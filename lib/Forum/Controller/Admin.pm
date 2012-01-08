package Forum::Controller::Admin;
use Mojo::Base 'Mojolicious::Controller';
    
    use Pony::Stash;
    use Pony::Crud::MySQL;
    
    sub auth
        {
            my $this = shift;
            
            my @u = Pony::Crud::MySQL
                      ->new('userToGroup')
                        ->list( {userId => $this->user->{id}, groupId => 1},
                                            ['userId'], 'userId', undef, 0, 1 );
            return 1 if @u;
            return 0;
        }

1;
