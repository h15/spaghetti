package Spaghetti::Controller::Item;
use Mojo::Base 'Mojolicious::Controller';
    
    use Spaghetti::Util;
    use Pony::Model::Dbh::MySQL;
    use Pony::Model::Crud::MySQL;
    use Pony::Stash;
    use Module::Load;
    
    sub giveByArchon
        {
            my $this = shift;
            
            # Allow Archons.
            # Deny All.
            
            $this->stop(401) unless grep { $_ eq 2 } @{ $this->user->{groups} };
            
            if ( $this->req->method eq 'POST' )
            {
                my $itemId = int $this->param('item');
                my $userId = int $this->param('user');
                
                Pony::Model::Crud::MySQL->new('userToItem')->create
                ({
                    itemId => $itemId,
                    userId => $userId
                });
            }
            
            return $this->redirect_to( $this->req->headers->referrer );
        }

    sub activate
        {
            my $this = shift;
            
            $this->stop(401) unless $this->user->{id} > 0 && $this->user->{banId} == 0;
            
            if ( $this->req->method eq 'POST' )
            {
                my $itemId = int $this->param('item');
                my $userId = $this->user->{id};
                
                my $item = Pony::Model::Crud::MySQL->new('userToItem')
                             ->read({itemId => $itemId, userId => $userId});
                
                # Item with $userId and $itemId does not exist.
                # Get out here!
                
                $this->stop(400) unless $item;
                
                # Get item.
                #
                
                my $itemObj = Pony::Model::Crud::MySQL->new('item')
                                ->read({ id => $item->{itemId} });
                
                # Does that item can do smth?
                #
                
                if ( $itemObj->{effect} )
                {
                    my $class = __PACKAGE__ . '::' . $itemObj->{effect};
                    
                    # Apply item effect.
                    #
                    
                    load $class;
                         $class->new( $this->user->{id}, split ';', $itemObj->{param} )
                               ->run;
                    
                    # Item disappears in the smoke...
                    #
                    
                    Pony::Model::Crud::MySQL->new('userToItem')
                      ->delete({ id => $item->{id} });
                }
            }
            
            return $this->redirect_to( $this->req->headers->referrer );
        }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

