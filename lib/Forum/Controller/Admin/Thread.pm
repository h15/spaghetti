package Forum::Controller::Admin::Thread;
use Mojo::Base 'Mojolicious::Controller';
    
    use Forum::Form::Admin::Thread::Create;
    use Forum::Util;
    use Pony::Crud::Dbh::MySQL;
    use Pony::Crud::MySQL;
    use Pony::Stash;
    
    # Admin edit simple thread.
    #
    
    sub edit
        {
            my $this = shift;
            my $id   = int $this->param('id');
            my $form = new Forum::Form::Admin::Thread::Create;
               $form->action .= "/$id";
            
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
                        {
                            modifyAt    => time,
                            parentId    => $thread->{parentId},
                            topicId     => $thread->{topicId},
                        },
                        { id => $thread->{id} }
                    );
                               
                    $textModel->update
                    (
                        { text => Forum::Util::escape($text) },
                        { id => $thread->{textId} }
                    );
                    
                    $this->redirect_to( admin_thread_edit => url => $thread->{id});
                }
            }
            
            for my $k ( keys %{$form->elements} )
            {
                $form->elements->{$k}->value = $text->{$k}   if exists $text->{$k};
                $form->elements->{$k}->value = $thread->{$k} if exists $thread->{$k};
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

