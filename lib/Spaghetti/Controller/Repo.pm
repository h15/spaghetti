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
            
            my $repos = Pony::Stash->get('project')->{repos};
            
            # Check: does user is owner of this project
            #        and does limit reached.
            
            return $this->redirect_to( $this->req->headers->referrer )
                unless $proj->{owner} == $this->user->{id}
                       && $repos >= $proj->{repos};
            
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
                    
                    return $this->redirect_to(repo_edit => id => $thId);
                }
            }
            
            $this->stash( form => $form->render );
        }

    sub read
        {
            my $this = shift;
            my $url  = $this->param('url');
            my $dbh  = Pony::Crud::Dbh::MySQL->new->dbh;
            
            my $sth = $dbh->prepare( $Spaghetti::SQL::repo->{read} );
               $sth->execute( $url );
            
            my $repo = $sth->fetchrow_hashref();
            
            return $this->redirect_to( $this->req->headers->referrer )
                unless defined $repo;
            
            $this->stash( repo => $repo );
        }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

