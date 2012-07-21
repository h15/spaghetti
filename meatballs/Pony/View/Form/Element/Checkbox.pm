package Pony::View::Form::Element::Checkbox;
use Pony::Object qw/Pony::View::Form::Element/;

    has valueForm => q/<input type="checkbox" class="pony-checkbox"
                              id="%s" %s name="%s" %s>/;
    
    sub render
        {
            my $this   = shift;
            my $formId = shift;
            my $value  = ( $this->value ? 'checked=checked' : '' );
            
            sprintf $this->valueForm, "$formId-".$this->id,
                    $value, $this->name, ($this->required ? 'required' : '');
        }

1;

__END__

=head1 NAME

Pony::View::Form::Element::Checkbox the Pony::View::Form element.

=head1 OVERVIEW

Pony::View::Form::Element::Checkbox can be used for rendering and validation
checkbox html element.

=head1 SYNOPSIS

    package My::Form;
    use Pony::Object qw/Pony::View::Form/;
    
        has action => '/url';
        has method => 'post';
        has id     => 'pony-form';
        
        sub create
            {
                my $this = shift;
                
                $this->addElement ( isBot => checkbox =>
                                    { required => 1, label => 'I\'m human' } );
            }
        
    1;

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
