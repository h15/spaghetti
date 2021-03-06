package Spaghetti::Form::OneColumnDecorator;
use Pony::Object 'Pony::View::Form::Decorator';

    has element => qq{<tr>\n<td>\%s <span class="required">\%s</span></td></tr>
                            <tr><td class="wide">\%s</td>\n</tr><tr><td>\%s</td></tr>};
    
    sub decorateElement
        {
            my $this = shift;
            my $e    = shift;
            my $t    = new Pony::View::Translate;
            
            sprintf $this->element, $t->t( $e->{label} ),
                    @$e{ qw/require value error/ };
        }

1;
