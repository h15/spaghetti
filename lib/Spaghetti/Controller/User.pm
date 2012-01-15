package Spaghetti::Controller::User;
use Mojo::Base 'Mojolicious::Controller';
    
    use Spaghetti::Form::Login;
    use Spaghetti::Form::Registration;
    use Spaghetti::Form::User::ChangePassword;
    use Spaghetti::Form::User::ChangeMail;
    use Pony::Crud::MySQL;
    use Pony::Stash;
    use Digest::MD5 "md5_hex";

    sub login
        {
            my $this = shift;
            my $form = new Spaghetti::Form::Login;
            
            if ( $this->req->method eq 'POST' )
            {
                $form->data->{$_} = $this->param($_) for keys %{$form->elements};
                
                if ( $form->isValid )
                {
                    my $mail = $form->elements->{mail}->value;
                    my $pass = $form->elements->{password}->value;
                    my $model= new Pony::Crud::MySQL('user');
                    my $conf = Pony::Stash->get('user');
                    my $user = $model->read({mail => $mail}, ['id','attempts']);
                    my $att  = $user->{attempts};
                    
                    if ( $att > $conf->{attempts} )
                    {
                        $form->elements->{submit}->errors
                                = ['Too much login attempts'];
                    }
                    else
                    {
                        my $where= { 'mail' => $mail,
                                     'password' => md5_hex( $mail . $pass ) };
                                     
                        $user = $model->read( $where, ['id'] );
                    
                        if ( defined $user && $user->{id} > 0 )
                        {
                            # All fine.
                            #
                            $model->update
                            ( { accessAt => time,
                                attempts => 0     },
                              { id => $user->{id} } );
                            
                            $this->session( userId  => $user->{id} )
                                 ->redirect_to('user_home');
                        }
                        else
                        {
                            $model->update
                            ( { attempts => ++$att },
                              { mail     => $mail  } );
                            
                            $form->elements->{password}->errors
                                    = ['Invalid mail or password'];
                        }
                    }
                }
            }
            
            $this->stash( form => $form->render() );
            $this->render;
        }
        
    sub registration
        {
            my $this = shift;
            my $form = new Spaghetti::Form::Registration;
            
            if ( $this->req->method eq 'POST' )
            {
                $form->data->{$_} = $this->param($_) for keys %{$form->elements};
                
                if ( $form->isValid )
                {
                    my $name = $form->elements->{name}->value;
                    my $mail = $form->elements->{mail}->value;
                    my $pass = $form->elements->{password}->value;
                    
                    my $model = new Pony::Crud::MySQL('user');
                    my $user1 = $model->read( {'mail' => $mail}, ['id'] );
                    my $user2 = $model->read( {'name' => $name}, ['id'] );
                    
                    if ( $user1->{id} > 0 || $user2->{id} > 0 )
                    {
                        $form->elements->{mail}->errors
                                = ['Mail is already used'] if $user1->{id} > 0;
                        $form->elements->{name}->errors
                                = ['Name is already used'] if $user2->{id} > 0;
                    }
                    else
                    {
                        # All fine.
                        #
                        my $id = $model->create({ 
                                    name      => $name,
                                    mail      => $mail,
                                    createAt  => time,
                                    accessAt  => time,
                                    modifyAt  => time,
                                    password  => md5_hex( $mail . $pass )
                                 });
                        
                        my $u2gModel = new Pony::Crud::MySQL('userToGroup');
                        
                        # Default group.
                        #
                        $u2gModel->create({ userId  => $id,
                                            groupId => 999 });
                        
                        $this->session( userId  => $id )
                             ->redirect_to('user_home');
                    }
                }
            }
            
            $this->stash( form => $form->render() );
            $this->render;
        }
    
    sub home
        {
            my $this = shift;
            my $formPass = new Spaghetti::Form::User::ChangePassword;
            my $formMail = new Spaghetti::Form::User::ChangeMail;
            
            $this->stash( formPass => $formPass->render() );
            $this->stash( formMail => $formMail->render() );
            $this->stash( user => $this->user );
            $this->render;
        }
    
    sub profile
        {
            my $this = shift;
            my $id   = $this->param('id');
            my $model= new Pony::Crud::MySQL('user');
            my $user = $model->read({ id => $id });
            
            $this->stash( user => $user );
            $this->render;
        }
    
    sub logout
        {
            my $this = shift;
            
            $this->session( userId  => 0 )
                 ->redirect_to('thread_index');
        }

    sub changePassword
        {
            my $this = shift;
            my $form = new Spaghetti::Form::User::ChangePassword;
            
            if ( $this->req->method eq 'POST' )
            {
                $form->data->{$_} = $this->param($_) for keys %{$form->elements};
                
                if ( $form->isValid )
                {
                    my $oldPass = $form->elements->{oldPassword}->value;
                    my $newPass = $form->elements->{newPassword}->value;
                    
                    my $model = new Pony::Crud::MySQL('user');
                    
                    my $where = { 'id'       => $this->user->{id},
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

    sub changeMail
        {
            my $this = shift;
            my $form = new Spaghetti::Form::User::ChangeMail;
            
            if ( $this->req->method eq 'POST' )
            {
                $form->data->{$_} = $this->param($_) for keys %{$form->elements};
                
                if ( $form->isValid )
                {
                    my $pass = $form->elements->{password}->value;
                    my $mail = $form->elements->{mail}->value;
                    
                    my $model = new Pony::Crud::MySQL('user');
                    
                    my $where = { 'id'       => $this->user->{id},
                                  'password' => md5_hex( $this->user->{mail} . $pass ) };
                    
                    my $user = $model->read( $where, ['id'] );
                    
                    if ( exists $user->{id} && $user->{id} > 0 )
                    {
                        # Does this mail already use.
                        #
                        $user = $model->read({ mail => $mail }, ['id']);
                        
                        unless ( defined $user && $user->{id} > 0 )
                        {
                            # All fine.
                            #
                            $model->update
                            ( {
                                modifyAt => time,
                                password => md5_hex($mail.$pass),
                                mail     => $mail
                              },
                              { id => $this->user->{id} } );
                            
                            $this->redirect_to('user_home');
                        }
                        else
                        {
                            $form->elements->{mail}->errors
                                    = ['E-mail is already used'];
                        }
                    }
                    else
                    {
                        $form->elements->{password}->errors
                                = ['Invalid password'];
                    }
                }
            }
            
            $this->stash( form => $form->render() );
            $this->render;
        }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

