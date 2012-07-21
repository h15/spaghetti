package Pony::View::Form::Validator::Like;
use Pony::Object qw/Pony::View::Form::Validator/;
    
    use Pony::View::Form::Translate;
    
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
            my $t    = new Pony::View::Form::Translate;
            
            return undef if $data =~ /$re/;
            return $t->t('Does not valid required format');
        }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
