package Mojolicious::Plugin::B;
use Mojo::Base 'Mojolicious::Plugin';

    use Mojo::ByteStream;
    
    sub register
        {
            my ( $this , $app ) = @_;
            
            $app->helper
            (
                b => sub
                {
                    my $this = shift;
                    return new Mojo::ByteStream( shift );
                }
            );
        }
    
1;
