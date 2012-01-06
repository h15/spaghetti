package Pony::Orm::Redis;
use Pony::Object;
use Pony::Db;
    
    has redis => undef;
    
    sub init
        {
            shift->redis = new Pony::Db;
        }
    
    # Object:
    #   id   - string px.set.lastId
    #   keys - list px.set.keys
    #   keys:
    #       name - string px.set.name2id
    #       mail - string px.set.mail2id
    #   data - hash
    
    sub find
        {
            my ( $this, $where ) = @_;
            
            $this->redis->exists($where) ?
                 $this->redis->read($where) : undef ;
        }
        
    sub create
        {
            my ( $this, $where, $keys ) = @_;
            
            # check and create
            if ( defined $keys )
            {
                my $key = $keys->[0];
                
                return undef if
                    $this->redis->exists({ $key => $where->{$key} });
                
                return $this->redis->create( $where, $keys );
            }
            
            # create without check
            else
            {
                return $this->redis->create($where);
            }
        }
        
    sub save
        {
            my ( $this, $data, $where ) = @_;
            
            return $this->redis->update( $data, $where );
        }
    
    sub delete
        {
            
        }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
