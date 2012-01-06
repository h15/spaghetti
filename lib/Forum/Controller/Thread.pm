package Forum::Controller::Thread;
use Mojo::Base 'Mojolicious::Controller';
    
    use Forum::Form::CreateTopic;
    use Forum::Form::CreateThread;
    use Forum::Util;
    use Pony::Crud::Dbh::MySQL;
    use Pony::Crud::MySQL;
    use Pony::Stash;
    
    sub show
        {
            my $this = shift;
            my $url  = $this->param('url');
            my $topicModel = new Pony::Crud::MySQL('topic');
            my ( $id, $topic );
            
            # Get Topic ID from requested url.
            # It can be string (url) or integer (id).
            
            if ( $url !~ /^\d*$/ )
            {
                $topic = [ $topicModel->list({url => $url}, undef,
                                                'threadId', undef, 0, 1) ]->[0];
                
                $id = $topic->{threadId};
            }
            else
            {
                $id = int $url;
                
                $topic = [ $topicModel->list({threadId => $id}, undef,
                                                'threadId', undef, 0, 1) ]->[0];
            }
            
            $topic = {} unless $topic;
            
            my $threadModel= new Pony::Crud::MySQL('thread');
            my $textModel  = new Pony::Crud::MySQL('text');
            my $userModel  = new Pony::Crud::MySQL('user');
            
            my $thread = $threadModel->read({ id => $id });
            
            # If user wanna topic - get topic start.
            # Else - just thread line.
            
            if ( $thread )
            {
                # Topic exists.
                #
                
                my $text = $textModel->read({ id => $thread->{textId} });
                %$topic = ( %$topic, %$text, %$thread );
            }
            
            my $ts = $userModel->read({ id => $thread->{userId} }) || {};
            $this->stash(ts => $ts);
            $this->stash(topic => $topic);
            
            my $page = int $this->param('page');
               $page = 1 if $page < 1;
             --$page;
            
            my $conf = Pony::Stash->findOrCreate( thread => { size => 50 } );
            
            my $threadModel = new Pony::Crud::MySQL('thread');
            my $thread  = ( $id > 0 ? $threadModel->read({ id => $id }) : {} );
            
            # A few crap for more speed.
            #
            
            my $q = sprintf 'SELECT th.id, th.createAt, th.modifyAt, th.parentId,
                                    th.topicId, th.userId, t.`text`, t1.title,
                                    t1.url, u.name, u.banId
                                FROM `thread` th
                                LEFT JOIN `text`  t  ON( th.textId  = t.id  )
                                LEFT JOIN `topic` t1 ON( t1.threadId= th.id )
                                LEFT JOIN `user`  u  ON( th.userId  = u.id  )
                                    WHERE th.topicId = \'%s\'
                                        ORDER BY t1.threadId, th.id ASC
                                        LIMIT %s, %s',
                            $id, $page * $conf->{size}, $conf->{size};
            
            my @threads = $threadModel->raw( $q );
            my $form = new Forum::Form::CreateThread;
            
            $this->stash( threads => \@threads );
            $this->stash( form    => $form     );
            $this->render;
        }
    
    sub create
        {
            my $this = shift;
            my $pid  = int $this->param('parentId');
            my $tid  = int $this->param('topicId');
            my $form = new Forum::Form::CreateThread;
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
            my $form = new Forum::Form::CreateTopic;
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

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

