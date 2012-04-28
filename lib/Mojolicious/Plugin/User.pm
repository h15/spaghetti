package Mojolicious::Plugin::User;
use Pony::Object 'Mojolicious::Plugin';

    # This is an Mojolicious plugin for work
    # with users. I mean, that it realises personal
    # pages, authentitication, registration and other.

    use Digest::MD5 "md5_hex";
    use URI::Escape qw(uri_escape);
    use Storable qw(thaw freeze);
    use Pony::Stash;
    use Pony::Model::Crud::MySQL;
    use Pony::View::Translate;
    use Module::Load;

    our $VERSION = '0.000008';

    sub register
        {
            # Init 'global' vars.
            #
            
            my($self, $app) = @_;
            my $userModel   = new Pony::Model::Crud::MySQL('user');
            my $u2gModel    = new Pony::Model::Crud::MySQL('userToGroup');
            my $banModel    = new Pony::Model::Crud::MySQL('ban');
            my $anonymous   = $userModel->read({id => 0});
            my $user        = $anonymous;
            my $conf        = Pony::Stash->get('user');
            my $default     = Pony::Stash->get('defaultUserConf');
            
            %$anonymous = ( conf => $default, %$anonymous );
            
            # Configure session.
            #
            
            $app->secret( $conf->{cookies} );
            $app->sessions->default_expiration( $conf->{expiration} );
            
            # Be careful - this code will run on each request.
            #
            
            $app->hook
            (
                before_dispatch => sub
                {
                    my $self = shift;
                    my $id   = $self->session('userId');
                    my $conf = $self->session('conf');
                    
                    if ( $id )
                    {
                        $user = $userModel->read({id=>$id});
                        my @groups = $u2gModel->list({userId => $id},
                                            ['groupId'],'groupId',undef,0,99);
                        
                        $user->{groups} = [ map { $_->{groupId} } @groups ];
                        
                        my $responses = Pony::Model::Crud::MySQL->new('userInfo')
                                            ->read({id => $id}, ['responses']);
                        
                        $user->{responses} = $responses->{responses} || 0;
                        
                        # Get config
                        #
                        
                        unless ( defined $conf )
                        {
                            $conf = Pony::Model::Crud::MySQL
                                      ->new('userInfo')
                                        ->read({id => $id}, ['conf']);
                            
                            if ( defined $conf )
                            {
                                $conf = $conf->{conf};
                                $self->session( conf => $conf );
                            }
                        }
                            
                        $conf = ( defined $conf ? thaw $conf : {} );
                        
                        for my $k ( keys %$default )
                        {
                            $conf->{$k} = $default->{$k} unless exists $conf->{$k};
                        }
                        
                        %$user = ( conf => $conf, %$user );
                    }
                    else
                    {
                        $user = $anonymous;
                    }
                    
                    # If user was deactivate, he uses anonymous account,
                    # but with his ban reason.
                    
                    if ( $user->{banId} )
                    {
                        my $ban = $banModel->read({ id => $user->{banId} });
                        $user = $anonymous;
                        $user->{ban} = $ban;
                    }
                    
                    # Define lang.
                    #
                    
                    Pony::View::Translate->new->lang = $user->{conf}->{lang};
                }
            );
            
            $app->helper( user => sub { $user } );
            
            # Simple helper for user rendering.
            #
            $app->helper
            (
                render_user => sub
                {
                    my ( $self, $user ) = @_;
                    
                    $user = Pony::Model::Crud::MySQL->new('user')->read({id => $user})
                                                unless ( ref $user eq 'HASH' );
                    
                    my $default = sprintf 'http://%s:%s/pic/userpic20.png',
                                          $self->req->url->base->host,
                                          $self->req->url->base->port;
                    my $pic = sprintf '<img class=userpic_small src="http://www.gravatar.com/avatar/%s?d=%s&s=%s">',
                                      md5_hex( lc($user->{mail}||'') ), uri_escape($default), 20;
                    my $url =
                        (
                            $user->{id} != $self->user->{id} ?
                                $app->url_for( 'user_profile', id => $user->{id} ) :
                                $app->url_for( 'user_home' )
                        );
                    
                    return new Mojo::ByteStream
                    (
                        sprintf '<a href="%s" class="%s">%s%s</a>',
                            ($url||''), ($user->{banId} ? 'banned' : 'active'),
                            ($pic||''), ($user->{name}||'')
                    );
                }
            );
            
            $app->helper
            (
                render_userpic => sub
                {
                    my ( $self, $mail, $size ) = @_;
                    
                    if ( $size == 20 )
                    {
                        my $default = sprintf 'http://%s:%s/pic/userpic20.png',
                                              $self->req->url->base->host,
                                              $self->req->url->base->port;
                    
                        return( sprintf '<img class=userpic_small src="http://www.gravatar.com/avatar/%s?d=%s&s=%s">',
                                       md5_hex(lc $mail), uri_escape($default), $size );
                    }
                    else
                    {
                        my $default = sprintf 'http://%s:%s/pic/userpic96.png',
                                              $self->req->url->base->host,
                                              $self->req->url->base->port;
                    
                        return( sprintf '<img class=userpic_big src="http://www.gravatar.com/avatar/%s?d=%s&s=%s">',
                                       md5_hex(lc $mail), uri_escape($default), $size );
                    }
                }
            );
        }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 - 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

