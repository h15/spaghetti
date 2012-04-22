package Stuff::Git::Scanner;
use Pony::Object;
use Git::Repository;

    protected dir => undef;
    
    sub init : Public
        {
            my $this = shift;
               $this->dir = shift;
            
            die "Can't find dir " . $this->dir unless -d $this->dir;
        }
    
    sub getLog : Public
        {
        
        }
    
    sub getFile : Public
        {
        }

1;
