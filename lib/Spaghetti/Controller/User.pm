package Spaghetti::Controller::User;
use Mojo::Base 'Mojolicious::Controller';
  
  # Forms.
  use Spaghetti::Form::User::Login;
  use Spaghetti::Form::User::LoginViaMail;
  use Spaghetti::Form::User::Registration;
  use Spaghetti::Form::User::ChangePassword;
  use Spaghetti::Form::User::ChangeMail;
  use Spaghetti::Form::User::AddSshKey;

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
  
  sub home
    {
      my $this = shift;
      
      # Not found for anonymous.
      #
      
      $this->stop(404) unless $this->user->{id};
      
      $this->stash( user => $this->user );
      $this->render;
    }
  
  sub config
    {
    }
  
  sub profile
    {
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

