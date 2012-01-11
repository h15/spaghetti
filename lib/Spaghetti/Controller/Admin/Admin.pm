package Spaghetti::Controller::Admin::Admin;
use Mojo::Base 'Mojolicious::Controller';
    
    use Pony::Stash;
    use Pony::Crud::MySQL;
    
    sub index
        {
            my $this = shift;
            $this->render;
        }

1;
