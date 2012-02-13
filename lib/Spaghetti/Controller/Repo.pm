package Spaghetti::Controller::Repo;
use Mojo::Base 'Mojolicious::Controller';
    
    use Pony::Stash;
    use Pony::Crud::MySQL;
    use Pony::Crud::Dbh::MySQL;
    use Spaghetti::Form::Repo::Create;
    use Spaghetti::Util;
    
    sub create
        {
            my $this    = shift;
            my $project = int $this->param('id');
            my $form    = new Spaghetti::Form::Repo::Create;
            
            my $thread = Pony::Crud::MySQL->new('thread')
                           ->read({ id => $project });
            my $proj   = Pony::Crud::MySQL->new('project')
                           ->read({ id => $project });
            
            # If project does not exist - get out here.
            #
            
            return $this->redirect_to( $this->req->headers->referrer )
                unless defined $proj;
            
            %$proj = ( %$thread, %$proj );
            $form->action = $this->url_for('repo_create', id => $proj->{id});
            
            # Check: does user is owner of this project
            #        and does limit reached.
            
            return $this->redirect_to( $this->req->headers->referrer )
                unless $proj->{owner} == $this->user->{id}
                       && $proj->{maxRepo} > $proj->{repos};
            
            # Create repo on POST request.
            # Show create form in other case.
            
            if ( $this->req->method eq 'POST' )
            {
                $form->data->{$_} = $this->param($_) for keys %{$form->elements};
                
                if ( $form->isValid )
                {
                    # Get data from form.
                    #
                    
                    my $title = $form->elements->{title}   ->value;
                    my $url   = $form->elements->{url}     ->value;
                    my $text  = $form->elements->{text}    ->value;
                    my $owner = $form->elements->{owner}   ->value;
                    
                    # Prepare models.
                    #
                    
                    my $thModel = new Pony::Crud::MySQL('thread');
                    my $teModel = new Pony::Crud::MySQL('text');
                    my $reModel = new Pony::Crud::MySQL('repo');
                    
                    # Create records in database.
                    #
                    
                    my $thId = $thModel->create
                               ({
                                    author   => $owner,
                                    owner    => $owner,
                                    createAt => time,
                                    modifyAt => time,
                                    parentId => $project,
                                    topicId  => $project,
                               });
                               
                    my $teId = $teModel->create
                               ({
                                    threadId => $thId,
                                    text     => Spaghetti::Util::escape($text),
                               });
                    
                    $thModel->update( { textId => $teId },
                                      { id     => $thId } );
                    
                    $reModel->create
                    ({
                        id    => $thId,
                        url   => $url,
                        title => $title
                    });
                    
                    # Repos++
                    #
                    Pony::Crud::MySQL->new('project')->update
                    (
                        { repos => $proj->{repos} + 1 },
                        { id => $proj->{id} }
                    );
                    
                    # All is done - let's see that!
                    #
                    
                    return $this->redirect_to(repo_update => url => $url);
                }
            }
            
            $this->stash( form => $form->render );
        }

    sub read
        {
            my $this = shift;
            my $url  = $this->param('url');
            my $dbh  = Pony::Crud::Dbh::MySQL->new->dbh;
            
            # Get repo
            #
            
            my $sth = $dbh->prepare( $Spaghetti::SQL::repo->{read} );
               $sth->execute( $url );
            
            my $repo = $sth->fetchrow_hashref();
            
            return $this->redirect_to( $this->req->headers->referrer )
                unless defined $repo;
            
            # Get project manager
            #
            
            my $pm = Pony::Crud::MySQL->new('thread')
                       ->read({ id => $repo->{topicId} }, ['owner'])->{owner};
            
            # Prepare to render
            #
            
            $this->stash( pm => $pm );
            $this->stash( repo => $repo );
        }
    
    sub update
        {
            my $this = shift;
            my $url  = $this->param('url');
            my $dbh  = Pony::Crud::Dbh::MySQL->new->dbh;
            my $form = new Spaghetti::Form::Repo::Create;
               $form->action = $this->url_for(repo_update => url => $url);
            
            # Get repo
            #
            
            my $sth = $dbh->prepare( $Spaghetti::SQL::repo->{read} );
               $sth->execute( $url );
            
            my $repo = $sth->fetchrow_hashref();
            my $id   = $repo->{id};
            
            return $this->redirect_to(repo_read => url => $url) unless $repo;
            
            # Get project owner (project manager)
            #
            
            my $pm = Pony::Crud::MySQL->new('thread')
                       ->read({ id => $repo->{topicId} }, ['owner']);
            
            return $this->redirect_to(repo_read => url => $url) unless $pm;
            
            $pm = $pm->{owner};
            
            # Allow access only for
            # owner and project owner.
            
            return $this->redirect_to( $this->req->headers->referrer )
                unless $repo->{owner} == $this->user->{id}
                       || $pm == $this->user->{id};
            
            # Edit repo on POST request.
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
                    my $reModel = new Pony::Crud::MySQL('repo');
                    
                    # Update records in database.
                    #
                    
                    $thModel->update
                    (
                        { owner => $owner },
                        { id    => $id    }
                    );
                    
                    $teModel->update
                    (
                        { text => $text },
                        { id   => $repo->{textId} }
                    );
                    
                    $reModel->update
                    (
                        { url   => $url,
                          title => $title },
                        { id    => $id    }
                    );
                    
                    # All is done - let's see that!
                    #
                    
                    return $this->redirect_to(repo_read => url => $url);
                }
            }
            
            for my $e ( keys %{ $form->{elements} } )
            {
                $form->elements->{$e}->value = $repo->{$e};
            }
            
            $this->stash( repo => $repo );
            $this->stash( form => $form->render );
        }
    
    sub changeAccess
        {
            my $this = shift;
            my $url  = $this->param('url');
            my $dbh  = Pony::Crud::Dbh::MySQL->new->dbh;
            
            # Get repo
            #
            
            my $sth = $dbh->prepare( $Spaghetti::SQL::repo->{read} );
               $sth->execute( $url );
            
            my $repo = $sth->fetchrow_hashref();
            my $id   = $repo->{id};
            
            return $this->redirect_to(repo_read => url => $url) unless $repo;
            
            # Get project owner (project manager)
            #
            
            my $pm = Pony::Crud::MySQL->new('thread')
                       ->read({ id => $repo->{topicId} }, ['owner']);
            
            return $this->redirect_to(repo_read => url => $url) unless $pm;
            
            $pm = $pm->{owner};
            
            # Allow access only for
            # owner and project owner.
            
            return $this->redirect_to( $this->req->headers->referrer )
                unless $repo->{owner} == $this->user->{id}
                       || $pm == $this->user->{id};
            
            # Edit repo on POST request.
            # Show edit form in other case.
            
            if ( $this->req->method eq 'POST' )
            {
                my $user = $this->param('user');
            
                my $r = ( $this->param('r') ? 1 : 0 );
                my $w = ( $this->param('w') ? 1 : 0 );
                my $p = ( $this->param('p') ? 1 : 0 );
                my $c = ( $this->param('c') ? 1 : 0 );
                my $d = ( $this->param('d') ? 1 : 0 );
                
                my $access = 16*$d + 8*$c + 4*$p + 2*$w + $r;
                
                my $model = new Pony::Crud::MySQL('repoRightsViaUser');
                my $where = { repoId => $id, userId => $user };
                
                if ( $access != 1 )
                {
                    if ( $model->read($where) )
                    {
                        $model->update
                        (
                            { rwpcd => $access },
                            $where
                        );
                    }
                    else
                    {
                        $model->create({ %$where, rwpcd => $access });
                    }
                }
                else
                {
                    $model->delete($where);
                }
                
            }
            
            # Get access list
            #
            
            $sth = $dbh->prepare( $Spaghetti::SQL::repo->{userAccessList} );
            $sth->execute( $repo->{id} );
            
            my $accessList = $sth->fetchall_hashref('id');
            
            $this->stash( repo => $repo );
            $this->stash( url => $url );
            $this->stash( accessList => $accessList );
        }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

