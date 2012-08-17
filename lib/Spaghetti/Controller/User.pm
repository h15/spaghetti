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
          
          $this->session( userId => $user->getId() )->redirect_to('user_home');
        }
      }
      
      $this->stash( form => $form->render );
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
    }

  sub changePassword
    {
    }
  
  sub flushPassword
    {
    }
  
  sub genPassword
    {
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

