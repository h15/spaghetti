package Forum::Controller::Admin::User;
use Mojo::Base 'Mojolicious::Controller';

    use Pony::Crud::MySQL;
    
    sub list
        {
            my $this = shift;
            
            # Paginator
            #
            
            my $page = int ( $this->param('page') || 0 );
               $page = 1 if $page < 1;
            
            my $conf  = Pony::Stash->findOrCreate( default => { size => 10 } );
            my @users = Pony::Crud::MySQL->new('user')->list( undef, undef, undef,
                                undef, ($page-1)*$conf->{size}, $conf->{size} );
            my $count = Pony::Crud::MySQL->new('user')->count;
            
            $this->stash( paginator => $this->paginator
                          ('admin_user_list', $page, $count, $conf->{size}) );
            $this->stash( users => \@users );
            $this->render('admin/user/list');
        }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

