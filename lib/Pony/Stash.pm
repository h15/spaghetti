package Pony::Stash;
use Pony::Object 'singleton';

    # "R2D2 where are you?"

    use Storable qw(freeze thaw);
    
    our $VERSION = '0.000002';
    
    has conf => {};
    has file => '';
    
    # Read file and init
    # config by data from file.
    
    sub init
        {
            my $this = shift;
               $this->file = shift;
            
            open F, $this->file or warn 'Can`t open ' . $this->file;
            {
                local $/;
                
                my $conf = <F>;
                
                $this->conf = ( length $conf ? thaw $conf : {} );
            }
            close F;
        }
    
    # " - What's going on... Buddy? 
    #   - You're being put into carbon-freeze. "
    
    sub save
        {
            my $this = shift->new;
            
            open  F, '>', $this->file;
            print F freeze($this->conf);
            close F;
        }
    
    # Find config and return.
    # Create config if not found ... and return result.
    
    sub findOrCreate
        {
            my $this = shift->new;
            my ($name, $conf ) = @_;
            
            $this->set($name => $conf) unless exists $this->conf->{$name};
            
            return $this->get($name);
        }
    
    # Find config by name and return.
    # Return undef, if can't find.
    
    sub get
        {
            my $this = shift->new;
            my ( $name ) = @_;
            
            return $this->conf->{$name} if exists $this->conf->{$name};
            return undef;
        }
    
    # Create or update stash hash
    # into $this->conf.
    
    sub set
        {
            my $this = shift->new;
            my ( $name, $conf ) = @_;
            
            $this->conf->{$name} = $conf;
        }
    
    # Delete element from stash hash.
    #
    
    sub delete
        {
            my $this = shift->new;
            my ( $name ) = @_;
            
            delete $this->conf->{$name};
        }
    
1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
