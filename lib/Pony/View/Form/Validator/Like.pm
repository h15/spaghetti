package Pony::View::Form::Validator::Like;
use Pony::Object qw/Pony::View::Form::Validator/;
    
    has regexp => '';
    
    # Get validator's params
    # and init validator by them.
    
    sub init
        {
            my $this  = shift;
            my $param = shift;
            
            $this->regexp = $param;
        }
    
    # Work with input data.
    # Check it for valid.
    
    sub getError
        {
            my $this = shift;
            my $data = shift;
            my $re   = $this->regexp;
            
            return undef if $data =~ /$re/;
            return 'does not like required format';
        }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
