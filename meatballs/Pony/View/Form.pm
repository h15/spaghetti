package Pony::View::Form;
use Pony::Object;
use Pony::Stash;
use Pony::View::Form::Decorator;
use Pony::View::Translate;

    # " - Boy, it's lucky you have these compartments.
    #   - I use them for smuggling.
    #     I never thought I'd be smuggling myself in them.
    #     This is ridiculous. "
    
    our $VERSION = '0.000004';
    
    # Some html form's properties.
    has action      => '';
    has method      => '';
    has id          => '';
    has attrs       => {};
    has decorator   => undef;
    
    # Internal storeges.
    has elements    => {};
    has prioritet   => [];
    has errors      => {};
    has data        => {};
    has packages    => [];
    
    sub init
        {
            my $this = shift;
               $this->decorator = new Pony::View::Form::Decorator;
            
            # Get validators' packages.
            # Define default path to validators.
            
            $this->packages = Pony::Stash->findOrCreate
                ( PonyValidatorPrefixes => ['Pony::View::Form::Validator'] );
            
            $this->create();
        }
    
    # Check values of all elements.
    # Return 1 or 0 and if some error happies
    # - it will be added to errors property.
    
    sub isValid
        {
            my $this = shift;
            
            for my $k ( keys %{ $this->elements } )
            {
                my $e = $this->elements->{$k};
                
                next if $e->{ignore};
                
                # Does exist required element?
                if (! exists $this->data->{$k} && $e->{required} )
                {
                    push @{ $this->errors->{$k} }, 'required';
                }
                
                my $d = $this->data->{$k};
                
                # Harvest element's errors.
                unless ( $e->isValid($d) )
                {
                    push @{ $this->errors->{$k} }, $e->errors;
                }
            }
            
            return 0 if keys %{ $this->errors };
            return 1;
        }
    
    sub render
        {
            my $this = shift;
            my @elements;
            my $formStr = qq{<form action="\%s" method="\%s" id="\%s" \%s>\n\%s\n</form>};
            my $attrStr = '';
            my $t = new Pony::View::Translate;
            
            # Attribute's hash to string.

            while ( my ( $k, $v ) = each %{ $this->attrs } )
            {
                $attrStr .= sprintf '%s="%s" ', $k, $v;
            }

            $formStr = sprintf $formStr, $this->action, $this->method,
                                         $this->id, $attrStr, '%s';

            # Create an array of rendered elements
            # and other useful data.

            for my $k ( @{ $this->prioritet } )
            {
                my $e = $this->elements->{$k};
                my $errorStr = '';
                
                if ( @{ $e->errors } )
                {
                    # Translate errors.
                    #
                    
                    @{ $e->errors } = map { $t->t($_) } @{ $e->errors };
                    
                    $errorStr = join '</li><li>', @{ $e->errors };
                    $errorStr = '<div class="error"><ul class=error><li>'
                              . $errorStr . '</li></ul></div>';
                }
                   
                my $req = ( $e->required ? '*' : '' );
                
                my $h = {
                            label    => $e->label,
                            value    => $e->render( $this->id ),
                            error    => $errorStr,
                            require  => $req
                        };
                
                push @elements, $h;
            }

            # Run decorator.
            # It will return nice html code.

            return $this->decorator->decorate( $formStr, @elements );
        }
    
    # Add element to form.
    # Object or param list can be used.
    
    sub addElement
        {
            my ( $this, $name, $type, $options ) = @_;
            
            # Create and add element.
            if ( defined $type )
            {
                my $package = 'Pony::View::Form::Element::' . ucfirst $type;
                
                eval "use $package";
                die if $@;
                
                push @{ $this->prioritet }, $name;
                
                $this->elements->{$name} = $package->new($name, $options);
            }
            
            # Add element object.
            else
            {
                push @{ $this->prioritet }, $name->name;
                $this->elements->{$name->name} = $name;
            }
        }
    
1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
