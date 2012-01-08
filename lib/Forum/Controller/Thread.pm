package Forum::Controller::Thread;
use Mojo::Base 'Mojolicious::Controller';
    
    use Forum::Form::Topic::Create;
    use Forum::Form::Thread::Create;
    use Forum::Util;
    use Pony::Crud::Dbh::MySQL;
    use Pony::Crud::MySQL;
    use Pony::Stash;
    
    sub show
        {
            my $this = shift;
            my $url  = $this->param('url') || 0;
            my $topicModel = new Pony::Crud::MySQL('topic');
            
            # Get Topic ID from requested url.
            # It can be string (url) or integer (id).
            
            my $id = $url !~ /^\d*$/ ?
                        $topicModel->list({url=>$url},'threadId','threadId',undef,0,1) ]->[0]->{threadId} :
                        int $url;
            
            # Paginator
            #
            
            my $page = int ( $this->param('page') || 0 );
               $page = 1 if $page < 1;
             --$page;
            
            my $conf = Pony::Stash->findOrCreate( thread => { size => 50 } );
            
            # Quick and dirty :)
            #
            
            my $q = sprintf 'SELECT th.id, th.createAt, th.modifyAt, th.parentId,
                                    th.topicId, th.userId, t.`text`, t1.title,
                                    t1.url, u.name, u.mail, u.banId
                                FROM `thread` th
                                LEFT OUTER JOIN `text`    t    ON ( th.textId    = t.id  )
                                LEFT OUTER JOIN `topic`   t1   ON ( t1.threadId  = th.id )
                                LEFT OUTER JOIN `user`    u    ON ( th.userId    = u.id  )
                                    WHERE ( th.topicId=%d or th.id=%d )
                                        AND th.id IN
                                            (
                                                SELECT `threadId` FROM `threadToDataType`
                                                WHERE `dataType` IN
                                                (
                                                    SELECT `dataType` FROM `access`
                                                    WHERE `RWCD` & 1 != 0 AND `groupId` IN
                                                    (
                                                        SELECT `groupId` FROM `userToGroup`
                                                        WHERE `userId`=%d
                                                    )
                                                )
                                            )
                                    ORDER BY t1.threadId, th.id ASC
                                    LIMIT %d, %d',
                                $id, $id, $this->user->{id},
                                $page * $conf->{size}, $conf->{size};
            
            my @threads = $threadModel->raw( $q );
            my $form = new Forum::Form::Thread::Create;
            
            $this->stash( threads => \@threads );
            $this->stash( id      => $id       );
            $this->stash( form    => $form     );
            $this->render;
        }
    
    sub create
        {
            my $this = shift;
            my $pid  = int $this->param('parentId');
            my $tid  = int $this->param('topicId');
            my $form = new Forum::Form::Thread::Create;
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
                                    userId      => $userId,
                                    createAt    => time,
                                    modifyAt    => time,
                                    parentId    => $parent,
                                    topicId     => $topic,
                               });
                               
                    my $teId = $textModel->create
                               ({
                                    threadId    => $thId,
                                    text        => Forum::Util::escape($text),
                               });
                    
                    $threadModel->update( { textId  => $teId },
                                          { id      => $thId } );
                    
                    # Inheritance of groups
                    #
                    my $t2dtModel = new Pony::Crud::MySQL('threadToDataType');
                    my @types = $t2dtModel->list({threadId => $parent},
                                        'dataTypeId', undef, undef, 0, 100);
                    
                    my $q = 'INSERT INTO `threadToDataType`(`threadId`,`dataTypeId`) VALUES';
                    my @v = map { sprintf '(%s,%s)', $thId, $_->{dataTypeId} } @types;
                    
                    $t2dtModel->raw( $q . join ',' @v );
                    
                    $this->redirect_to('thread_show', url => $topic);
                }
            }
            
            $this->stash( form => $form->render );
            $this->render;
        }
    
    sub createTopic
        {
            my $this = shift;
            my $pid  = int $this->param('parentId');
            my $tid  = int $this->param('topicId');
            my $form = new Forum::Form::Topic::Create;
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
                    my $url   = substr(Forum::Util::rusToLatUrl($title), 0, 52);
                    
                    my $threadModel= new Pony::Crud::MySQL('thread');
                    my $topicModel = new Pony::Crud::MySQL('topic');
                    my $textModel  = new Pony::Crud::MySQL('text');
                    
                    my $thId = $threadModel->create
                               ({
                                    userId      => $userId,
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
                                    text        => Forum::Util::escape($text),
                               });
                    
                    $threadModel->update( { textId  => $teId },
                                          { id      => $thId } );
                    
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
            my $form = new Forum::Form::Thread::Create;
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
                        text => Forum::Util::escape($text),
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
            my $form = new Forum::Form::Topic::Create;
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
                                     ({ text => Forum::Util::escape($textVal),
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

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

