package Spaghetti::Controller::Admin;
use Mojo::Base 'Mojolicious::Controller';
    
    use Pony::Stash;
    use Pony::Model::Crud::MySQL;
    
    sub auth
        {
            my $this = shift;
            
            my $u2g = Pony::Model::Crud::MySQL
                       ->new('userToGroup')
                         ->read({userId => $this->user->{id}, groupId => 1});
            
            return 1 if $u2g;
            return 0;
        }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

