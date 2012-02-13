package Spaghetti::Controller::Project;
use Mojo::Base 'Mojolicious::Controller';
    
    use Pony::Stash;
    use Pony::Crud::MySQL;
    use Pony::Crud::Dbh::MySQL;
    use Spaghetti::Form::Project::Create;
    use Spaghetti::Util;
    
    sub read
        {
            my $this = shift;
            my $url  = $this->param('url');
            my $dbh  = Pony::Crud::Dbh::MySQL->new->dbh;
            my $conf = Pony::Stash->get('project');
            
            # Get project
            #
            
            my $sth = $dbh->prepare( $Spaghetti::SQL::project->{read} );
               $sth->execute( $url );
               
            my $project = $sth->fetchrow_hashref();
            
            return $this->redirect_to('/404') unless $project;
            
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
            my $dbh  = Pony::Crud::Dbh::MySQL->new->dbh;
            my $form = new Spaghetti::Form::Project::Create;
               $form->action = $this->url_for('project_update', url => $url);
            
            # Get project
            #
            
            my $sth = $dbh->prepare( $Spaghetti::SQL::project->{read} );
               $sth->execute( $url );
            
            my $project = $sth->fetchrow_hashref();
            
            return $this->redirect_to ( $this->req->headers->referer )
                unless $project;
            
            my $id = $project->{id};
            
            # Allow access only for
            # project owner.
            
            return $this->redirect_to( $this->req->headers->referrer )
                unless $project->{owner} == $this->user->{id};
            
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
                    
                    my $thModel = new Pony::Crud::MySQL('thread');
                    my $teModel = new Pony::Crud::MySQL('text');
                    my $prModel = new Pony::Crud::MySQL('project');
                    
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

