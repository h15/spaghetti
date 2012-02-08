package Spaghetti::Controller::Project;
use Mojo::Base 'Mojolicious::Controller';
    
    use Pony::Stash;
    use Pony::Crud::MySQL;
    use Pony::Crud::MySQL::Dbh;
    
    sub read
        {
            my $this = shift;
            my $url  = $this->param('url');
            my $dbh  = Pony::Crud::Dbh::MySQL->new->dbh;
            
            # Get project
            #
            
            my $sth = $dbh->prepare( $Spaghetti::SQL::project->{read} );
               $sth->execute( $url );
                                     
            my $project = $sth->fetchrow_hashref();
            
            return $this->redirect_to('/404') unless $project;
            
            # Get project's repos
            #
            
            my $sth = $dbh->prepare( $Spaghetti::SQL::repo->{list} );
               $sth->execute( $project->{id} );
            
            my $repos = $sth->fetchall_hashref('id');
            
            # Prepare to render
            #
            
            $this->stash( project => $project );
            $this->stash( repos   => $repos   );
        }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

