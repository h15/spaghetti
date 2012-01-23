package Spaghetti::Controller::News;
use Mojo::Base 'Mojolicious::Controller';
    
    use Spaghetti::Form::Topic::Create;
    use Spaghetti::Form::Thread::Create;
    use Spaghetti::Util;
    use Pony::Crud::Dbh::MySQL;
    use Pony::Crud::MySQL;
    use Pony::Stash;

    sub list
        {
            my $this = shift;
            my $dbh  = Pony::Crud::Dbh::MySQL->new->dbh;
            
            # Paginator
            #
            
            my $page = int ( $this->param('page') || 0 );
               $page = 1 if $page < 1;
            
            my $conf = Pony::Stash->get('news');
            
            # Get news list.
            #
            
            my $sth = $dbh->prepare( $Spaghetti::SQL::news->{list} );
               $sth->execute( ($page-1) * $conf->{size}, $conf->{size} );
                                     
            my $news = $sth->fetchall_hashref('id');
            
            # Get size of news list.
            #
            
            my $count = Pony::Crud::MySQL->new('news')->count;
            
            # Prepare to render.
            #
            
            $this->stash( paginator =>
                $this->paginator( 'news_list_p', $page, $count, $conf->{size} ) );
            
            $this->stash( newsList => $news );
            $this->render;
        }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

