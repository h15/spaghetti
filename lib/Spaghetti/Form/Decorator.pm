package Spaghetti::Form::Decorator;
use Pony::Object 'Pony::View::Form::Decorator';

    has element => qq{<tr>\n<td>\%s <span class="required">\%s</span></td>
                            <td>\%s</td>\n</tr><tr><td colspan=2>\%s</td></tr>};
    
    sub decorateElement
        {
            my $this = shift;
            my $e    = shift;
            my $t    = new Pony::View::Form::Translate;
            
            sprintf $this->element, $t->t( $e->{label} ),
                    @$e{ qw/require value error/ };
        }

1;
