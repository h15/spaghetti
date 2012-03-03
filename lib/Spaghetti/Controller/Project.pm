package Spaghetti::Controller::Project;
use Mojo::Base 'Mojolicious::Controller';
    
    use Pony::Stash;
    use Pony::Model::Crud::MySQL;
    use Pony::Model::Dbh::MySQL;
    use Spaghetti::Form::Project::Create;
    use Spaghetti::Util;
    
    sub list
        {
            my $this = shift;
            
            # Some smart
            # SELECT
        }
    
    sub listByAbc
        {
            my $this   = shift;
            my $letter = shift;
            my $dbh    = Pony::Model::Dbh::MySQL->new->dbh;
            my $size   = Pony::Stash->get('thread')->{size};
            
            # Paginator
            #
            
            my $page = int ( $this->param('page') || 0 );
               $page = 1 if $page < 1;
            
            # Get project list.
            #
            
            my $sth = $dbh->prepare( $Spaghetti::SQL::project->{listByAbc} );
               $sth->execute( #$this->user->{id},
                              "$letter%", ($page - 1)*$size, $size );
            
            my $projects = $sth->fetchall_hashref('id');
            
            my $count = Pony::Model::Crud::MySQL->new('project')->count;
            
            # Prepare to render.
            #
            
            $this->stash( paginator =>
                            $this->paginator( 'thread_show_p', $page,
                                $count, $size, [ letter => $letter ] ) );
            
            $this->stash( projects => $projects );
        }
    
    sub read
        {
            my $this = shift;
            my $url  = $this->param('url');
            my $dbh  = Pony::Model::Dbh::MySQL->new->dbh;
            my $conf = Pony::Stash->get('project');
            
            # Get project
            #
            
            my $sth = $dbh->prepare( $Spaghetti::SQL::project->{read} );
               $sth->execute( $url );
               
            my $project = $sth->fetchrow_hashref();
            
            # Project with this url
            # does not exist.
            
            $this->stop(404) unless $project;
            
            # Get project's repos
            #
            
            $sth = $dbh->prepare( $Spaghetti::SQL::repo->{list} );
            $sth->execute( $project->{id} );
            
            my $repos = $sth->fetchall_hashref('id');
            
            # Prepare to render
            #
            
            $this->stash( conf    => $conf    );
            $this->stash( project => $project );
            $this->stash( repos   => $repos   );
        }	
    
    sub update
        {
            my $this = shift;
            my $url  = $this->param('url');
            my $dbh  = Pony::Model::Dbh::MySQL->new->dbh;
            my $form = new Spaghetti::Form::Project::Create;
               $form->action = $this->url_for('project_update', url => $url);
            
            # Get project
            #
            
            my $sth = $dbh->prepare( $Spaghetti::SQL::project->{read} );
               $sth->execute( $url );
            
            my $project = $sth->fetchrow_hashref();
            
            # Does not exist.
            #
            
            $this->stop(400) unless $project;
            
            my $id = $project->{id};
            
            # Allow access only for
            # project owner.
            
            $this->stop(401) unless $project->{owner} == $this->user->{id};
            
            # Edit project on POST request.
            # Show edit form in other case.
            
            if ( $this->req->method eq 'POST' )
            {
                $form->data->{$_} = $this->req->body_params->param($_)
                                                for keys %{$form->elements};
                
                if ( $form->isValid )
                {
                    # Get data from form.
                    #
                    
                    my $title = $form->elements->{title}->value;
                    my $url   = $form->elements->{url}  ->value;
                    my $text  = $form->elements->{text} ->value;
                    my $owner = $form->elements->{owner}->value;
                    
                    # Prepare models.
                    #
                    
                    my $thModel = new Pony::Model::Crud::MySQL('thread');
                    my $teModel = new Pony::Model::Crud::MySQL('text');
                    my $prModel = new Pony::Model::Crud::MySQL('project');
                    
                    # Update records in database.
                    #
                    
                    $thModel->update
                    (
                        { owner => $owner },
                        { id    => $id    }
                    );
                    
                    $teModel->update
                    (
                        { text => Spaghetti::Util::escape($text) },
                        { id   => $project->{textId} }
                    );
                    
                    $prModel->update
                    (
                        { url   => $url,
                          title => $title },
                        { id    => $id    }
                    );
                    
                    # All is done - let's see that!
                    #
                    
                    return $this->redirect_to(project_read => url => $url);
                }
            }
            
            for my $e ( keys %{ $form->{elements} } )
            {
                $form->elements->{$e}->value = $project->{$e};
            }
            
            $this->stash( project => $project );
            $this->stash( form => $form->render );
        }
    
1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

