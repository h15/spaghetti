package Mojolicious::Plugin::StripTags;
use Mojo::Base 'Mojolicious::Plugin';

    use Mojo::ByteStream;
    
    sub register
        {
            my ( $this , $app ) = @_;
            
            $app->helper
            (
                strip => sub
                {
                    my $this = shift;
                    my $str  = shift;

                    $str =~ s/\<.*?\>//g;

                    return $str;
                }
            );
            
            $app->helper
            (
                shortify => sub
                {
                    my $this = shift;
                    my $str  = shift;
                    my $len  = shift;

                    $str  = substr $str, 0, $len;
                    my @w = split ' ', $str;
                    $str  = join ' ', @w[0 .. $#w - 1];

                    return $str;
                }
            );
        }
    
1;
