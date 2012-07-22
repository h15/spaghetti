package Pony::Model::ActiveRecord;
use Pony::Object;

    # Adaptor for Pony::Model::ActiveRecord drivers.
    # Define driver in Pony::Stash 'dbDriver'.
    # Case sensitive.

    sub init : Public
        {
            my $this = shift;
            my $dbd  = Pony::Stash->get('dbDriver');
            my $pkg  = "Pony::Model::ActiveRecord::$dbd";
            
            return $pkg->new(@_);
        }
    
1;
