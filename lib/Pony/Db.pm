package Pony::Db;
use Pony::Object 'singleton';
    
    has driver => undef;
    
    sub init
        {
            my ( $this, $driver, $options ) = @_;
            
            $options ||= {};
            
            $driver = "Pony::Db::$driver";
            
            eval "use $driver";
            die "[-] Can't load driver $driver.\n$@\n" if $@;
            
            $this->driver = $driver->new($options);
        }
    
    sub create
        {
            my ( $this, @params ) = @_;
            
            $this->driver->can('create') ?
                $this->driver->create(@params) :
                die "Can't find method 'create' in " . $this->driver;
        }
    
    sub read
        {
            my ( $this, @params ) = @_;
            
            $this->driver->can('read') ?
                $this->driver->read(@params) :
                die "Can't find method 'read' in " . $this->driver;
        }
    
    sub update
        {
            my ( $this, @params ) = @_;
            
            $this->driver->can('update') ?
                $this->driver->update(@params) :
                die "Can't find method 'update' in " . $this->driver;
        }
    
    sub delete
        {
            my ( $this, @params ) = @_;
            
            $this->driver->can('delete') ?
                $this->driver->delete(@params) :
                die "Can't find method 'delete' in " . $this->driver;
        }
    
    sub list
        {
            my ( $this, @params ) = @_;
            
            $this->driver->can('list') ?
                $this->driver->list(@params) :
                die "Can't find method 'list' in " . $this->driver;
        }
    
    sub count
        {
            my ( $this, @params ) = @_;
            
            $this->driver->can('count') ?
                $this->driver->count(@params) :
                die "Can't find method 'count' in " . $this->driver;
        }
    
    sub raw
        {
            my ( $this, @params ) = @_;
            
            $this->driver->can('raw') ?
                $this->driver->raw(@params) :
                die "Can't find method 'raw' in " . $this->driver;
        }
    
    sub exists
        {
            my ( $this, @params ) = @_;
            
            $this->driver->can('exists') ?
                $this->driver->exists(@params) :
                die "Can't find method 'exists' in " . $this->driver;
        }

1;

__END__

=head1 OVERVIEW

Database interface.

=head2 Methods

All methods can return string, hash and array.

=over

=item create

Create database record. Returning id (or some thing like id) of new record.

=item read

Read data from database by anonymous hash. 

=item update

Update data. Use 2 anonymous hashes: one for new data, one for searching.

=item delete

Delete a record from database.

=item list

Works like read, but returns many records.

=item count

How much records can get by this request.

=back

=head2 Params

Array of params.

=over

=item set

Set of records, like a table in SQL database.

=item type

Type of output. Can be hash, array and string.

=item data

Data for request. For create it will be hash like that:

    {
        'firstName'  => 'Gosha',
        'lastName'   => 'Bugov',
        'web'        => 'http://lorcode.org',
        'password'   => md5_hex('secret')
    }

For update it can be

    {
        data  => { password => md5_hex('new secret') },
        where => { id       => 123 }
    }

=back

=head1 EXAMPLE

    # Create database handler
    my $db = new Pony::Db( Pony::Db::Redis =>
                            { server => '192.168.0.1:6379' } );
    
    # Get hash from DB
    my $hashref = $db->read( User => hash => { id => 831105 } );
    
    # Init user by data from DB
    my $user = new Pony::User($hashref);

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

