package Pony::Model::Crud;
use Pony::Object;

    # Adaptor for Pony::Model::Crud drivers.
    # Define driver in Pony::Stash 'dbDriver'.
    # Case sensitive.

    sub init : Public
        {
            my $this = shift;
            my $dbd  = Pony::Stash->get('dbDriver');
            my $pkg  = "Pony::Model::Crud::$dbd";
            
            return $pkg->new(@_);
        }
    
1;

