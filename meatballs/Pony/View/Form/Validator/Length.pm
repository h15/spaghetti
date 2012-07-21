package Pony::View::Form::Validator::Length;
use Pony::Object qw/Pony::View::Form::Validator/;
    
    use Pony::View::Form::Translate;
    
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
            my $t    = new Pony::View::Form::Translate;
            my $len  = length $data;
            my $tpl  = 'Length must be between %d and %d';
            
            return $t->t($tpl, $this->min, $this->max) if $this->min > $len;
            return $t->t($tpl, $this->min, $this->max) if $len > $this->max;
            
            return undef;
        }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
