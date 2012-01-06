package Pony::View::Form::Element::Select;
use Pony::Object qw/Pony::View::Form::Element/;

    has selectForm =>
        qq{<select class="pony-select" id="\%s" name="\%s" required="\%s">\n\%s</select>};
    has optionForm =>
        qq{<option class="pony-option" value="\%s">\%s</option>\n};
    
    sub render
        {
            my $this = shift;
            my $formId = shift;
            my $options = '';
            
            while ( my($k, $v) = each %{ $this->options } )
            {
                $options .= sprintf $this->optionForm, $v, $k;
            }
            
            sprintf $this->selectForm, "$formId-".$this->id,
                    $this->name, $this->required, $options;
        }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
