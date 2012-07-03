
# Class: Spaghetti::Controller::Repo
# | Repo controller. There are many actions
# | for working with repositories.
# | Access allows to all.
# | Params provides by $this->param.
# | Returns data to $this->stash.
#
# Extends: Mojolicious::Controller
#
# See Also:
#   <Stuff::Git::Scanner>

package Spaghetti::Controller::Repo;
use Mojo::Base 'Mojolicious::Controller';
    
    use Pony::Stash;
    use Pony::Model::Crud::MySQL;
    use Pony::Model::Dbh::MySQL;
    use Spaghetti::Form::Repo::Create;
    use Spaghetti::Util;
    use Stuff::Git::Scanner;
    use Error ':try';
    
    
    # Function: create
    # | Action. Create repository using user's data.
    # | Stops request with bad status if project does not exists
    # | or when limit reachedl or user is not owner.
    #
    # Parameters:
    #   project - Id of project.
    #
    # Returns:
    #   form - Generated html code.
    #
    # Events:
    #   Redirect to "All done" page on success.
    
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
                $form->data->{$_} = $this->param($_)
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
                    
                    return $this->redirect_to( repo_update => repo => $url,
                                                project => $proj->{url} );
                }
            }
            
            $this->stash( form => $form->render );
        }
    
    
    # Function: read
    # | Reads repository log and root tree
    # | repository name and project name.
    #
    # Parametrs:
    #   repo - repository url
    #   proj - project url
    #
    # Returns:
    #   files - Array ref to files in root tree.
    #   dirs - Array ref to dirs in root tree.
    #   pm - Project manager info (user).
    #   repo - Repository info.
    #   logs - Log list for last 3 records.
    
    sub read
        {
            my $this = shift;
            my $repo = $this->param('repo');
            my $proj = $this->param('project');
            my $dbh  = Pony::Model::Dbh::MySQL->new->dbh;
            
            # Get repo.
            #
            
            my $sth = $dbh->prepare( $Spaghetti::SQL::repo->{read} );
               $sth->execute( $repo, $proj );
            
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
            
            my $git;
            
            try
            {
                $git = new Stuff::Git::Scanner(@$repo{ qw/projectUrl url/ })
            }
            catch Stuff::Exception::IO with
            {
                my $exc = shift;
                $this->stop(418);
            };
            
            my @logs = eval { $git->getLog(3) };
            
            # Get commit from git.
            #
            
            my $files = $git->getTree('HEAD');
            my @dirs = grep { $_->{type} eq 'tree' } @$files;
             @$files = grep { $_->{type} eq 'blob' } @$files;
            
            # Prepare to render.
            #
            
            $this->stash( files=> $files );
            $this->stash( dirs => \@dirs );
            $this->stash( pm   => $pm    );
            $this->stash( repo => $repo  );
            $this->stash( logs => \@logs );
        }
    
    
    # Function: readLogs
    #   In work.
    # TODO: Show paged log list for this repo.
    
    sub readLogs
        {
            my $this = shift;
            my $repo = $this->param('repo');
            my $proj = $this->param('project');
            my $page = $this->param('page');
            
            # Get repo.
            #
            
            my $sth = $dbh->prepare( $Spaghetti::SQL::repo->{read} );
               $sth->execute( $repo, $proj );
            
            $repo = $sth->fetchrow_hashref();
            
            # Paginator.
            #
            
            my $page = int ( $this->param('page') || 0 );
               $page = 1 if $page < 1;
            
            my $size = Pony::Stash->get('thread')->{size};
            
            # Get data from git.
            #
            
            my $git;
            
            try
            {
                $git = new Stuff::Git::Scanner(@$repo{ qw/projectUrl url/ })
            }
            catch Stuff::Exception::IO with
            {
                my $exc = shift;
                $this->stop(418);
            };
            
            $this->stop(418) if $@;
            
            my @logs = eval { $git->getLog(1000) };
            my $count = {count => 0};
            
            # Rendering.
            #
            
            $this->stash( logs => \@logs );
            $this->stash( repo => $repo  );
            $this->stash( paginator =>
                            $this->paginator( repo_readLogs =>
                                $page, $count->{count}, $size,
                                [ repo => $repo, project => $proj ] ) );
            
        }
    
    
    # Function: readObject
    # | Read git diff.
    # | Will returns "I'm teapot" on git read error.
    #
    # Paramerts:
    #   obj - Id of git object, where describes diff.
    #   repo - Url of repo.
    #   proj - Url of project.
    #
    # Returns:
    #   files - List of changed files.
    #   desc - Commit comment.
    #   diff - Lines of diff.
    #   repo - Repo url.
    #   project - Project url.
    #   object - Git object id.
    
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
               $sth->execute( $repo, $proj );
            
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
    
    
    # Function: readBlob
    # | Read file of git tree.
    # | Will returns "I'm teapot" on git read error.
    #
    # Paramerts:
    #   obj - Git object id.
    #   repo - Repo url.
    #   proj - project url.
    #
    # Returns:
    #   blob - Lines of file.
    #   repo - Repo url.
    #   project - Project url.
    #   object - Git object id.
    
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
               $sth->execute( $repo, $proj );
            
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
    
    
    # Function: readBlobPath
    # | Read file of git tree.
    # | Will returns "I'm teapot" on git read error.
    # | It's more sapient version of readBlob.
    #
    # Paramerts:
    #   obj - Git object id.
    #   repo - Repo url.
    #   proj - project url.
    #
    # Returns:
    #   blob - Lines of file.
    #   repo - Repo url.
    #   project - Project url.
    #   object - Git object id.
    
    sub readBlobPath
        {
            my $this = shift;
            my $obj  = $this->param('object');
            my $repo = $this->param('repo');
            my $proj = $this->param('project');
            my $path = $this->param('dir');
            
            $path = substr $path, 1;
            
            # Get repo.
            #
            
            my $dbh = Pony::Model::Dbh::MySQL->new->dbh;
            my $sth = $dbh->prepare( $Spaghetti::SQL::repo->{read} );
               $sth->execute( $repo, $proj );
            
            $repo = $sth->fetchrow_hashref();
            
            # Get commit from git.
            #
            
            my $git = eval { new Stuff::Git::Scanner($proj, $repo->{url}) };
            $this->stop(418) if $@;
            
            my $data = eval { $git->getBlob($obj, $path) };
            
            $this->stash( blob    => $data );
            $this->stash( repo    => $repo );
            $this->stash( project => $proj );
            $this->stash( object  => $obj  );
            
            $this->render('repo/readBlob');
        }
    
    
    # Function: readTree
    # | Read tree's directory.
    # | Returns "I'm teapot" on git read error.
    #
    # Parametrs:
    #   tree - Git id of tree.
    #   obj - Object Id.
    #   repo - Repo url.
    #   proj - Project url.
    #
    # Returns:
    #   files - List of files in this dir.
    #   dirs - List of dirs in this dir.
    #   repo - Repo info.
    #   project - Project url.
    #   object - Object url.
    
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
               $sth->execute( $repo, $proj );
            
            $repo = $sth->fetchrow_hashref();
            
            # Get commit from git.
            #
            
            my $git = eval { new Stuff::Git::Scanner($proj, $repo->{url}) };
            $this->stop(418) if $@;
            
            my $files = $git->getTree($obj);
            my @dirs = grep { $_->{type} eq 'tree' } @$files;
             @$files = grep { $_->{type} eq 'blob' } @$files;
            
            $this->stash( files   => $files);
            $this->stash( dirs    => \@dirs);
            $this->stash( repo    => $repo );
            $this->stash( project => $proj );
            $this->stash( object  => $obj  );
        }
    
    
    # Function: readTreePath
    # | Read tree's directory.
    # | Returns "I'm teapot" on git read error.
    # | It's more sapient version of readTree.
    #
    # Parametrs:
    #   tree - Git id of tree.
    #   obj - Object Id.
    #   repo - Repo url.
    #   proj - Project url.
    #
    # Returns:
    #   files - List of files in this dir.
    #   dirs - List of dirs in this dir.
    #   repo - Repo info.
    #   project - Project url.
    #   object - Object url.
    
    sub readTreePath
        {
            my $this = shift;
            my $tree = $this->param('tree');
            my $obj  = $this->param('object');
            my $repo = $this->param('repo');
            my $proj = $this->param('project');
            my $path = $this->param('dir');
            
            $path = substr $path, 1;
            
            # Get repo.
            #
            
            my $dbh = Pony::Model::Dbh::MySQL->new->dbh;
            my $sth = $dbh->prepare( $Spaghetti::SQL::repo->{read} );
               $sth->execute( $repo, $proj );
            
            $repo = $sth->fetchrow_hashref();
            
            # Get commit from git.
            #
            
            my $git = eval { new Stuff::Git::Scanner($proj, $repo->{url} ) };
            $this->stop(418) if $@;
            
            my $files = $git->getTree($obj, $path);
            my @dirs = grep { $_->{type} eq 'tree' } @$files;
             @$files = grep { $_->{type} eq 'blob' } @$files;
            
            $this->stash( files   => $files);
            $this->stash( dirs    => \@dirs);
            $this->stash( repo    => $repo );
            $this->stash( project => $proj );
            $this->stash( object  => $obj  );
            
            $this->render('repo/readTree');
        }
    
    
    # Function: update
    #   Update repo info.
    #
    # Parametrs:
    #   url - Repo url.
    #   proj - Project url.
    #
    # Returns:
    #   repo - Repository info.
    #   form - Html form.
    #
    # Events:
    #   Redirect on success.
    
    sub update
        {
            my $this = shift;
            my $url  = $this->param('repo');
            my $proj = $this->param('project');
            my $dbh  = Pony::Model::Dbh::MySQL->new->dbh;
            my $form = new Spaghetti::Form::Repo::Create;
               $form->action = $this->url_for( repo_update => repo => $url,
                                                            project => $proj );
            
            # Get repo
            #
            
            my $sth = $dbh->prepare( $Spaghetti::SQL::repo->{read} );
               $sth->execute( $url, $proj );
            
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
                    
                    return $this->redirect_to( repo_read => repo => $url,
                                                    project => $proj );
                }
            }
            
            for my $e ( keys %{ $form->{elements} } )
            {
                $form->elements->{$e}->value = $repo->{$e};
            }
            
            $this->stash( repo => $repo );
            $this->stash( form => $form->render );
        }
    
    
    # Function: changeAccess
    #   Change repo ACL.
    #
    # Paramerts:
    #   url - Repo url.
    #   proj - Project url.
    #
    # Returns:
    #   repo - Reposytory info.
    #   url - Repo url.
    #   accessList - ACL for this repo.
    
    sub changeAccess
        {
            my $this = shift;
            my $url  = $this->param('repo');
            my $proj = $this->param('project');
            my $dbh  = Pony::Model::Dbh::MySQL->new->dbh;
            
            # Get repo
            #
            
            my $sth = $dbh->prepare( $Spaghetti::SQL::repo->{read} );
               $sth->execute( $url, $proj );
            
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
