package Pony::Model;
use Pony::Object 'singleton';
    
    has models => {};
    has base   => '';
    
    # Define base class for
    
    sub init
        {
            my $this = shift;
               $this->base = shift;
            
            
        }
    
1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
