package Spaghetti::Controller::News;
use Mojo::Base 'Mojolicious::Controller';
    
    use Spaghetti::Form::Topic::Create;
    use Spaghetti::Form::Thread::Create;
    use Spaghetti::Util;
    use Pony::Crud::Dbh::MySQL;
    use Pony::Crud::MySQL;
    use Pony::Stash;
    
    sub show
        {
            my $this = shift;
            my $url  = $this->param('url');
            my $dbh  = Pony::Crud::Dbh::MySQL->new->dbh;
               $url  = $dbh->quote($url);
            
            # Paginator
            #
            
            my $page = int ( $this->param('page') || 0 );
               $page = 1 if $page < 1;
            
            my $conf = Pony::Stash->get('thread');
            
            # Get news and comments.
            #
            
            my $sth = $dbh->prepare( $Spaghetti::SQL::news->{show} );
               $sth->execute( $this->user->{id}, $url, $this->user->{id},
                                     ($page-1) * $conf->{size}, $conf->{size} );
                                     
            my $comments = $sth->fetchall_hashref('id');
            my ( $news ) = grep { $_->{url} eq $url } values %$comments;
            
            $this->redirect_to('404') unless defined $news;
            
            delete $comments->{ $news->{id} };
            
            # Get count of news' comments.
            #
            
            my $sth = $dbh->prepare( $Spaghetti::SQL::news->{count} );
               $sth->execute( $news->{id}, $this->user->{id} );
                                     
            my $count = $sth->fetchrow_hashref();
            
            # Prepare to render.
            #
            
            my $form = new Spaghetti::Form::Thread::Create;
            my $topicForm = new Spaghetti::Form::Topic::Create;
            
            $this->stash( create => $this->access($id, 'c') );
            
            $this->stash( paginator =>
                            $this->paginator( 'news_show_p', $page,
                                $count->{count}, $conf->{size}, [ url => $url ] ) );
            
            $this->stash( comments  => $comments  );
            $this->stash( news      => $news      );
            $this->stash( form      => $form      );
            $this->stash( topicForm => $topicForm );
            $this->render;
        }

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
                                     
            my $news = $sth->fetchall_hashref('threadId');
            
            # Get size of news list.
            #
            
            my $count = Pony::Crud::MySQL->new('news')->count;
            
            # Prepare to render.
            #
            
            $this->stash( paginator =>
                $this->paginator( 'news_list_p', $page, $count, $conf->{size} ) );
            
            $this->stash( newsList => $news );
        }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

