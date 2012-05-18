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
        }
    
1;
