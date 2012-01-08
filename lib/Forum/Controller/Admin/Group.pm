package Forum::Controller::Admin::Group;
use Mojo::Base 'Mojolicious::Controller';

    use Forum::Form::Admin::Group::Create;
    use Pony::Crud::MySQL;
    use Forum::Util;

    sub show
        {
            my $this  = shift;
            my $id    = $this->param('id');
            my $model = new Pony::Crud::MySQL('group');
            my $group = $model->read({id => $id});
            
            # Get types
            #
            
            my @types = Pony::Crud::MySQL->new('dataType')->list;
            my @access= Pony::Crud::MySQL
                          ->new('access')
                            ->list({groupId => $id},undef,'dataTypeId');
                            
            $this->stash(access => \@access);
            $this->stash(types  => \@types);
            $this->stash(group  => $group);
            $this->render;
        }
    
    sub list
        {
            my $this  = shift;
            my $model = new Pony::Crud::MySQL('group');
            
            my $page = int $this->param('page');
               $page = 1 if $page < 1;
             --$page;
            
            my $conf = Pony::Stash->findOrCreate( default => { size => 50 } );
            
            my @groups = $model->list ( undef, undef, undef, undef,
                                        $page * $conf->{size}, $conf->{size} );
            
            $this->stash(groups => \@groups);
            $this->render;
        }
    
    sub create
        {
            my $this = shift;
            my $form = new Forum::Form::Admin::Group::Create;
            
            if ( $this->req->method eq 'POST' )
            {
                $form->data->{$_} = $this->param($_) for keys %{$form->elements};
                
                if ( $form->isValid )
                {
                    my $name = $form->elements->{name}->value;
                    my $desc = $form->elements->{desc}->value;
                    my $prio = $form->elements->{prioritet}->value;
                    
                    my $model = new Pony::Crud::MySQL('group');
                    my $group = $model->read({name => $name}, ['id']);
                    
                    if ( $group->{id} > 0 )
                    {
                        $form->elements->{name}->errors
                              = ['Group with the same name is already exist'];
                    }
                    else
                    {
                        my $id = $model->create
                                 ({
                                    name      => $name,
                                    desc      => Forum::Util::escape($desc),
                                    prioritet => $prio
                                 });
                        
                        $this->redirect_to('admin_group_show', id => $id);
                    }
                }
            }
            
            $this->stash( form => $form->render() );
            $this->render;
        }
    
    sub edit
        {
            my $this  = shift;
            my $id    = $this->param('id');
            my $model = new Pony::Crud::MySQL('group');
            my $group = $model->read({id => $id});
            my $form  = new Forum::Form::Admin::Group::Create;
               $form->action = $this->url_for('admin_group_edit');
            
            if ( $this->req->method eq 'POST' )
            {
                $form->data->{$_} = $this->param($_) for keys %{$form->elements};
                
                if ( $form->isValid )
                {
                    my $name = $form->elements->{name}->value;
                    my $desc = $form->elements->{desc}->value;
                    my $prio = $form->elements->{prioritet}->value;
                    
                    $model->update
                    (
                        {
                            name      => $name,
                            desc      => Forum::Util::escape($desc),
                            prioritet => $prio
                        },
                        {
                            id => $id
                        }
                    );
                    
                    $this->redirect_to('admin_group_show', id => $id);
                }
            }
            
            $form->elements->{$_}->value = $group->{$_} for keys %{$form->elements};
            
            $this->stash( form  => $form->render() );
            $this->stash( group => $group );
            $this->render;
        }
    
    sub delete
        {
            my $this  = shift;
            my $id    = $this->param('id');
            my $model = new Pony::Crud::MySQL('group');
               $model->delete({id => $id});
            
            $this->redirect_to('admin_group_list');
        }

    sub access
        {
            my $this  = shift;
            my $group = $this->param('group');
            my $type  = $this->param('type');
            my $rwcd  = 0;
            
            $rwcd += 1 if defined $this->param('read');
            $rwcd += 2 if defined $this->param('write');
            $rwcd += 4 if defined $this->param('create');
            $rwcd += 8 if defined $this->param('delete');
            
            my $a = Pony::Crud::MySQL->new('access')
                      ->list({ dataTypeId => $type, groupId => $group },
                                    ['RWCD'], 'dataTypeId', undef, 0, 1 );
            
            if ( $a )
            {
                Pony::Crud::MySQL->new('access')->update
                ({ RWCD => $rwcd }, { dataTypeId => $type, groupId => $group });
            }
            else
            {
                Pony::Crud::MySQL->new('access')->create
                ({ RWCD => $rwcd, dataTypeId => $type, groupId => $group });
            }
            
            $this->redirect_to('admin_group_show', id => $group);
        }
1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

