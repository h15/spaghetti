package Mojolicious::Plugin::User;
use Pony::Object 'Mojolicious::Plugin';

    # This is an Mojolicious plugin for work
    # with users. I mean, that it realises personal
    # pages, authentitication, registration and other.

    use Digest::MD5 "md5_hex";
    use URI::Escape qw(uri_escape);
    use Pony::Stash;
    use Pony::Crud::MySQL;

    our $VERSION = '0.000006';

    sub register
        {
            # Init 'global' vars.
            #
            
            my($self, $app) = @_;
            my $userModel   = new Pony::Crud::MySQL('user');
            my $u2gModel    = new Pony::Crud::MySQL('userToGroup');
            my $banModel    = new Pony::Crud::MySQL('ban');
            my $anonymous   = $userModel->read({id => 0});
            my $user        = $anonymous;
            my $conf        = Pony::Stash->findOrCreate
                              ( user => {
                                    cookies     => 'some random string',
                                    expiration  => 3600 * 24,
                                    salt        => 'some random string',
                                    enable_registration => 1,
                              });
            
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
                    
                    if ( $id )
                    {
                        $user = $userModel->read({id=>$id});
                        my @groups = $u2gModel->list({userId => $id},
                                            ['groupId'],'groupId',undef,0,99);
                        
                        $user->{groups} = [ map { $_->{groupId} } @groups ];
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
                    
                    $user = Pony::Crud::MySQL->new('user')->read({id => $user})
                                                unless ( ref $user eq 'HASH' );
                    
                    my $default = sprintf 'http://%s:%s/pic/userpic.png',
                                          $self->req->url->base->host,
                                          $self->req->url->base->port;
                    my $pic = sprintf '<img class=userpic_small src="http://www.gravatar.com/avatar/%s?d=%s&s=%s">',
                                      md5_hex(lc $user->{mail}), uri_escape($default), 64;
                    
                    return new Mojo::ByteStream
                    (
                        sprintf '<a href="%s" class="%s">%s%s</a>',
                            $app->url_for( 'user_profile', id => $user->{id} ),
                            ($user->{banId} ? 'banned' : 'active'), $pic, $user->{name}
                    );
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

