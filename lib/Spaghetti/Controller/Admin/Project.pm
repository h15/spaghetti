package Spaghetti::Controller::Admin::Project;
use Mojo::Base 'Mojolicious::Controller';
    
    use Pony::Stash;
    use Pony::Crud::MySQL;
    use Pony::Crud::MySQL::Dbh;
    use Spaghetti::Form::Admin::Project::Create;
    use Spaghetti::Util::escape;
    
    sub create
        {
            my $this = shift;
            my $form = new Spaghetti::Form::Admin::Project::Create;
            
            if ( $this->req->method eq 'POST' )
            {
                $form->data->{$_} = $this->param($_) for keys %{$form->elements};
                
                if ( $form->isValid )
                {
                    # Get data from form.
                    #
                    
                    my $title = $form->elements->{title} ->value;
                    my $url   = $form->elements->{url}   ->value;
                    my $text  = $form->elements->{text}  ->value;
                    my $owner = $form->elements->{owner} ->value;
                    my $parent= $form->elements->{parent}->value;
                    my $topic = $form->elements->{topic} ->value;
                    
                    # Prepare models.
                    #
                    
                    my $thModel = new Pony::Crud::MySQL('thread');
                    my $teModel = new Pony::Crud::MySQL('text');
                    my $prModel = new Pony::Crud::MySQL('project');
                    
                    # Create records in database.
                    #
                    
                    my $thId = $thModel->create
                               ({
                                    author   => $owner,
                                    owner    => $owner,
                                    createAt => time,
                                    modifyAt => time,
                                    parentId => $parent,
                                    topicId  => $topic,
                               });
                               
                    my $teId = $teModel->create
                               ({
                                    threadId => $thId,
                                    text     => Spaghetti::Util::escape($text),
                               });
                    
                    $thModel->update( { textId => $teId },
                                      { id     => $thId } );
                    
                    $prModel->create
                    ({
                        id    => $thId,
                        url   => $url,
                        title => $title,
                        repos => 0
                    });
                    
                    # All is done - let's see that!
                    #
                    
                    $this->redirect_to( admin_project_edit => id => $id );
                }
            }
            
            $this->stash( form => $form->render );
            $this->render('admin/project/create');
        }
    
    sub list
        {
            my $this = shift;
            
            # Paginator
            #
            
            my $page = int ( $this->param('page') || 0 );
               $page = 1 if $page < 1;
            
            # Get project list and count
            #
            
            my $size = Pony::Stash->get('thread')->{size};
            
            my $projects = Pony::Crud::MySQL->new('project')
                             ->list( undef, undef, undef, undef,
                                        ($page - 1) * $size, $size );
            
            my $count = Pony::Crud::MySQL->new('project')->count;
            
            # Prepare to render
            #
            
            $this->stash( projects => $projects );
            $this->stash( paginator =>
                $this->paginator('admin_project_list', $page, $count, $size) );
        }
    
    sub read
        {
            my $this = shift;
            my $id   = int $this->param('id');
            
            # Get project info
            # and get project's repos list.
            
            my $project = Pony::Crud::MySQL->new('project')->read({id => $id});
            
            my $sth = $dbh->prepare( $Spaghetti::SQL::repo->{list} );
               $sth->execute( $project->{id} );
            
            my $repos = $sth->fetchall_hashref('id');
            
            # Prepare to render
            #
            
            $this->stash( project => $project );
            $this->stash( repos   => $repos   );
        }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

