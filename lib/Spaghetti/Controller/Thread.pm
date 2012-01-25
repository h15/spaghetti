package Spaghetti::Controller::Thread;
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
            my $url  = $this->param('url') || 0;
            my $topicModel = new Pony::Crud::MySQL('topic');
            my $dbh  = Pony::Crud::Dbh::MySQL->new->dbh;
            
            # Get Topic ID from requested url.
            # It can be string (url) or integer (id).
            
            my $id = ( $url =~ /^\d*$/ ? int $url :
                       [ $topicModel->list({url=>$url},['threadId'],'threadId',
                                                undef,0,1) ]->[0]->{threadId} );
            
            # Paginator
            #
            
            my $page = int ( $this->param('page') || 0 );
               $page = 1 if $page < 1;
            
            my $conf = Pony::Stash->get('thread');
            
            # Get thread list.
            #
            
            my $sth = $dbh->prepare( $Spaghetti::SQL::thread->{show} );
               $sth->execute( $this->user->{id}, $id, $id, $this->user->{id},
                                     ($page-1) * $conf->{size}, $conf->{size} );
            
            my $threads = $sth->fetchall_hashref('id');
            my ($topic) = grep { $_->{id} eq $id } values %$threads;
            
            delete $threads->{ $topic->{id} } if defined $topic;
            
            $this->redirect_to('404') unless $threads;
            
            # Get thread count.
            #
            
            $sth = $dbh->prepare( $Spaghetti::SQL::thread->{showCount} );
            $sth->execute( $id, $id, $this->user->{id} );
            
            my $count = $sth->fetchrow_hashref();
            
            # make tree view
            #
            
            my @roots;
            
            for my $t ( sort {$a->{id} <=> $b->{id}} values %$threads )
            {
                if ( exists $threads->{ $t->{parentId} } )
                {
                    push @{ $threads->{ $t->{parentId} }->{childs} }, $t->{id};
                }
                else
                {
                    push @roots, $t->{id};
                }
            }
            
            # Prepare to render.
            #
            
            my $form = new Spaghetti::Form::Thread::Create;
            my $topicForm = new Spaghetti::Form::Topic::Create;
            
            $this->stash( create => $this->access($id, 'c') );
            
            $this->stash( paginator =>
                            $this->paginator( 'thread_show_p', $page,
                                $count->{count}, $conf->{size}, [ url => $id ] ) );
            
            $this->stash( roots     => \@roots    );
            $this->stash( topic     => $topic     );
            $this->stash( threads   => $threads   );
            $this->stash( id        => $id        );
            $this->stash( form      => $form      );
            $this->stash( topicForm => $topicForm );
            
            defined $topic->{legend} ?
                $this->render('news/show') : $this->render;
        }
    
    sub create
        {
            my $this = shift;
            my $pid  = int $this->param('parentId');
            my $tid  = int $this->param('topicId');
            
            $this->redirect_to('404') unless $this->access($tid, 'c');
            
            my $form = new Spaghetti::Form::Thread::Create;
               $form->action = $this->url_for('thread_create');
               $form->elements->{parentId}->value = $pid;
               $form->elements->{topicId}->value  = $tid;
            
            if ( $this->req->method eq 'POST' )
            {
                $form->data->{$_} = $this->param($_) for keys %{$form->elements};
                
                if ( $form->isValid )
                {
                    my $text  = $form->elements->{text}->value;
                    my $parent= $form->elements->{parentId}->value;
                    my $topic = $form->elements->{topicId}->value;
                    my $userId= $this->user->{id};
                    
                    my $threadModel= new Pony::Crud::MySQL('thread');
                    my $textModel  = new Pony::Crud::MySQL('text');
                    
                    my $thId = $threadModel->create
                               ({
                                    author      => $userId,
                                    owner       => $userId,
                                    createAt    => time,
                                    modifyAt    => time,
                                    parentId    => $parent,
                                    topicId     => $topic,
                               });
                               
                    my $teId = $textModel->create
                               ({
                                    threadId    => $thId,
                                    text        => Spaghetti::Util::escape($text),
                               });
                    
                    $threadModel->update( { textId  => $teId },
                                          { id      => $thId } );
                    
                    # Inheritance of groups
                    #
                    my $t2dtModel = new Pony::Crud::MySQL('threadToDataType');
                    my @types = $t2dtModel->list({threadId => $parent},
                                        ['dataTypeId'], 'dataTypeId', undef, 0, 100);
                    
                    my $q = 'INSERT INTO `threadToDataType`(`threadId`,`dataTypeId`) VALUES';
                    my @v = map { sprintf '(%s,%s)', $thId, $_->{dataTypeId} } @types;
                    
                    Pony::Crud::Dbh::MySQL->new->dbh->do( $q . join(',', @v) );
                    
                    $this->redirect_to('thread_show', url => $topic);
                }
            }
            
            $this->stash( form => $form->render );
            $this->render;
        }
    
    sub createTopic
        {
            my $this = shift;
            my $pid  = int ( $this->param('parentId') || 0 );
            my $tid  = int ( $this->param('topicId' ) || 0 );
            
            $this->redirect_to('404') unless $this->access($tid, 'c');
            
            my $form = new Spaghetti::Form::Topic::Create;
               $form->action = $this->url_for('thread_createTopic');
               $form->elements->{parentId}->value = $pid;
               $form->elements->{topicId}->value  = $tid;
            
            if ( $this->req->method eq 'POST' )
            {
                $form->data->{$_} = $this->param($_) for keys %{$form->elements};
                
                if ( $form->isValid )
                {
                    my $title = $form->elements->{title}->value;
                    my $text  = $form->elements->{text}->value;
                    my $parent= $form->elements->{parentId}->value;
                    my $topic = $form->elements->{parentId}->value;
                    my $userId= $this->user->{id};
                    my $url   = substr(Spaghetti::Util::rusToLatUrl($title), 0, 52);
                    
                    my $threadModel= new Pony::Crud::MySQL('thread');
                    my $topicModel = new Pony::Crud::MySQL('topic');
                    my $textModel  = new Pony::Crud::MySQL('text');
                    
                    my $thId = $threadModel->create
                               ({
                                    author      => $userId,
                                    owner       => $userId,
                                    createAt    => time,
                                    modifyAt    => time,
                                    parentId    => $parent,
                                    topicId     => $topic,
                               });
                               
                    $topicModel->create
                               ({
                                    threadId    => $thId,
                                    title       => $title,
                                    url         => "$thId-$url"
                               });
                               
                    my $teId = $textModel->create
                               ({
                                    threadId    => $thId,
                                    text        => Spaghetti::Util::escape($text),
                               });
                    
                    $threadModel->update( { textId  => $teId },
                                          { id      => $thId } );
                    
                    # Inheritance of groups
                    #
                    my $t2dtModel = new Pony::Crud::MySQL('threadToDataType');
                    my @types = $t2dtModel->list({threadId => $parent},
                                        ['dataTypeId'], 'dataTypeId', undef, 0, 100);
                    
                    my $q = 'INSERT INTO `threadToDataType`(`threadId`,`dataTypeId`) VALUES';
                    my @v = map { sprintf '(%s,%s)', $thId, $_->{dataTypeId} } @types;
                    
                    Pony::Crud::Dbh::MySQL->new->dbh->do( $q . join(',', @v) ) if @v;
                    
                    $this->redirect_to('thread_show', url => "$thId-$url");
                }
            }
            
            $this->stash( form => $form->render );
            $this->render;
        }
    
    sub edit
        {
            my $this = shift;
            my $id   = int $this->param('id');
            
            $this->redirect_to('404') unless $this->access($id, 'w');
            
            my $form = new Spaghetti::Form::Thread::Create;
               $form->action = $this->url_for( thread_edit => id => $id );
            
            my $threadModel= new Pony::Crud::MySQL('thread');
            my $textModel  = new Pony::Crud::MySQL('text');
            
            my $thread = $threadModel->read({ id => $id });
            my $text = $textModel->read({ id => $thread->{textId} });
            
            if ( $this->req->method eq 'POST' )
            {
                $form->data->{$_} = $this->param($_) for keys %{$form->elements};
                
                if ( $form->isValid )
                {
                    my $text = $form->elements->{text}->value;
                    
                    $threadModel->update
                    (
                        { modifyAt => time    },
                        { id => $thread->{id} }
                    );
                               
                    my $textId = $textModel->create
                    ({
                        text => Spaghetti::Util::escape($text),
                        threadId => $thread->{id}
                    });
                    
                    $threadModel->update( { textId   => $textId,
                                            modifyAt => time },
                                          { id       => $thread->{id} } );
                    
                    $this->redirect_to('thread_edit', url => $thread->{id});
                }
            }
            
            for my $k ( keys %{$form->elements} )
            {
                $form->elements->{$k}->value = $text->{$k}   if defined $text->{$k};
                $form->elements->{$k}->value = $thread->{$k} if defined $thread->{$k};
            }
            
            $this->stash( id => $id );
            $this->stash( form => $form->render );
            $this->render;
        }
    
    
    sub editTopic
        {
            my $this = shift;
            my $id   = int $this->param('id');
            
            $this->redirect_to('404') unless $this->access($id, 'w');
            
            my $form = new Spaghetti::Form::Topic::Create;
               $form->action = $this->url_for( topic_edit => id => $id );
            
            my $threadModel= new Pony::Crud::MySQL('thread');
            my $topicModel = new Pony::Crud::MySQL('topic');
            my $textModel  = new Pony::Crud::MySQL('text');
            
            my $thread= $threadModel->read({ id => $id });
            my $topic = [ $topicModel->list( {threadId => $id}, undef,
                                             'threadId', undef, 0, 1 ) ]->[0];
            my $text  = $textModel->read({ id => $thread->{textId} });
            
            if ( $this->req->method eq 'POST' )
            {
                $form->data->{$_} = $this->param($_) for keys %{$form->elements};
                
                if ( $form->isValid )
                {
                    my $textVal = $form->elements->{text}->value;
                    my $title   = $form->elements->{title}->value;
                    
                    my $data = { modifyAt => time };
                    
                    if ( $text->{text} ne $textVal )
                    {
                        my $textId = $textModel->create
                                     ({ text => Spaghetti::Util::escape($textVal),
                                        threadId => $thread->{id} });
                        
                        $data->{textId} = $textId;
                    }
                    
                    if ( $topic->{title} ne $title )
                    {
                        $topicModel->update({ title => $title },
                                            { threadId => $id });
                    }
                    
                    $threadModel->update( $data, { id => $id } );
                    
                    $this->redirect_to('topic_edit', url => $id);
                }
            }
            
            for my $k ( keys %{$form->elements} )
            {
                $form->elements->{$k}->value = $text->{$k} if defined $text->{$k};
                $form->elements->{$k}->value = $thread->{$k} if defined $thread->{$k};
                $form->elements->{$k}->value = $topic->{$k} if defined $topic->{$k};
            }
            
            $this->stash( id => $id );
            $this->stash( form => $form->render );
            $this->render;
        }

    sub tracker
        {
            my $this = shift;
            my $dbh  = Pony::Crud::Dbh::MySQL->new->dbh;
            
            # Paginator
            #
            
            my $page = int ( $this->param('page') || 0 );
               $page = 1 if $page < 1;
            
            my $conf = Pony::Stash->get('thread');
            
            # Get thread list.
            #
            
            my $sth = $dbh->prepare( $Spaghetti::SQL::thread->{tracker} );
               $sth->execute( $this->user->{id}, ($page-1) * $conf->{size}, $conf->{size} );
            
            my $threads = $sth->fetchall_hashref('id');
            
            $this->redirect_to('404') unless $threads;
            
            # Get thread count.
            #
            
            $sth = $dbh->prepare( $Spaghetti::SQL::thread->{trackerCount} );
            $sth->execute( $this->user->{id} );
            
            my $count = $sth->fetchrow_hashref();
            
            # Prepare to render.
            #
            
            $this->stash( paginator =>
                            $this->paginator( 'thread_tracker', $page,
                                $count->{count}, $conf->{size} ) );
            
            $this->stash( threads   => $threads   );
            $this->render;
        }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

