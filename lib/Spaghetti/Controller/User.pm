package Spaghetti::Controller::User;
use Mojo::Base 'Mojolicious::Controller';
    
    use Spaghetti::Form::Login;
    use Spaghetti::Form::Registration;
    use Spaghetti::Form::User::ChangePassword;
    use Pony::Crud::MySQL;
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
                    
                    my $where= { 'mail' => $mail,
                                 'password' => md5_hex( $mail . $pass ) };
                    
                    my $model= new Pony::Crud::MySQL('user');
                    my $user = $model->read( $where, ['id'] );
                    
                    if ( $user->{id} > 0 )
                    {
                        # All fine.
                        #
                        $model->update({accessAt => time}, {id => $user->{id}});
                        
                        $this->session( userId  => $user->{id} )
                             ->redirect_to('user_home');
                    }
                    else
                    {
                        $form->elements->{password}->errors
                                = ['Invalid mail or password'];
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
            my $form = new Spaghetti::Form::User::ChangePassword;
            
            $this->stash( form => $form->render() );
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
                        ( { password => md5_hex($this->user->{mail}.$newPass) },
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

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

