package Mojolicious::Plugin::Mail;
use Mojo::Base 'Mojolicious::Plugin';

    use MIME::Lite;
    use Pony::Stash;

    our $VERSION = '0.000002';

    sub register
        {
            my ( $plugin, $app ) = @_;
            my $conf = Pony::Stash->get('mail');
            
            $app->helper
            (
                mail => sub
                {
                    # It will be bad, if you does not
                    # define $type or $mail.
                    
                    my ( $self, $type, $mail, $title, $data ) = @_;
                    
                    $title ||= '';
                    $data  ||= {};

                    $self->stash
                    (
                        %$data,
                        title => $title,
                        host  => $conf->{site},
                    );
                    
                    my $html = $self->render
                               (
                                   partial    => 1,
                                   template   => "mail/$type",
                               );
                    
                    MIME::Lite->new
                    (
                        From    => $conf->{from},
                        To      => $mail,
                        Subject => $title,
                        Type    => 'text/html',
                        Data    => $html,
                    )->send;
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

