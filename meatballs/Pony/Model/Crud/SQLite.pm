package Pony::Model::Crud::SQLite;
use Pony::Object 'Pony::Model::Crud::Interface';
use Pony::Model::Dbh::SQLite;

    has table => undef;

    sub init
        {
            my $this = shift;
               $this->table = shift;
        }
    
    # CRUD+LC methods.
    #
    
    # Params : {data}.
    # Returns: id of new record.
    sub create
        {
            my $this = shift;
            my $data = shift;
            my $dbh  = Pony::Model::Dbh::SQLite->new->dbh;
            
            while ( my ( $k, $v ) = each %$data )
            {
                $data->{$k} = $dbh->quote($v);
            }
            
            my $t = $this->table;
            my $k = join '`,`', keys %$data;
            my $v = join ",", values %$data;
            
            $dbh->do ( "INSERT INTO `$t`(`$k`) VALUES($v)" );
            
            my $sth = $dbh->prepare("SELECT last_insert_rowid()");
               $sth->execute();
            
            my $row = $sth->fetchrow_hashref();
            
            return $row->{'last_insert_rowid()'};
        }

    # Params : {where}(?), [fields](?).
    # Returns: hash.
    sub read
        {
            my $this = shift;
            my ( $w, $f ) = @_;
            
            # If where param is not hash.
            ( $w, $f ) = ( {$w, $f}, undef ) if ref $w ne 'HASH';
            
            # ORDER BY first where param.
            my ( $order ) = keys %$w;
            
            [ $this->list( $w, $f, $order, undef, 0, 1 ) ]->[0];
        }

    # Params : {data}, {where}.
    # Returns: true || false.
    sub update
        {
            my $this = shift;
            my ( $data, $where ) = @_;
            my $dbh  = Pony::Model::Dbh::SQLite->new->dbh;
            
            # Prepare
            #
            
            my @where = $this->_prepare($where);
            my @data  = $this->_prepare($data );
            
            # Prepare request.
            #
            
            my $t = $this->table;
            my $w = join ' and ', @where;
            my $d = join ',', @data;
            
            $dbh->do ( "UPDATE `$t` SET $d WHERE $w" );
        }

    # Params : {where}.
    # Returns: true || false.
    sub delete
        {
            my $this  = shift;
            my $where = shift;
            my $dbh   = Pony::Model::Dbh::SQLite->new->dbh;
            
            # Prepare WHERE condition.
            #
            
            my @where = $this->_prepare($where);
            
            # Prepare request.
            #
            
            my $t = $this->table;
            my $w = join ' and ', @where;
            
            $dbh->do ( "DELETE FROM `$t` WHERE $w" );
        }
    
    # Params : {where}(?), [fields](?), order(?), rule(?), offset(?), limit(?).
    # Returns: array of hashes.
    sub list
        {
            my $this  = shift;
            my ( $where, $fields, $order, $rule, $offset, $limit ) = @_;
            my $dbh  = Pony::Model::Dbh::SQLite->new->dbh;
            
            # Define default values
            #
            
            @$fields = map { "`$_`" } @$fields if $fields;
            
            $fields ||= ['*'];
            $order  ||= 'id';
            $rule   ||= 'DESC';
            $offset ||= 0;
            $limit  ||= 20;
            
            # Prepare
            #
            
            my $w = ( $where ? join ' and ', $this->_prepare($where) : '1=1' );
            my $t = $this->table;
            my $f = join ',', @$fields;
            my $q = "SELECT $f FROM `$t` WHERE $w
                     ORDER BY $order $rule LIMIT $offset, $limit";
            
            # Run request and return result.
            #
            
            my $sth = $dbh->prepare($q);
               $sth->execute();
            
            my @result;
            my $row;
            
            push @result, $row while $row = $sth->fetchrow_hashref();
            
            return @result;
        }
    
    # Params : {where}(?).
    # Returns: integer.
    sub count
        {
            my $this  = shift;
            my ( $where ) = @_;
            my $dbh  = Pony::Model::Dbh::SQLite->new->dbh;
            
            # Prepare
            #
            
            my $w = ( $where ? join ' and ', $this->_prepare($where) : '1=1' );
            my $t = $this->table;
            my $q = "SELECT COUNT(*) FROM `$t` WHERE $w";
            
            # Run request and return result.
            #
            
            my $sth = $dbh->prepare($q);
               $sth->execute();
            
            my $row = $sth->fetchrow_hashref();
            
            return $row->{'COUNT(*)'};
        }
        
    sub raw
        {
            my $this  = shift;
            my $query = shift;
            my $dbh   = Pony::Model::Dbh::SQLite->new->dbh;
            
            # Run request and return result.
            #
            
            my $sth = $dbh->prepare($query);
               $sth->execute();
            
            my @result;
            my $row;
            
            push @result, $row while $row = $sth->fetchrow_hashref();
            
            return @result;
        }
        
    sub _prepare
        {
            my $this = shift;
            my $data = shift;
            my $dbh  = Pony::Model::Dbh::SQLite->new->dbh;
            my @data;
            
            while ( my ( $k, $v ) = each %$data )
            {
                push @data, sprintf "`%s`=%s", $k, $dbh->quote($v);
            }
            
            return @data;
        }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
