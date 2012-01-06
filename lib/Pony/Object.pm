package Pony::Object;

use feature ':5.10';
use Storable qw/dclone/;
use Module::Load;

our $VERSION = '0.000008';

# "You will never find a more wretched hive of scum and villainy.
#  We must be careful."

sub import
    {
        my $this   = shift;
        my $call   = caller;
        my $isa    = "${call}::ISA";
        my $single = 0;
        
        # Load all base classes.
        #
        
        while ( @_ )
        {
            my $param = shift;
            
            if ( $param eq 'singleton' )
            {
                $single = 1;
                next;
            }
            
            load $param;
            
            push @$isa, $param;
        }
        
        # Pony objects must be strict
        # and modern.
        
        strict  ->import;
        warnings->import;
        feature ->import(':5.10');
        
        # Define special methods.
        #
        
        *{$call.'::has' } = sub { addAttr ($call, @_) };
        *{$call.'::ALL' } = sub { \%{ $call.'::ALL' } };
        *{$call.'::dump'} = sub {
                                    use Data::Dumper;
                                    $Data::Dumper::Indent = 1;
                                    Dumper(@_);
                                };
        *{$call.'::new'} = sub
        {
            # For singletons.
            #
            
            return ${$call.'::instance'} if defined ${$call.'::instance'};

            my $this = shift;

            # properties inheritance
            #
            
            for my $base ( @{ $this.'::ISA'} )
            {
                if ( $base->can('ALL') )
                {
                    my $all = $base->ALL;

                    for my $k ( keys %$all )
                    {
                        unless ( exists ${$call.'::ALL'}{$k} )
                        {
                            %{ $this.'::ALL' } = ( %{ $this.'::ALL' },
                                                   $k => $all->{$k} );
                        } 

                    }

                }
            }
            
            my $obj = dclone { %{${this}.'::ALL'} };
            $this = bless $obj, $this;
            
            ${$call.'::instance'} = $this if $single;
            
            # 'After' for user.
            
            $this->init(@_) if $call->can('init');
            
            return $this;    
        };
    }

sub addAttr
    {
        my ( $this, $attr, $value ) = @_;
        
        # methods
        if ( ref $value eq 'CODE' )
        {
            *{$this."::$attr"} = $value;
            
            return;
        }
        
        %{ $this.'::ALL' } = ( %{ $this.'::ALL' }, $attr => $value );
        
        *{$this."::$attr"} = sub : lvalue
                             {
                                 my $this = shift;
                                    $this->{$attr};
                             }
    }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 - 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
