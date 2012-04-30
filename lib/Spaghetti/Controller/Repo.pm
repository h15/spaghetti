package Spaghetti::Controller::Repo;
use Mojo::Base 'Mojolicious::Controller';
    
    use Pony::Stash;
    use Pony::Model::Crud::MySQL;
    use Pony::Model::Dbh::MySQL;
    use Spaghetti::Form::Repo::Create;
    use Spaghetti::Util;
    use Stuff::Git::Scanner;
    
    sub create
        {
            my $this    = shift;
            my $project = int $this->param('id');
            my $form    = new Spaghetti::Form::Repo::Create;
            
            my $thread = Pony::Model::Crud::MySQL->new('thread')
                           ->read({ id => $project });
            my $proj   = Pony::Model::Crud::MySQL->new('project')
                           ->read({ id => $project });
            
            # If project does not exist
            # - say "Bad request".
            
            $this->stop(400) unless $proj;
            
            %$proj = ( %$thread, %$proj );
            $form->action = $this->url_for('repo_create', id => $proj->{id});
            
            # Check: does user is owner of this project
            #        and does limit reached.
            
            $this->stop(400)
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
                    
                    my $title = $form->elements->{title}->value;
                    my $url   = $form->elements->{url}  ->value;
                    my $text  = $form->elements->{text} ->value;
                    my $owner = $form->elements->{owner}->value;
                    
                    # Prepare models.
                    #
                    
                    my $thModel = new Pony::Model::Crud::MySQL('thread');
                    my $teModel = new Pony::Model::Crud::MySQL('text');
                    my $reModel = new Pony::Model::Crud::MySQL('repo');
                    
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
                    Pony::Model::Crud::MySQL->new('project')->update
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
            my $repo = $this->param('repo');
            my $proj = $this->param('project');
            my $dbh  = Pony::Model::Dbh::MySQL->new->dbh;
            
            # Get repo.
            #
            
            my $sth = $dbh->prepare( $Spaghetti::SQL::repo->{read} );
               $sth->execute( $repo );
            
            $repo = $sth->fetchrow_hashref();
            
            # Does not exist.
            #
            
            $this->stop(404) unless $repo;
            
            # Get project manager.
            #
            
            my $pm = Pony::Model::Crud::MySQL
                       ->new('thread')
                         ->read({id => $repo->{topicId}}, ['owner'])
                           ->{owner};
            
            # Get data from git.
            #
            
            my $git = eval { new Stuff::Git::Scanner(@$repo{ qw/projectUrl url/ }) };
            $this->stop(418) if $@;
            
            my @logs = eval { $git->getLog(10) };
            
            # Prepare to render.
            #
            
            $this->stash( pm => $pm );
            $this->stash( repo => $repo );
            $this->stash( logs => \@logs );
        }
    
    sub readObject
        {
            my $this = shift;
            my $obj  = $this->param('object');
            my $repo = $this->param('repo');
            my $proj = $this->param('project');
            
            # Get repo.
            #
            
            my $dbh = Pony::Model::Dbh::MySQL->new->dbh;
            my $sth = $dbh->prepare( $Spaghetti::SQL::repo->{read} );
               $sth->execute( $repo );
            
            $repo = $sth->fetchrow_hashref();
            
            # Get commit from git.
            #
            
            my $git = eval { new Stuff::Git::Scanner($proj, $repo->{url}) };
            $this->stop(418) if $@;
            
            my ( $desc, $files, $data ) = $git->getCommit($obj);
            
            $this->stash( files   => $files);
            $this->stash( desc    => $desc );
            $this->stash( diff    => $data );
            $this->stash( repo    => $repo );
            $this->stash( project => $proj );
            $this->stash( object  => $obj  );
        }
    
    sub readBlob
        {
            my $this = shift;
            my $obj  = $this->param('object');
            my $repo = $this->param('repo');
            my $proj = $this->param('project');
            
            # Get repo.
            #
            
            my $dbh = Pony::Model::Dbh::MySQL->new->dbh;
            my $sth = $dbh->prepare( $Spaghetti::SQL::repo->{read} );
               $sth->execute( $repo );
            
            $repo = $sth->fetchrow_hashref();
            
            # Get commit from git.
            #
            
            my $git = eval { new Stuff::Git::Scanner($proj, $repo->{url}) };
            $this->stop(418) if $@;
            
            my $data = eval { $git->getBlob($obj) };
            
            $this->stash( blob    => $data );
            $this->stash( repo    => $repo );
            $this->stash( project => $proj );
            $this->stash( object  => $obj  );
        }
    
    sub readTree
        {
            my $this = shift;
            my $tree = $this->param('tree');
            my $obj  = $this->param('object');
            my $repo = $this->param('repo');
            my $proj = $this->param('project');
            
            # Get repo.
            #
            
            my $dbh = Pony::Model::Dbh::MySQL->new->dbh;
            my $sth = $dbh->prepare( $Spaghetti::SQL::repo->{read} );
               $sth->execute( $repo );
            
            $repo = $sth->fetchrow_hashref();
            
            # Get commit from git.
            #
            
            my $git = eval { new Stuff::Git::Scanner($proj, $repo->{url}) };
            $this->stop(418) if $@;
            
            my $files = $git->getTree($obj);
            
            $this->stash( files   => $files);
            $this->stash( repo    => $repo );
            $this->stash( project => $proj );
            $this->stash( object  => $obj  );
        }
    
    sub update
        {
            my $this = shift;
            my $url  = $this->param('repo');
            my $dbh  = Pony::Model::Dbh::MySQL->new->dbh;
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
            
            my $pm = Pony::Model::Crud::MySQL
                       ->new('thread')
                         ->read({ id => $repo->{topicId} }, ['owner']);
            
            $this->stop(400) unless $pm;
            
            $pm = $pm->{owner};
            
            # Allow access only for
            # owner and project owner.
            
            $this->stop(401)
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
                    
                    my $thModel = new Pony::Model::Crud::MySQL('thread');
                    my $teModel = new Pony::Model::Crud::MySQL('text');
                    my $reModel = new Pony::Model::Crud::MySQL('repo');
                    
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
            my $url  = $this->param('repo');
            my $dbh  = Pony::Model::Dbh::MySQL->new->dbh;
            
            # Get repo
            #
            
            my $sth = $dbh->prepare( $Spaghetti::SQL::repo->{read} );
               $sth->execute( $url );
            
            my $repo = $sth->fetchrow_hashref();
            my $id   = $repo->{id};
            
            $this->stop(400) unless $repo;
            
            # Get project owner (project manager)
            #
            
            my $pm = Pony::Model::Crud::MySQL->new('thread')
                       ->read({ id => $repo->{topicId} }, ['owner']);
            
            $this->stop(401) unless $pm;
            
            $pm = $pm->{owner};
            
            # Allow access only for
            # owner and project owner.
            
            $this->stop(401)
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
                
                my $model = new Pony::Model::Crud::MySQL('repoRightsViaUser');
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

