package Stuff::Git::Scanner;
use Pony::Object;

    use Git::Repository;
    use Pony::Stash;
    use Date::Parse;
    use Spaghetti::Util;
    
    protected repo => undef;
    
    # Init one repo.
    # @access public
    # @raises "Can't find dir ..."
    # @raises "Repo does not exist"
    
    sub init : Public
        {
            my $this = shift;
            my $proj = shift;
            my $repo = shift;
            my $dir  = Pony::Stash->get('git')->{dir};
            
            die "Can't find dir $dir" unless -d $dir;
            die "Repo does not exist" unless -d "$dir/$proj/$repo.git";
            
            $this->repo = Git::Repository
                            ->new( git_dir => "$dir/$proj/$repo.git" );
        }
    
    # Special C<run> method to prevent server
    # overload by huge git objects.
    # @access protected
    # @raises "Too big"
    
    sub run : Protected
        {
            my $this = shift;
            #my $cmd = $this->repo->command(@_);
            my @out;
            
            eval
            {
            #    local $SIG{ALRM} = sub { die "timeout" };
                
            #    alarm 1;
                @out = $this->repo->run(@_);
            #    alarm 0;
            };
            
            #my $stdout = $cmd->stdout();
            #
            #my $lineCount = 0;
            #my @out;
            #
            #while ( my $out = <$stdout> )
            #{
            #    exit 'Too big' if ++$lineCount == 100_000;
            #    chomp $out;
            #    push @out, $out;
            #}
            
            return @out;
        }
    
    # Get log.
    # @access public
    
    sub getLog : Public
        {
            my $this = shift;
            my $size = shift;
            my @log = $this->run( qw/log -n/, $size );
            my @logs;
            
            for ( @log )
            {
                given( $_ )
                {
                    when( /^\s+(.*)/s )
                    {
                        $logs[$#logs]{comment} .= $1 . ' ';
                    }
                    when( /Author:\s*(.*)/s )
                    {
                        my ( $name, $mail ) = ( $1 =~ /(.*?)\<(.*?)\>/s );
                        
                        $logs[$#logs]{name} = $name;
                        $logs[$#logs]{mail} = $mail;
                    }
                    when( /Date:\s*(.*)/s )
                    {
                        $logs[$#logs]{date} = str2time $1;
                    }
                    when( /commit\s*(.*)/s )
                    {
                        push @logs,
                            {
                                commit  => $1,
                                date    => 0,
                                name    => '',
                                mail    => '',
                                comment => '',
                            };
                    }
                }
            }
            
            return @logs;
        }
    
    # Get file tree.
    # @access public
    
    sub getTree : Public
        {
            my $this = shift;
            my $id   = shift;
            my $path = shift;

            $id .= ':' . $path if defined $path;
            
            my @c = $this->run( 'ls-tree', $id );
            
            # Parse
            for my $i ( 0 .. $#c )
            {
                chomp $c[$i];
                
                my ( $type, $obj, $name ) =
                        ( $c[$i] =~ /(tree|blob) ([a-f0-9]+)\s+(\S+)$/ );
                
                $c[$i] = {type => $type, obj => $obj, name => $name};
            }
            
            return \@c;
        }
    
    # Get file.
    # @access public
    
    sub getBlob : Public
        {
            my $this = shift;
            my $id   = shift;
            my $path = shift;
            
            $id .= ':' . $path if defined $path;
            
            my @c = $this->run( 'show', $id );
            return \@c;
        }
    
    # Get parsed commit.
    # @access public
    
    sub getCommit : Public
        {
            my $this = shift;
            my $id   = shift;
            
            my @c = $this->repo->run( 'show', $id );
            my %log;
                 
            # Parse log
            #
            
            while ( @c )
            {
                my $line = shift @c;
                
                given ( $line )
                {
                    when( /^\s+(.*)/s )
                    {
                        $log{comment} .= $1 . ' ';
                    }
                    
                    when( /Author:\s*(.*)/s )
                    {
                        my ( $name, $mail ) = ( $1 =~ /(.*?)\<(.*?)\>/s );
                        
                        $log{name} = $name;
                        $log{mail} = $mail;
                    }
                    
                    when( /Date:\s*(.*)/s )
                    {
                        $log{date} = str2time $1;
                    }
                    
                    when( /commit\s*(.*)/s )
                    {
                        %log =
                            (
                                commit  => $1,
                                date    => 0,
                                name    => '',
                                mail    => '',
                                comment => '',
                            );
                    }
                    
                    when (/^diff/)
                    {
                        unshift @c, $line;
                        last;
                    }
                }
            }
            
            # Parse diff
            #
            
            my @files;
            
            # Old line, new line.
            my( $o, $n );
            
            # Parse
            for my $i ( 0 .. $#c )
            {
                chomp $c[$i];
                
                given ( $c[$i] )
                {
                    when ( /^index/ ) { $c[$i] = ''; }
                    when ( /^new/   ) { $c[$i] = ''; }
                    when ( /^\+\+\+/) { $c[$i] = ''; }
                    when ( /^---/   ) { $c[$i] = ''; }
                    when ( /^Binary/) { $c[$i] = ''; }
                    when (/^deleted/) { $c[$i] = ''; }
                    
                    when ( /^\+/ )
                    {
                        $c[$i] = substr $c[$i], 1;
                        $c[$i] = {
                                    class   => "green line",
                                    newLine => $n,
                                    text    => $c[$i]
                                 };
                        ++$n;
                    }
                    
                    when ( /^\-/ )
                    {
                        $c[$i] = substr $c[$i], 1;
                        $c[$i] = {
                                    class   => "red line",
                                    oldLine => $o,
                                    text    => $c[$i]
                                 };
                        ++$o;
                    }
                    
                    when ( /^\s/ )
                    {
                        $c[$i] = substr $c[$i], 1;
                        $c[$i] = {
                                    class   => " line",
                                    oldLine => $o,
                                    newLine => $n,
                                    text    => $c[$i]
                                 };
                        ++$n;$o++;
                    }
                    
                    when ( /^@@/ )
                    {
                        ( $o, $n ) = ( $c[$i] =~ /^@@ -(\d+),\d+ \+(\d+)/ );
                        
                        if ( $o > 1 )
                        {
                            $c[$i] = {
                                        class   => "line",
                                        text    => '...'
                                     };
                        }
                        else
                        {
                            $c[$i] = '';
                        }
                    }
                    
                    when (/^diff/)
                    {
                        ( $c[$i] ) = ( $c[$i] =~ /b\/(\S+)\s*$/ );
                        my $f = $c[$i];
                        
                        $c[$i] = {
                                    class   => "file",
                                    text    => $f
                                 };
                                                
                        unshift @files, $f;
                    }
                }
            }
            
            return \%log, \@files, \@c;
        }
    
1;

