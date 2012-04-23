package Stuff::Git::Scanner;
use Pony::Object;

    use Git::Repository;
    use Pony::Stash;
    use Date::Parse;
    
    protected repo => undef;
    
    sub init : Public
        {
            my $this = shift;
            my $proj = shift;
            my $repo = shift;
            my $dir  = Pony::Stash->get('gitdir');
            
            die "Can't find dir $dir" unless -d $dir;
            
            $this->repo = Git::Repository->new( git_dir => "$dir/$proj/$repo.git" );
        }
    
    sub getLog : Public
        {
            my $this = shift;
            my $size = shift;
            my @log = $this->repo->run( qw/log -n/, $size );
            my @logs;
            
            while ( @log )
            {
                my ( $comment ) = ( pop(@log) =~ /\s*(.*)/s );
                
                pop @log;
                
                my ( $date   ) = ( pop(@log) =~ /Date:\s*(.*)/s );
                my ( $author ) = ( pop(@log) =~ /Author:\s*(.*)/s );
                my ( $commit ) = ( pop(@log) =~ /commit\s*(.*)/s );
                
                my ( $name, $mail ) = ( $author =~ /(.*?)\<(.*?)\>/s );
                
                push @logs, {
                                date   => str2time($date),
                                name   => $name,
                                mail   => $mail,
                                commit => $commit,
                                comment=> $comment
                            };
                
                pop @log if @log;
            }
            
            return @logs;
        }
    
    sub getFile : Public
        {
        }

1;
