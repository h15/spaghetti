package Spaghetti::Controller::Search;
use Mojo::Base 'Mojolicious::Controller';

    use Pony::Model::Dbh::MySQL;
    use Pony::Model::Crud::MySQL;
    use Pony::Stash;
    use Sphinx::Search;
    use Encode 'decode';

    sub search
        {
            my $this = shift;
            
            unless ( $this->param('q') )
            {
                return $this->render('search/index');
            }
            
            my $query = $this->param('q');
            
            # Get search result.
            #
            
            my $sphinx  = new Sphinx::Search;
            my $weights = { title => 3, text => 1 };
            my $results = $sphinx->SetMatchMode(SPH_MATCH_ANY)
                                 ->SetSortMode(SPH_SORT_RELEVANCE)
                                 ->SetFieldWeights($weights)
                                 ->SetLimits(0, 20)
                                 ->Query($query, 'threads');
            
            my $count = $results->{total_found};
            my $attrs = $results->{words};
            
            my @IDs;
            
            push @IDs, int $_->{doc} for @{ $results->{matches} };
            
            # Get data by IDs
            #
            
            my $threads = {};
            
            if ( @IDs )
            {
                my $sql = sprintf $Spaghetti::SQL::thread->{search}, join(',',@IDs);
                
                my $sth = Pony::Model::Dbh::MySQL->new->dbh->prepare($sql);
                   $sth->execute();
                $threads = $sth->fetchall_hashref('id');
            }
            
            # Prepare to render.
            #
            
            $this->stash( threads => $threads );
            $this->render;
        }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

