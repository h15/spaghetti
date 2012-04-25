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
                push @logs, $this->getLogRow(@log);
                
                @log = @log[6..$#log];
            }
            
            return @logs;
        }
    
    sub getTree : Public
        {
            my $this = shift;
            my $id   = shift;
            
            my @c = $this->repo->run( 'ls-tree', $id );
            
            # Parse
            for my $i ( 0 .. $#c )
            {
                chomp $c[$i];
                my ( $type, $obj, $name ) = ( $c[$i] =~ /(tree|blob) ([a-f0-9]+)\s+(\S+)$/ );
                $c[$i] = {type => $type, obj => $obj, name => $name};
            }
            
            return \@c;
        }
    
    sub getBlob : Public
        {
            my $this = shift;
            my $id   = shift;
            
            my @c = $this->repo->run( 'show', $id );
            return \@c;
        }
    
    sub getCommit : Public
        {
            my $this = shift;
            my $id   = shift;
            
            my @c = $this->repo->run( 'show', $id );
            my $i = $this->getLogRow(@c);
            @c = @c[6 .. $#c];
            
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
                    
                    when ( /^\+/ )
                    {
                        $c[$i] = substr $c[$i], 1;
                        $c[$i] = qq{<tr class="green line"><td class="oldLine"></td><td class="newLine">$n</td>}
                               . '<td class=text>'.$c[$i].'</td></tr>';
                        ++$n;
                    }
                    
                    when ( /^\-/ )
                    {
                        $c[$i] = substr $c[$i], 1;
                        $c[$i] = qq{<tr class="red line"><td class="oldLine">$o</td><td class="newLine"></td>}
                               . '<td class=text>'.$c[$i].'</td></tr>';
                        ++$o;
                    }
                    
                    when ( /^\s/ )
                    {
                        $c[$i] = substr $c[$i], 1;
                        $c[$i] = qq{<tr class="line"><td class="oldLine">$o</td><td class="newLine">$n</td>}
                               . '<td class=text>'.$c[$i].'</td></tr>';
                        ++$n;$o++;
                    }
                    
                    when ( /^@@/ )
                    {
                        ( $o, $n ) = ( $c[$i] =~ /^@@ -(\d+),\d+ \+(\d+)/ );
                        
                        if ( $o > 1 ) { $c[$i] = "<tr><td colspan=3 class='line'>...</td></tr>"; }
                        else { $c[$i] = '' }
                    }
                    
                    when (/^diff/)
                    {
                        ( $c[$i] ) = ( $c[$i] =~ /b\/(\S+)\s*$/ );
                        my $f = $c[$i];
                        
                        $c[$i] = "<tr><td colspan=3 class='file'><a name='$f'></a>$f</td></tr>";
                                                
                        unshift @files, $f;
                    }
                }
            }
            
            return $i, \@files, join("\n", @c);
        }
    
    sub getLogRow : Public
        {
            my $this = shift;
            
            my ( $commit  ) = ( $_[0] =~ /commit\s*(.*)/s );
            my ( $author  ) = ( $_[1] =~ /Author:\s*(.*)/s );
            my ( $date    ) = ( $_[2] =~ /Date:\s*(.*)/s );
            my ( $comment ) = ( $_[4] =~ /\s*(.*)/s );
            
            my ( $name, $mail ) = ( $author =~ /(.*?)\<(.*?)\>/s );
            
            return  {
                        date   => str2time($date),
                        name   => $name,
                        mail   => $mail,
                        commit => $commit,
                        comment=> $comment
                    };
        }
    
1;
