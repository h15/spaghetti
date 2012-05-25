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
            
            # Paginator
            #
            
            my $page = int ( $this->param('page') || 0 );
               $page = 1 if $page < 1;
            
            my $size = Pony::Stash->get('thread')->{size};
            
            # Get search result.
            #
            
            my $sphinx  = new Sphinx::Search;
            my $weights = { title => 3, text => 1 };
            my $results = $sphinx->SetMatchMode(SPH_MATCH_ANY)
                                 ->SetSortMode(SPH_SORT_RELEVANCE)
                                 ->SetFieldWeights($weights)
                                 ->SetLimits( ($page - 1) * $size, $size )
                                 ->Query($query, 'threads');
            
            my $count = $results->{total_found};
            
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
            
            my $pager = $this->paginatorForSearch($page, $count, $size, $query);
            
            # Prepare to render.
            #
            
            $this->stash( paginator => $pager );
            $this->stash( threads => $threads );
            $this->render;
        }
        
    sub paginatorForSearch
        {
            my ( $self, $cur, $count, $size, $query ) = @_;
            my $html = '';
            
            return '' if not defined $count or $count <= $size;
            
            my $last = int ( $count / $size );
             ++$last if $count % $size;
            
            # Render first page.
            #
            $html .= sprintf '<a href="%s?q=%s">&lArr;</a>',
                     $self->url_for('search_index_p', page => 1), $query if $cur != 1;
            
            for my $i ( $cur - 5 .. $cur + 5 )
            {
                next if $i < 1 || $i > $last;
                
                $html .= ( $i == $cur ?
                            sprintf '<span>%s</span>', $cur :
                            sprintf '<a href="%s?q=%s">%s</a>',
                            $self->url_for('search_index_p', page => $i), $query, $i );
            }
            
            # Render last page.
            #
            $html .= sprintf '<a href="%s?q=%s">&rArr;</a>',
                     $self->url_for('search_index_p', page => $last), $query
                        if $cur != $last;
            
            new Mojo::ByteStream("<div class=\"paginator\">$html</div>")
        }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

