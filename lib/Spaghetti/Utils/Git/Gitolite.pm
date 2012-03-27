package Spaghetti::Utils::Git::Gitolite;
use Pony::Object;
    
    use Pony::Model::Dbh::MySQL;
    use Pony::Model::Crud::MySQL;
    
    has file => '';
    has sql  => {
                    getRepo => 
                    q{
                        SELECT r.id, r.url,
                               p.url AS projectUrl,
                               t.owner
                        FROM `repo` AS r
                        INNER JOIN `thread`  AS t ON ( r.id = t.id )
                        INNER JOIN `project` AS p ON ( p.id = t.topicId )
                     }
                };
    
    sub init
        {
            my $this = shift;
               $this->file = shift;
        }
    
    sub update
        {
            my $this = shift;
            my $dbh  = Pony::Model::Dbh::MySQL->new->dbh;
            my $sth  = $dbh->prepare( $this->sql->{getRepo} );
               $sth->execute;
            
            # Get all repos.
            #
            
            my $repos = $sth->fetchall_hashref('id');
            
            open F, '>', $this->file or die "Can't find file " . $this->file;
            {
                my $model = new Pony::Model::Crud::MySQL('repoRightsViaUser');
                
                for my $r ( values %$repos )
                {
                    printf F "repo %s/%s\n", $r->{projectUrl}, $r->{url};
                    print  F "\tR\t= ALL\n";
                    printf F "\tRW+CD\t= %s\n", $r->{owner};
                    
                    # Get user list from this repo.
                    #
                    
                    my @users = $model->list( {repoId => $r->{id}}, undef,
                                              'rwpcd', undef, 0, 10_000 );
                    
                    my %rights;
                    
                    for my $u ( @users )
                    {
                        my $access;
                        $access .= 'R' if $u->{rwpcd} & 1;
                        $access .= 'W' if $u->{rwpcd} & 2;
                        $access .= 'C' if $u->{rwpcd} & 8;
                        $access .= 'D' if $u->{rwpcd} & 16;
                        
                        push @{ $rights{$access} }, $u->{userId} if $access;
                    }
                    
                    while ( my($k, $v) = each %rights )
                    {
                        print F "\t$k\t= @$v\n";
                    }
                }
            }
            close F;
        }



1;
