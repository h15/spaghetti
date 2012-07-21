package Pony::View::Form::Validator::Have;
use Pony::Object qw/Pony::View::Form::Validator/;
    
    use Pony::View::Form::Translate;
    
    has types => {};
    
    # Get validator's params
    # and init validator by them.
    
    sub init
        {
            my $this  = shift;
            my $param = shift;
            
            for my $p ( @$param )
            {
                given ( $p )
                {
                    when ( '-' ) { $p = 'SPECIAL_CHAR'  }
                    when ( '1' ) { $p = 'DIGITAL'       }
                    when ( 'a' ) { $p = 'LOWER_CASE'    }
                    when ( 'A' ) { $p = 'UPPER_CASE'    }
                    
                    default { next }
                }
                
                ++$this->types->{$p}
            }
        }
    
    # Work with input data.
    # Check it for valid.
    
    sub getError
        {
            my $this = shift;
            my $data = shift;
            my $tpl  = 'Value must have %s like %s';
            my $t    = new Pony::View::Form::Translate;
            
            for my $k ( keys %{ $this->types } )
            {
                given ( $k )
                {
                    when ( 'SPECIAL_CHAR' )
                    {
                        return $t->t($tpl, 'special chars', '-,/,!,?')
                               unless $data =~ /[^\w\d]/
                    }
                    
                    when ( 'DIGITAL' )
                    {
                        return $t->t($tpl, 'digits', '1,2,3')
                               unless $data =~ /\d/
                    }
                    
                    when ( 'LOWER_CASE' )
                    {
                        return $t->t($tpl, 'latin chars in lower case', 'a,b,c')
                               unless $data =~ /[a-z]/
                    }
                    
                    when ( 'UPPER_CASE' )
                    {
                        return $t->t($tpl, 'latin chars in upper case', 'A,B,C')
                               unless $data =~ /[A-Z]/
                    }
                    
                    default { next }
                }
            }
            
            return undef;
        }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
