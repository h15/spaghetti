package Pony::Orm;
use Pony::Object;
use Pony::Db;

    has keys    => [];
    has id      => undef;
    has set     => undef;
    has exists  => undef;
    
    /**
     *  Load Pony::Object from database.
     *  Uses loadHash.
     */
    sub load
        {
            my $this = shift;
            my $hash = $this->loadHash(@_);
            
            if ( defined $hash )
            {
                $this->$_ = $hash->{$_} for keys %$hash;
            }
            else
            {
                $this->exists = undef;
            }
        }
    
    /**
     *  Save Pony::Object into database.
     *  Uses saveHash.
     */
    sub save
        {
            my $this = shift;
            my $all  = $this->ALL;
            
            delete $all->{keys};
            delete $all->{set};
            delete $all->{id};
            delete $all->{exists};
            
            my $data = {};
               $data->{$_} = $this->$_ for keys %$all;
            
            my $index = $this->keys->[0];
            my $where = { $index => $this->$index };
            
            $this->saveHash($data, $where);
        }
    
    /**
     *  Delete Pony::Object from database.
     *  Uses delHash.
     */
    sub del
        {
            my $this  = shift;
            my $index = $this->keys->[0];
            my $where = { $index => $this->$index };
            
            $this->delHash($where);
        }
    
    sub raw 
        {
            new Pony::Db
        }

    sub loadHash
        {
            my ( $this, $where ) = @_;
            my $set = $this->set;
            my $db = new Pony::Db;
            
            $db->exists($set, $where) ?
                $db->read($set, $where) : undef;
        }
            
    sub saveHash
        {
            my ( $this, $data, $where ) = @_;
            my $set = $this->set;
            my $db  = new Pony::Db;
            
            if ( $this->exists )
            {
                $db->update( $set => { data  => $data,
                                       where => $where } );
            }
            else
            {
                $this->id = $db->create( $set => $data, $this->keys );
                $this->exists = 1;
            }
        }
            
    sub delHash
        {
            my ( $this, $where ) = @_;
            my $set = $this->set;
            my $db  = new Pony::Db;
            
            $db->delete( $set => $where, $this->keys );
        }
    
    sub findOrCreateHash
        {
            my ( $this, $where ) = @_;
            my ( $keys, $set ) = ( $this->keys, $this->set );
            my $db = new Pony::Db;
            
            $keys ||= [];
            my $key;
            
            # get by keys
            my @e = grep { exists $where->{$_} } @$keys;
            $key = { $e[0] => $where->{$e[0]} } if @e;
            
            # get by id if keys does not defined.
            $key = { id => $where->{id} } if !@e && exists $where->{id};
            
            defined $key && $db->exists($set, $key) ?
                $db->read  ( $set, $key ) :
                $db->create( $set, $where, $keys ) ;
        }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

