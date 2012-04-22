package Spaghetti::Controller::Admin::Thread;
use Mojo::Base 'Mojolicious::Controller';
    
    use Spaghetti::Form::Admin::Thread::Create;
    use Spaghetti::Util;
    use Pony::Model::Dbh::MySQL;
    use Pony::Model::Crud::MySQL;
    use Pony::Stash;
    
    # Admin edit simple thread.
    #
    
    sub edit
        {
            my $this = shift;
            my $id   = int $this->param('id');
            my $form = new Spaghetti::Form::Admin::Thread::Create;
               $form->action = $this->url_for('admin_thread_edit', id => $id);
            
            my $threadModel= new Pony::Model::Crud::MySQL('thread');
            my $textModel  = new Pony::Model::Crud::MySQL('text');
            
            my $thread = $threadModel->read({ id => $id });
            my $text   = $textModel  ->read({ id => $thread->{textId} });
            
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
                        { text => Spaghetti::Util::escape($text) },
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
            $this->render('admin/thread/edit');
        }

    sub addType
        {
            my $this   = shift;
            my $id     = int ( $this->param('id')   || 0 );
            my $typeId = int ( $this->param('type') || 0 );
            
            # Smth. wrong
            #
            
            $this->redirect_to('admin_thread_list') if $id == 0 || $typeId == 0;
            
            my $t2dtModel = new Pony::Model::Crud::MySQL('threadToDataType');
               $t2dtModel->create({threadId => $id, dataTypeId => $typeId});
            
            $this->redirect_to('admin_thread_show', id => $id);
        }
    
    sub removeType
        {
            my $this   = shift;
            my $id     = int ( $this->param('id')   || 0 );
            my $typeId = int ( $this->param('type') || 0 );
            
            # Smth. wrong
            #
            
            $this->redirect_to('admin_thread_list') if $id == 0 || $typeId == 0;
            
            my $t2dtModel = new Pony::Model::Crud::MySQL('threadToDataType');
               $t2dtModel->delete({threadId => $id, dataTypeId => $typeId});
            
            $this->redirect_to('admin_thread_show', id => $id);
        }
    
    sub show
        {
            my $this = shift;
            my $id   = int ( $this->param('id') || 0 );
            
            # Get types
            #
            
            my @types = Pony::Model::Crud::MySQL->new('dataType')->list;
            my @t = map { $_->{dataTypeId} }
                      Pony::Model::Crud::MySQL
                        ->new('threadToDataType')
                          ->list({threadId => $id},['dataTypeId'],'dataTypeId');
            
            # Get thread
            #
            
            my $thread= Pony::Model::Crud::MySQL->new('thread')->read({id => $id});
            my $text  = Pony::Model::Crud::MySQL->new('text')->read({threadId => $id});
            my $topic = [Pony::Model::Crud::MySQL->new('topic')->list
                        ({threadId => $id},undef,'threadId',undef,0,1)]->[0];
            
            $this->redirect_to('admin_thread_list') unless exists $thread->{id};
            $this->redirect_to('admin_thread_list') unless exists $text->{id};
            
            %$thread = ( %$text, %$thread  );
            %$thread = ( %$topic, %$thread ) if exists $topic->{threadId};
            
            $this->stash( thread      => $thread );
            $this->stash( types       => \@types );
            $this->stash( threadTypes => \@t );
            $this->render('admin/thread/show');
        }
    
    sub list
        {
            my $this = shift;
            
            # Paginator
            #
            
            my $page = int ( $this->param('page') || 0 );
               $page = 1 if $page < 1;
            
            # Get data
            #
            
            my $size = Pony::Stash->get('thread')->{size};
            
            my $dbh = Pony::Model::Dbh::MySQL->new->dbh;
            my $sth = $dbh->prepare( $Spaghetti::SQL::thread->{show_admin} );
               $sth->execute(($page-1)*$size, $size);
            my $threads = $sth->fetchall_hashref('id');
            my $count = Pony::Model::Crud::MySQL->new('thread')->count;
            
            # Prepare render
            #
            
            $this->stash( paginator => $this->paginator
                            ('admin_thread_list_p', $page, $count, $size) );
            $this->stash( threads => $threads );
            $this->render('admin/thread/list');
        }
    
1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

