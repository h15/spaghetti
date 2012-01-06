package Pony::View::Form::Validator::Length;
use Pony::Object qw/Pony::View::Form::Validator/;
    
    has min => '';
    has max => '';
    
    # Get validator's params
    # and init validator by them.
    
    sub init
        {
            my $this  = shift;
            my $param = shift;
            
            $this->min = $param->[0];
            $this->max = $param->[1];
        }
    
    # Work with input data.
    # Check it for valid.
    
    sub getError
        {
            my $this = shift;
            my $data = shift;
            
            my $len  = length $data;
            
            return 'too short' if $this->min > $len;
            return 'too long'  if $len > $this->max;
            
            return undef;
        }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
