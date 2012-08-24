package Spaghetti::Controller::User;
use Mojo::Base 'Mojolicious::Controller';
  
  # Forms.
  use Spaghetti::Form::User::Login;
  use Spaghetti::Form::User::LoginViaMail;
  use Spaghetti::Form::User::Registration;
  use Spaghetti::Form::User::ChangePassword;
  use Spaghetti::Form::User::ChangeMail;
  use Spaghetti::Form::User::AddSshKey;
  
  use Pony::Model::Dbh::MySQL;
  use Pony::Model::Crud::MySQL;
  use Pony::Stash;
  
  use Digest::MD5 "md5_hex";
  use Storable qw(thaw freeze);
  use Captcha::AreYouAHuman;
  
  use User::Object;
  
  # Login action.
  # Here is user can enter to the site.
  # On GET it shows login form.
  # On POST we'll try to login user.
  
  sub login
    {
      my $this = shift;
      my $form = new Spaghetti::Form::User::Login;
      
      if ( $this->req->method eq 'POST' )
      {
        $form->data->{$_} = $this->param($_) for keys %{$form->elements};
        
        if ( $form->isValid )
        {
          my $e = $form->elements;
          my $user = new User::Object;
          $user->load({mail => $e->{mail}->value});
          
          # Too much attempts.
          if ( $user->attempts > Pony::Stash->get('user')->{attempts} )
          {
            $e->{submit}->errors = ['Too much login attempts'];
          }
          else
          {
            # Does user with this mail and password exists?
            if ($user->password ne $user->cryptPassword($e->{password}->value))
            {
              $user->set({attempts => $user->attempts + 1})->save();
              $e->{password}->errors = ['Invalid mail or password'];
            }
            else
            {
              # All fine. Flush attempt count.
              $user->set({attempts => 0, accessAt => time})->save();
              $this->session(userId=>$user->getId())->redirect_to('user_home');
            }
          }
        }
      }
      
      $this->stash( form => $form->render );
    }
  
  # User registration.
  # Upgrade anonymous to registrant.
  # GET - show form, POST - create user.
  
  sub registration
    {
      my $this = shift;
      my $form = new Spaghetti::Form::User::Registration;
      
      if ( $this->req->method eq 'POST' )
      {
        $form->data->{$_} = $this->param($_) for keys %{$form->elements};
        
        if ( $form->isValid )
        {
          my $e = $form->elements;
          my $user = new User::Object;
          
          $e->{name}->errors = ['Name is already used'], break
            if $user->load({name => $e->{name}->value})->getId();
          $e->{mail}->errors = ['Mail is already used'], break
            if $user->load({mail => $e->{mail}->value})->getId();
          
          $user->setStorable( $form->data );
          $user->setPassword( $user->password );
          $user->set({createAt => time, modifyAt => time, accessAt => time,
                      attempts => 0, sshKeyCount => 0,
                      banId => 0, banTime => 0})->save();
          
          # Add user to default user group.
          Pony::Model::Crud::MySQL
            ->new('userToGroup')
              ->create({ groupId => 999, userId => $user->getId() });
          
          $this->session( userId => $user->getId() )->redirect_to('user_home');
        }
      }
      
      my $ayah = new Captcha::AreYouAHuman (
        publisher_key => Pony::Stash->get('areYouAHuman')->{publisher},
        scoring_key   => Pony::Stash->get('areYouAHuman')->{scoring}
      );
      
      $this->stash({form => $form->render, ayah => $ayah});
    }
  
  
  # Get responses to user's messages.
  # Flush response count.
  # 
  # @see Spaghetti::Thread::Create
  
  sub responses
    {
      my $this = shift;
      
      # Not found for anonymous.
      $this->stop(404) unless $this->user->{id};

      my $dbh = Pony::Model::Dbh::MySQL->new->dbh;
      my $sth = $dbh->prepare($Spaghetti::SQL::user->{responses});
         $sth->execute( $this->user->{id}, 0, 20 );
         
      my $resps = $sth->fetchall_hashref('id');
      
      # Flush response count.
      Pony::Model::Crud::MySQL->new('userInfo')
          ->update({ responses => 0 }, { id => $this->user->{id} });
      
      $this->stash(responses => $resps);
    }
  
  
  # Private user thread.
  # 
  # It uses for private messages from other
  # users and some system messages.
  # Thread owner can response to messages.
  # User has not rights for this messages.
  #
  # In this context author is a sender,
  # owner is a receiver.
  #
  # @param int page -- param for paginator.
  
  sub thread
    {
    }
  
  
  # Show user's home page.
  #
  
  sub home
    {
      my $this = shift;
      
      # Not found for anonymous.
      $this->stop(404) unless $this->user->{id};
      
      $this->stash( user => $this->user );
    }
  
  sub config
    {
    }
  
  sub profile
    {
      my $this = shift;
      my $id = $this->param('id') || 0;
      
      my $user = User::Object->new->load($id) || $this->stop(404);
      my @items;
      
      @items = Pony::Model::Crud::MySQL->new('item')->list()
        if grep { $_ eq 2 } @{ $this->user->{groups} }; # Is Archon?
      
      $this->stash( items => \@items );
      $this->stash( user => $user );
    }
  
  sub logout
    {
      my $this = shift;
      
      if ( $this->req->method eq 'POST' )
      {
        $this->session( userId  => 0 )->redirect_to('index_index');
      }
    }

  sub changePassword
    {
      my $this = shift;
      
      # Anonymous has not password.
      $this->stop(403) unless $this->user->{id};
      
      my $form = new Spaghetti::Form::User::ChangePassword;
      
      if ( $this->req->method eq 'POST' )
      {
          $form->data->{$_} = $this->param($_) for keys %{$form->elements};
          
          my $flush = $form->data->{flush};
          my $generate= $form->data->{generate};
          
          return $this->genPassword if $generate;
          return $this->flushPassword if $flush;
          
          if ( $form->isValid )
          {
              my $oldPass = $form->elements->{oldPassword}->value;
              my $newPass = $form->elements->{newPassword}->value;
              
              my $model = new Pony::Model::Crud::MySQL('user');
              
              my $where = { 'id' => $this->user->{id},
                            'password' => md5_hex( $this->user->{mail} . $oldPass ) };
              
              my $user = $model->read( $where, ['id'] );
              
              if ( exists $user->{id} && $user->{id} > 0 )
              {
                  # All fine.
                  #
                  $model->update
                  ( {
                      modifyAt => time,
                      password => md5_hex($this->user->{mail}.$newPass)
                    },
                    { id => $user->{id} } );
                  
                  $this->redirect_to('user_home');
              }
              else
              {
                  $form->elements->{oldPassword}->errors
                          = ['Invalid password'];
              }
          }
      }
      
      $this->stash( form => $form->render() );
      $this->render;
    }
  
  sub flushPassword
    {
      my $this = shift;
      
      # Anonymous has not password.
      #
      
      $this->stop(403) unless $this->user->{id};
      
      my $model = new Pony::Model::Crud::MySQL('user');
      
      $model->update({ password => '',
                       modifyAt => time },
                     { id => $this->user->{id} });
      
      $this->redirect_to('user_home');
    }
  
  sub genPassword
    {
      my $this = shift;
      
      # Anonymous has not password.
      #
      
      $this->stop(403) unless $this->user->{id};
      
      my $model = new Pony::Model::Crud::MySQL('user');
      my $pass = md5_hex( rand );
      my $mail = $this->user->{mail};
      
      $model->update({ password => md5_hex($mail.$pass),
                       modifyAt => time },
                     { id => $this->user->{id} });
      
      # Send mail.
      #
      $this->mail( new_password => $mail =>
                   'New password' => { password => $pass } );
      
      $this->redirect_to('user_home');
    }

  sub changeMail
    {
    }
    
  sub loginViaMail
    {
      my $this = shift;
      my $form = new Spaghetti::Form::User::LoginViaMail;
      
      if ( $this->req->method eq 'POST' )
      {
        $form->data->{$_} = $this->param($_) for keys %{$form->elements};
          
        if ( $form->isValid )
        {
          my $conf = Pony::Stash->get('user');
          my $mail = $form->elements->{mail}->value;
          my $user = Pony::Model::Crud::MySQL->new('user')->read({mail => $mail}, ['id']);
          
          if ( defined $user && $user->{id} > 0 )
          {
            # All fine.
            my $key = md5_hex(rand);
            Pony::Model::Crud::MySQL->new('mailConfirm')->delete({ mail => $mail });
            Pony::Model::Crud::MySQL->new('mailConfirm')->create({ expair => time + $conf->{expairMail},
                                                                   mail   => $mail, secret => $key  });
                  
            # Send mail.
            $this->mail( login => $mail => Login => { key  => $key, mail => $mail } );
            
            $form = new Spaghetti::Form::User::LoginViaMail;
            
            $this->done('Check your mail');
            $this->stash( form => $form->render() );
            
            return $this->render;
          }
          else
          {
              $form->elements->{mail}->errors = ['Invalid mail'];
          }
        }
      }
      
      $this->stash( form => $form->render() );
    }

  sub mailConfirm
    {
      my $this = shift;
      my $mail = $this->param('mail');
      my $key  = $this->param('key');
      my $conf = Pony::Stash->get('user');
      my $model= new Pony::Model::Crud::MySQL('mailConfirm');
         $mail = $model->read({mail => $mail});
                                 
      my $userModel = new Pony::Model::Crud::MySQL('user');
      
      # Mail does not used for confirm.
      #
      
      if ( not defined $mail )
      {
        $this->error("Does not exist");
      }
      
      
      # Too much attempts.
      #
      
      elsif ( $mail->{attempts} > $conf->{mailAttempts} )
      {
        $this->error("Too much login attempts");
      }
      
      # Too slow.
      #
      
      elsif ( $mail->{expair} < time )
      {
        $this->error("Time expaired");
      }
      
      # Wrong secret.
      #
      
      elsif ( $mail->{secret} ne $key )
      {
        $model->update( {attempts => $mail->{attempts}+1},
                        {mail     => $mail->{mail}      } );
          
        $this->error("Does not exist");
      }
      
      # All fine.
      #
      
      else
      {
        $model->update({attempts => 0}, {mail => $mail->{mail}});
        $userModel->update
        ({ attempts => 0,
           accessAt => time },
         { mail => $mail->{mail} });
          
        my $user = $userModel->read({ mail => $mail->{mail} }, ['id']);
          
        if ( defined $user )
        {
          $model->delete({ mail => $mail->{mail} });
              
          $this->session( userId  => $user->{id} )
               ->redirect_to('user_home');
        }
      }
      
      my $form = new Spaghetti::Form::User::LoginViaMail;
      
      $this->stash( form => $form->render() );
      $this->render('user_loginViaMail');
    }
  
  sub projects
    {
    }
  
  sub items
    {
    }

  sub ssh
    {
    }

  sub sshEdit
    {
    }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

