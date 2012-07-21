package Pony::View::Form::Element;
use Pony::Object;
use Pony::Stash;
    
    has id          => '';
    has name        => '';
    has label       => '';
    has value       => '';
    has required    =>  0;
    has ignore      =>  0;
    has errors      => [];
    has validators  => [];
    
    sub init
        {
			my $this = shift;
			   $this->name = shift;
			
            my $options = shift;
            my $prefixes = Pony::Stash->get('PonyValidatorPrefixes');
            
            $this->required = 1 if $options->{required};
            $this->ignore   = 1 if $options->{ignore};
            
            delete $options->{required};
            delete $options->{ignore};
            
            for my $k ( keys %{ $options } )
            {
                next if $k eq 'validators';
                
                $this->$k = $options->{$k} if $this->can($k);
            }
            
            $this->id = $this->name unless $this->id;
            
            # Init all elements' validators.
            # You can use custom valudators
            # if you add their package prefixes
            # into Stash field 'PonyValidatorPrefixes'.
            
            for my $k ( keys %{ $options->{validators} } )
            {
                # Search in all validators' prefixes
                # use first finded.
            
                for my $px ( @$prefixes )
                {
                    eval "use ${px}::$k";
                    next if $@;
                    
                    my $pkg = "${px}::$k";
                    push @{ $this->validators },
                         $pkg->new($options->{validators}->{$k});
                    
                    last;
                }
            }
        }
    
    sub render
        {
            return sprintf '<div class="error">%s</div>',
                           'Render is not defined!'
        }
    
    sub isValid
        {
            my $this = shift;
            my $data = shift;
            
            for my $v ( @{ $this->validators } )
            {
                my $error = $v->getError($data);
                
                push @{ $this->errors }, $error if $error;
            }
            
            return 0 if @{ $this->errors };
            
            $this->value = $data;
            
            return 1;
        }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
