package Spaghetti::Controller::Admin::User;
use Mojo::Base 'Mojolicious::Controller';

    use Pony::Crud::MySQL;
    
    sub list
        {
            my $this = shift;
            
            # Paginator
            #
            
            my $page = int ( $this->param('page') || 0 );
               $page = 1 if $page < 1;
            
            my $conf  = Pony::Stash->findOrCreate( default => { size => 10 } );
            my @users = Pony::Crud::MySQL->new('user')->list( undef, undef, undef,
                                undef, ($page-1)*$conf->{size}, $conf->{size} );
            my $count = Pony::Crud::MySQL->new('user')->count;
            
            $this->stash( paginator => $this->paginator
                          ('admin_user_list', $page, $count, $conf->{size}) );
            $this->stash( users => \@users );
            $this->render('admin/user/list');
        }
    
    sub show
        {
            my $this = shift;
            my $id   = $this->param('id');
            
            my $user = Pony::Crud::MySQL->new('user')->read({id => $id});
            my @groups = Pony::Crud::MySQL->new('group')->list;
            
            my @g = map { $_->{groupId} }
                      Pony::Crud::MySQL
                        ->new('userToGroup')
                          ->list({userId => $id},['groupId'],'groupId');
            
            $this->stash( user       => $user    );
            $this->stash( groups     => \@groups );
            $this->stash( userGroups => \@g      );
            
            $this->render('admin/user/show');
        }
    
    sub delete
        {
            my $this = shift;
            my $id   = $this->param('id');
            Pony::Crud::MySQL->new('user')->delete({id => $id});
            
            $this->redirect_to('admin_user_delete', id => $id);
        }

    sub addGroup
        {
            my $this    = shift;
            my $id      = int ( $this->param('id')    || 0 );
            my $groupId = int ( $this->param('group') || 0 );
            
            # Smth. wrong
            #
            
            $this->redirect_to('admin_user_list') if $id == 0 || $groupId == 0;
            
            Pony::Crud::MySQL->new('userToGroup')
                             ->create({userId => $id, groupId => $groupId});
            
            $this->redirect_to('admin_user_show', id => $id);
        }
    
    sub removeGroup
        {
            my $this    = shift;
            my $id      = int ( $this->param('id')    || 0 );
            my $groupId = int ( $this->param('group') || 0 );
            
            # Smth. wrong
            #
            
            $this->redirect_to('admin_user_list') if $id == 0 || $groupId == 0;
            
            Pony::Crud::MySQL->new('userToGroup')
                             ->delete({userId => $id, groupId => $groupId});
            
            $this->redirect_to('admin_user_show', id => $id);
        }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

