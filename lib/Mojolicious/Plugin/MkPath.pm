package Mojolicious::Plugin::MkPath;
use Mojo::Base 'Mojolicious::Plugin';

    use Mojo::ByteStream;
    
    sub register
        {
            my ( $this , $app ) = @_;
            
            $app->helper
            (
                mkPath => sub
                {
                    my $this = shift;
                    my ( $str, $project, $repo, $object )= @_;

                    my @out;
                    my $dir;

                    for my $way ( split '/', $str )
                    {
                        next if $way eq '';
                        
                        $dir .= '/' . $way;

                        my $url = $this->url_for('repo_readTreePath', project => $project,
                                                  repo => $repo, object => $object, dir => $dir );

                        push @out, sprintf('<a href="%s">%s</a>', $url, $way);
                    }

                    return new Mojo::ByteStream( join ' / ', @out );
                }
            );
        }
    
1;
