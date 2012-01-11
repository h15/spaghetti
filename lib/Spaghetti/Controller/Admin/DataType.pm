package Spaghetti::Controller::Admin::DataType;
use Mojo::Base 'Mojolicious::Controller';

    use Spaghetti::Form::Admin::DataType::Create;
    use Pony::Crud::MySQL;
    use Spaghetti::Util;

    sub show
        {
            my $this  = shift;
            my $id    = $this->param('id');
            my $model = new Pony::Crud::MySQL('dataType');
            my $type  = $model->read({id => $id});
            
            $this->stash(type => $type);
            $this->render;
        }
    
    sub list
        {
            my $this  = shift;
            my $model = new Pony::Crud::MySQL('dataType');
            
            my $page = int $this->param('page');
               $page = 1 if $page < 1;
             --$page;
            
            my $conf = Pony::Stash->findOrCreate( default => { size => 50 } );
            
            my @types = $model->list ( undef, undef, undef, undef,
                                        $page * $conf->{size}, $conf->{size} );
            
            $this->stash(types => \@types);
            $this->render;
        }
    
    sub create
        {
            my $this = shift;
            my $form = new Spaghetti::Form::Admin::DataType::Create;
            
            if ( $this->req->method eq 'POST' )
            {
                $form->data->{$_} = $this->param($_) for keys %{$form->elements};
                
                if ( $form->isValid )
                {
                    my $name = $form->elements->{name}->value;
                    my $desc = $form->elements->{desc}->value;
                    my $prio = $form->elements->{prioritet}->value;
                    
                    my $model = new Pony::Crud::MySQL('dataType');
                    my $type  = $model->read({name => $name}, ['id']);
                    
                    if ( $type->{id} > 0 )
                    {
                        $form->elements->{name}->errors
                              = ['Group with the same name is already exist'];
                    }
                    else
                    {
                        my $id = $model->create
                                 ({
                                    name      => $name,
                                    desc      => Spaghetti::Util::escape($desc),
                                    prioritet => $prio
                                 });
                        
                        $this->redirect_to('admin_dataType_show', id => $id);
                    }
                }
            }
            
            $this->stash( form  => $form->render() );
            $this->render;
        }
    
    sub edit
        {
            my $this  = shift;
            my $id    = $this->param('id');
            my $model = new Pony::Crud::MySQL('dataType');
            my $type  = $model->read({id => $id});
            my $form  = new Spaghetti::Form::Admin::DataType::Create;
               $form->action = $this->url_for('admin_dataType_edit');
            
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
                            desc      => Spaghetti::Util::escape($desc),
                            prioritet => $prio
                        },
                        {
                            id => $id
                        }
                    );
                    
                    $this->redirect_to('admin_dataType_show', id => $id);
                }
            }
            
            $form->elements->{$_}->value = $type->{$_} for keys %{$form->elements};
            
            $this->stash( form  => $form->render() );
            $this->stash( type  => $type );
            $this->render;
        }
    
    sub delete
        {
            my $this  = shift;
            my $id    = $this->param('id');
            my $model = new Pony::Crud::MySQL('dataType');
               $model->delete({id => $id});
            
            $this->redirect_to('admin_dataType_list');
        }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

