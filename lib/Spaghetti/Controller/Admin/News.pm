package Spaghetti::Controller::Admin::News;
use Mojo::Base 'Mojolicious::Controller';
    
    use Spaghetti::Form::Admin::News::FromTopic;
    use Spaghetti::Form::Admin::News::Edit;
    use Spaghetti::Util;
    use Pony::Model::Crud::MySQL;
    use Pony::Stash;
    
    sub topicToNews
        {
            my $this = shift;
            my $id   = $this->param('id');
            my $form = new Spaghetti::Form::Admin::News::FromTopic;
               $form->action = $this->url_for('admin_news_topicToNews', id => $id);
            
            my $thModel = new Pony::Model::Crud::MySQL('thread');
            my $teModel = new Pony::Model::Crud::MySQL('text');
            my $toModel = new Pony::Model::Crud::MySQL('topic');
            
            # Create news from thread.
            #
            if ( $this->req->method eq 'POST' )
            {
                $form->data->{$_} = $this->param($_) for keys %{$form->elements};
                
                if ( $form->isValid )
                {
                    my $title = $form->elements->{title} ->value;
                    my $url   = $form->elements->{url}   ->value;
                    my $legend= $form->elements->{legend}->value;
                    
                    my $thread = $thModel->read({id => $id});
                    
                    $thModel->update({ modifyAt => time,
                                       owner    => $this->user->{id} },
                                     { id => $id });
                    $toModel->update({ title => $title,
                                       url   => $url  },
                                     { threadId => $id });
                    
                    Pony::Model::Crud::MySQL->new('news')->create
                    ({
                        threadId => $id,
                        legend   => $legend
                    });
                    
                    $this->redirect_to( admin_news_edit => id => $id);
                }
            }
            
            # Fill form and show it.
            #
            my $thread = $thModel->read({id => $id});
            my $text   = $teModel->read({id => $thread->{textId}});
            my $topic  = [ $toModel->list
                            ({threadId => $id},undef,'threadId',undef,0,1) ]->[0];
            
            %$thread = (%$text, %$topic, %$thread);
            
            $form->elements->{$_}->value = $thread->{$_} for keys %{$form->elements};
            
            $this->stash( form  => $form->render() );
            $this->render('admin/news/topicToNews');
        }
    
    sub edit
        {
            my $this = shift;
            my $id   = $this->param('id');
            my $form = new Spaghetti::Form::Admin::News::Edit;
               $form->action = $this->url_for('admin_news_edit', id => $id);
            
            my $thModel = new Pony::Model::Crud::MySQL('thread');
            my $teModel = new Pony::Model::Crud::MySQL('text');
            my $toModel = new Pony::Model::Crud::MySQL('topic');
            my $neModel = new Pony::Model::Crud::MySQL('news');
            
            if ( $this->req->method eq 'POST' )
            {
                $form->data->{$_} = $this->param($_) for keys %{$form->elements};
                
                if ( $form->isValid )
                {
                    my $title = $form->elements->{title} ->value;
                    my $url   = $form->elements->{url}   ->value;
                    my $legend= $form->elements->{legend}->value;
                    my $text  = $form->elements->{text}  ->value;
                    
                    my $thread  = $thModel->read({id => $id});
                    my $oldText = $teModel->read({id => $thread->{textId}});
                    
                    # If text changed - create new record.
                    #
                    my $textId = $oldText->{text} ne $text ?
                                    $teModel->create
                                    ({
                                        text => Spaghetti::Util::escape($text),
                                        threadId => $id
                                    }):
                                    $thread->{textId};
                    
                    $thModel->update({textId => $textId} => {id => $id});
                    $neModel->update({legend => $legend} => {threadId => $id});
                    
                    $toModel->update({ title => $title, url => $url },
                                     { threadId => $id });
                    
                    $this->redirect_to( thread_show => url => $url );
                }
            }
            
            # Fill form and show it.
            #
            my $topic  =[$toModel->list({threadId => $id},undef,'threadId',undef,0,1)]->[0];
            my $thread = $thModel->read({id => $topic->{threadId}});
            my $text   = $teModel->read({id => $thread->{textId}});
            my $news   =[$neModel->list({threadId => $id},undef,'threadId',undef,0,1)]->[0];
            
            %$thread = ( %$text, %$topic, %$news, %$thread );
            
            $form->elements->{$_}->value = $thread->{$_} for keys %{$form->elements};
            
            $this->stash( form  => $form->render() );
            $this->render('admin/news/edit');
        }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

