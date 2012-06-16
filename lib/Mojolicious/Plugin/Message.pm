package Mojolicious::Plugin::Message;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::IOLoop;
use Carp;

    our $VERSION = 0.000003;

    sub register
        {
            my ( $self, $app ) = @_;
            
            $app->helper
            (
                # Too much bullets to live.
                fatal => sub
                {
                    my ($self, $message) = @_;
                    croak qq/Fatal error: "$message"\n/;
                }
            );
            
            $app->helper
            (
                # Log and show error.
                error => sub
                {
                    my ($self, $message) = @_;
                    $app->log->error($message);
                    $self->msg( error => $message );
                }
            );
            
            $app->helper
            (
                # Show "Done", be nice.
                done => sub
                {
                    my ($self, $message) = @_;
                    $self->msg( done => $message );
                }
            );
            
            $app->helper
            (
                # Do not use it directly.
                msg => sub
                {
                    # For example: (self, 'error',
                    # { message => "Die, die, dive with me!" }).
                    my ($self, $type, $data) = @_;
                    
                    $self->stash( messageType => $type );
                    $self->stash( message => $data );
                }
            );
            
            $app->helper
            (
                # Standart responses.
                # Like 404 and the same.
                # Will stop IO Loop force.
                
                stop => sub
                {
                    my ( $this, $code ) = @_;
                    
                    $this->render(status => $code, template => "_$code" );
                    
                    # FIXME: Guaranted exit from controller without die.
                    #
                    #$this->finish;
                    #my $id = Mojo::IOLoop->recurring(0 => sub{});
                    #
                    #Mojo::IOLoop->drop($id);
                    
                    die;
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

