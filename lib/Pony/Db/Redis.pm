package Pony::Db::Redis;
use Pony::Object;
use Redis;

    our $VERSION = '0.000003';

    has redis  => undef;
    has prefix => undef;

    sub init
        {
            my $this = shift;
            my $opts = shift;
            my $serv = $opts->{server};
            
            $this->prefix = $opts->{prefix};
            $this->redis  = new Redis(%$serv);
            
            return $this;
        }

    sub create
        {
            my ( $this, $set, $data, $keys ) = @_;
            my $px = $this->prefix;
            
            $keys ||= [];
            
            # Check data by keys' mapping.
            for my $k ( @$keys )
            {
                my $val = $data->{$k};
                
                my $v = $this->redis->get("$px.$set.${k}2id.$val");
                
                return undef if defined $v && $v > 0;
            }
            
            # Get new id
            my $id = $this->redis->incr("$px.$set.id");
            
            # Create mapping
            for my $k ( @$keys )
            {
                my $val = $data->{$k};
                $this->redis->set("$px.$set.${k}2id.$val" => $id);
            }
            
            # Save hash
            $this->redis->hmset("$px.$set.$id", %$data);
            
            return $id;
        }



    sub read
        {
            my ( $this, $set, $data ) = @_;
            my $px   = $this->prefix;
            my $id   = $this->_getId($set, %$data);
            my %data = $this->redis->hgetall("$px.$set.$id");
               %data = ( %data, id => $id );
            
            return \%data;
        }

    sub update
        {
            my ( $this, $set, $data ) = @_;
            my $px    = $this->prefix;
            my $where = $data->{where};
               $data  = $data->{data};
            
            my $id = $this->_getId($set, %$where);
            
            $this->redis->hmset("$px.$set.$id", %$data);
        }

    sub delete
        {
            my ( $this, $set, $data, $keys ) = @_;
            my $px = $this->prefix;
            my $id = $this->_getId($set, %$data);
            
            my %record = $this->read( $set, $data );
            
            $keys ||= [];
            
            if ( %record )
            {
                for my $k ( @$keys )
                {
                    my $v = $record{$k};
                    $this->redis->del("$px.$set.${k}2id.$v" => $id) if $v;
                }
            }
            
            $this->redis->del("$px.$set.$id");
        }

    sub list
        {
            my ( $this, $set, $data ) = @_;
            my @ret;
            
            push @ret, $this->read($set, [id => $_]) for @$data;
        }

    sub count
        {
            my ( $this, $set ) = @_;
            my $px = $this->prefix;
            
            $this->redis->hlen("$px.$set");
        }

    sub raw
        {
            shift->redis;
        }

    sub save
        {
            shift->redis->save;
        }

    sub exists
        {
            my ( $this, $set, $where ) = @_;
            my $px = $this->prefix;
            my $id = $this->_getId($set, %$where);
            
            return $this->redis->exists("$px.$set.$id");
        }
        
    sub _getId
        {
            my ( $this, $set, $key, $val ) = @_;
            return $val if $key eq 'id';
            
            my $px = $this->prefix;
            return $this->redis->get("$px.$set.${key}2id.$val");
        }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

