package Spaghetti::Controller::Admin::Config;
use Mojo::Base 'Mojolicious::Controller';

    use Pony::Stash;
    
    sub edit
        {
            my $this = shift;
            my $conf = Pony::Stash->new->{conf};
            
            $conf = \%$conf;
            
            delete $conf->{database};
            
            if ( $this->req->method eq 'POST' )
            {
                for my $key ( keys %$conf )
                {
                    for my $jay ( keys %{ $conf->{$key} } )
                    {
                        my $val = $this->param("$key $jay");
                        
                        $conf->{$key}->{$jay} = $this->param("$key $jay")
                                     if defined $val && length $val;
                    }
                }
            }
            
            $this->stash(conf => $conf);
            $this->render('admin/config');
        }
        
    sub save
        {
            my $this = shift;
            
            Pony::Stash->save;  
            
            $this->redirect_to('admin_config_edit');
        }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

