package Stuff::Git::Gitolite;
use Pony::Object;
  
  use Pony::Model::Dbh::MySQL;
  use Pony::Model::Crud::MySQL;
  use Pony::Stash;
  
  public file  => '';
  public dir   => '';
  public allow => 0;
  public sql   =>
    {
      getRepo => 
        q{
          SELECT r.id, r.url,
               p.url AS projectUrl,
               t.owner
          FROM `repo` AS r
          INNER JOIN `thread`  AS t ON ( r.id = t.id )
          INNER JOIN `project` AS p ON ( p.id = t.topicId )
        },
      getSshKeys =>
        q{
          SELECT s.key, s.id, u.name, u.id AS userId
          FROM `sshKey` AS s
          INNER JOIN `user` AS u ON (s.userId = u.id)
        },
    };
  
  sub init : Public
    {
      my $this = shift;
      my $conf = Pony::Stash->get('git');
      
      $this->dir   = shift;
      $this->allow = $conf->{all};
      $this->file  = $this->dir . '/conf/gitolite.conf';
      
      mkdir $this->dir unless -d $this->dir;
      mkdir $this->dir unless -d $this->dir . '/conf';
      mkdir $this->dir unless -d $this->dir . '/keydir';
    }
  
  sub update : Public
    {
      my $this = shift;
      my $dbh  = Pony::Model::Dbh::MySQL->new->dbh;
      my $sth;
      
      # Get all keys.
      # Map users to their keys.
      
      $sth  = $dbh->prepare( $this->sql->{getSshKeys} );
      $sth->execute;
      
      my $keys = $sth->fetchall_hashref('id');
      my %users;
      
      for my $k ( keys %$keys )
      {
        my $v = $keys->{$k};
        push @{ $users{$v->{userId}} }, $k;
      }
      
      # Get all repos.
      #
      
      $sth  = $dbh->prepare( $this->sql->{getRepo} );
      $sth->execute;
      
      my $repos = $sth->fetchall_hashref('id');
      
      open F, '>', $this->file or die "Can't find file " . $this->file;
      {
        # Gitolite-admin's account.
        print F "repo gitolite-admin\n\tRW+ = root\n\n";
        
        my $model = new Pony::Model::Crud::MySQL('repoRightsViaUser');
        
        for my $r ( values %$repos )
        {
          printf F "repo %s/%s\n", $r->{projectUrl}, $r->{url};
          
          # Allow access for anonymous.
          print  F "\tR\t= \@all\n" if $this->allow;
          # Repo owner.
          printf F "\tRW+CD\t= %s\n", join ' ', @{$users{$r->{owner}}};
          
          # Get user list from this repo.
          #
          
          my @users = $model->list( {repoId => $r->{id}}, undef,
                        'rwpcd', undef, 0, 10_000 );
          
          # Build rights.
          #
          
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
          
          # Write users, which has permission.
          # Write users with the same rights on each iteration.
          
          while ( my($k, $v) = each %rights )
          {
            next unless ref $users{$_} eq 'ARRAY';
            
            my @str = map { join ' ', @{$users{$_}} } @$v;
            
            print F "\t$k\t= @str\n";
          }
        }
      }
      close F;
      
      # Write keys.
      #
      
      while ( my($k, $v) = each %$keys )
      {
        open F, '>', $this->dir . "/keydir/$k.pub" or die;
        print F $v->{key};
        close F;
      }
    }
  
1;
