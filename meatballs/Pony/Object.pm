package Pony::Object;

# "You will never find a more wretched hive of scum and villainy.
#  We must be careful."

use feature ':5.10';
use Storable qw/dclone/;
use Module::Load;
use Carp qw(confess);
use Scalar::Util qw( refaddr );

use constant DEBUG => 0;

BEGIN
    {
        if ( DEBUG )
        {
            say STDERR "\n[!] Pony::Object DEBUGing mode is turning on!\n";
            
            *{dumper} = sub
                {
                    use Data::Dumper;
                    $Data::Dumper::Indent = 1;
                    Dumper(@_);
                }
        }
    }

our $VERSION = 0.04;


# This function will runs on each use of this module.
# It changes caller - adds new keywords,
#   makes caller more strict and modern,
#   create from simple package almost normal class.
# Also it provides some useful methods.
#
# Don't forget: it's still OOP with blessed refs,
# but now it looks better - more sugar for your code.

sub import
    {
        my $this = shift;
        my $call = caller;
        
        # Modify caller just once.
        # We suppose, that only we can create function ALL.
        
        return if defined *{$call.'::ALL'};
        
        # Keywords, base methods, attributes.
        predefine( $call );
        
        # Pony objects must be strict and modern.
        strict  ->import;
        warnings->import;
        feature ->import(':5.10');
        
        # Base classes and params.
        parseParams($call, "${call}::ISA", @_);
        
        methodsInheritance($call);
        propertiesInheritance($call);
        
        *{$call.'::new'} = sub { importNew($call, @_) };
    }


# Constructor for Pony::Objects.
# @param string - caller package.

sub importNew
    {
        my $call = shift;
        
        if ( $call->META->{isAbstract} )
        {
            confess "Trying to use an abstract class $call";
        }
        else
        {
            $call->AFTER_LOAD_CHECK;
        }
        
        # For singletons.
        return ${$call.'::instance'} if defined ${$call.'::instance'};
        
        my $this = shift;
        
        my $obj = dclone { %{${this}.'::ALL'} };
        $this = bless $obj, $this;
        
        ${$call.'::instance'} = $this if $call->META->{isSingleton};
        
        # 'After' for user.
        $this->init(@_) if $call->can('init');
        
        return $this;
    }


# Load all base classes and read class params.
# @param string - caller package.
# @param ArrayRef - ref to @ISA.
# @param array - import params.

sub parseParams
    {
        my ( $call, $isaRef, @params ) = @_;
        
        for my $param ( @params )
        {
            given ( $param )
            {
                # Define singleton class
                # via use param.
                
                when ( /^-?singleton$/ )
                {
                    $call->META->{isSingleton} = 1;
                    next;
                }
                
                # Define abstract class
                # via use param.
                
                when ( /^-?abstract$/ )
                {
                    $call->META->{isAbstract} = 1;
                    next;
                }
            }
            
            load $param;
            $param->AFTER_LOAD_CHECK if $param->can('AFTER_LOAD_CHECK');
            
            push @$isaRef, $param;
        }
    }


# Predefine keywords and base methods.
# @param string - caller package.

sub predefine
    {
        my $call = shift;
        
        # Predefine ALL and META.
        
        %{$call.'::ALL' } = ();
        %{$call.'::META'} = ();
        ${$call.'::META'}{isSingleton} = 0;
        ${$call.'::META'}{isAbstract}  = 0;
        ${$call.'::META'}{abstracts}   = [];
        ${$call.'::META'}{methods}     = {};
        ${$call.'::META'}{symcache}    = {};
        ${$call.'::META'}{checked}     = 0;
        
        #====================
        # Define "keywords".
        #====================
        
        *{$call.'::has'}       = sub { addProperty ($call, @_) };
        *{$call.'::public'}    = sub { addPublic   ($call, @_) };
        *{$call.'::private'}   = sub { addPrivate  ($call, @_) };
        *{$call.'::protected'} = sub { addProtected($call, @_) };
        
        
        #=========================
        # Define special methods.
        #=========================
        
        # Getters for REFs to special variables %ALL and %META.
        
        *{$call.'::ALL'}  = sub { \%{ $call.'::ALL' } };
        *{$call.'::META'} = sub { \%{ $call.'::META'} };
        
        # This method provides deep copy
        # for Pony::Objects
        *{$call.'::clone'}  = sub { dclone shift };
        
        # Convert object's data into hash.
        # Uses ALL() to get properties' list.
        
        *{$call.'::toHash'} = sub
        {
            my $this = shift;
            my %hash = map { $_, $this->{$_} } keys %{ $this->ALL() };
              \%hash;
        };
        
        # Simple Data::Dumper wrapper.
        
        *{$call.'::dump'} = sub {
                                    use Data::Dumper;
                                    $Data::Dumper::Indent = 1;
                                    Dumper(@_);
                                };
        
        *{$call.'::AFTER_LOAD_CHECK'} = sub { checkImplenets($call) };
        
        # Save method's attributes.
        
        *{$call.'::MODIFY_CODE_ATTRIBUTES'} = sub
        {
            my ($pkg, $ref, @attrs) = @_;
            
            my $sym = findsym($call, $pkg, $ref);
            
            $call->META->{methods}->{ *{$sym}{NAME} } =
                {
                    attributes => \@attrs,
                    package => $pkg
                };
            
            for ( @attrs )
            {
                given( $_ )
                {
                    when ('Public'   ) { makePublic   ($call,$pkg,$sym,$ref) }
                    when ('Protected') { makeProtected($call,$pkg,$sym,$ref) }
                    when ('Private'  ) { makePrivate  ($call,$pkg,$sym,$ref) }
                    when ('Abstract' ) { makeAbstract ($call,$pkg,$sym,$ref) }
                }
            }
            
            return;
        };
    }

# Inheritance of methods.
# @param string - caller package.

sub methodsInheritance
    {
        my $this = shift;
        
        for my $base ( @{$this.'::ISA'} )
        {
            # All Pony-like classes.
            if ( $base->can('META') )
            {
                my $methods = $base->META->{methods};
                
                while ( my($k, $v) = each %$methods )
                {
                    $this->META->{methods}->{$k} = $v
                        unless exists $this->META->{methods}->{$k};
                }
                
                # Abstract classes.
                if ( $base->META->{isAbstract} )
                {
                    my $abstracts = $base->META->{abstracts};
                    
                    push @{ $this->META->{abstracts} }, @$abstracts;
                }
            }
        }
    }


# Check for implementing abstract methods
# in our class in non-abstract classes.
# @param string - caller package.

sub checkImplenets
    {
        my $this = shift;
        
        return if $this->META->{checked};
        $this->META->{checked} = 1;
        
        # Check: does all abstract methods implemented.
        for my $base ( @{$this.'::ISA'} )
        {
            
            if ( $base->can('META') && $base->META->{isAbstract} )
            {
                my $methods = $base->META->{abstracts};
                my @bad;
                
                # Find Abstract methods,
                # which was not implements.
                
                for my $method ( @$methods )
                {
                    # Get Abstract methods.
                    push @bad, $method
                      if grep { $_ eq 'Abstract' }
                        @{ $base->META->{methods}->{$method}->{attributes} };
                    
                    # Get abstract methods,
                    # which doesn't implement.
                    @bad = grep { !exists $this->META->{methods}->{$_} } @bad;
                }
                
                if ( @bad )
                {
                    my @messages = map
                        {"Didn't find method ${this}::$_() defined in $base."}
                            @bad;
                    
                    push @messages, "You should implement abstract methods before.\n";
                    
                    confess join("\n", @messages);
                }
            }
            
        }
    }


# Guessing access type of property.
# @param string - caller package.
# @param $attr - name of property.
# @param $value - default value of property.

sub addProperty
    {
        my ( $this, $attr, $value ) = @_;
        
        given( $attr )
        {
            when( /^__/ ) { return addPrivate(@_) }
            when( /^_/  ) { return addProtected(@_) }
            default       { return addPublic(@_) }
        }
    }


# Create public property with accessor.
# Save it in special variable ALL.
# @param string - caller package.
# @param $attr - name of property.
# @param $value - default value of property.

sub addPublic
    {
        my ( $this, $attr, $value ) = @_;
        
        # Save pair (property name => default value)
        %{ $this.'::ALL' } = ( %{ $this.'::ALL' }, $attr => $value );
        
        *{$this."::$attr"} = sub : lvalue { my $this = shift; $this->{$attr} };
    }


# Create protected property with accessor.
# Save it in special variable ALL.
# Can die on wrong access attempt.
# @param string - caller package.
# @param $attr - name of property.
# @param $value - default value of property.

sub addProtected
    {
        my ( $pkg, $attr, $value ) = @_;
        
        # Save pair (property name => default value)
        %{ $pkg.'::ALL' } = ( %{ $pkg.'::ALL' }, $attr => $value );
        
        *{$pkg."::$attr"} = sub : lvalue
        {
            my $this = shift;
            my $call = caller;
            
            confess "Protected ${pkg}::$attr called"
                unless ( $call->isa($pkg) || $pkg->isa($call) )
                    and ( $this->isa($pkg) );
            
            $this->{$attr};
        };
    }


# Create private property with accessor.
# Save it in special variable ALL.
# Can die on wrong access attempt.
# @param string - caller package.
# @param $attr - name of property.
# @param $value - default value of property.

sub addPrivate
    {
        my ( $pkg, $attr, $value ) = @_;
        
        # Save pair (property name => default value)
        %{ $pkg.'::ALL' } = ( %{ $pkg.'::ALL' }, $attr => $value );
        
        *{$pkg."::$attr"} = sub : lvalue
        {
            my $this = shift;
            my $call = caller;
            
            confess "Private ${pkg}::$attr called"
                unless $pkg->isa($call) && ref $this eq $pkg;
            
            $this->{$attr};
        };
    }

# Function's attribute.
# Uses to define, that this code can be used
# only inside this class and his childs.
# @param $pkg - name of package, where this function defined.
# @param $symbol - reference to perl symbol.
# @param $ref - reference to function's code.

sub makeProtected
    {
        my ( $this, $pkg, $symbol, $ref ) = @_;
        my $method = *{$symbol}{NAME};
        
        no warnings 'redefine';
        
        *{$symbol} = sub
        {
            my $this = $_[0];
            my $call = caller;
            
            confess "Protected ${pkg}::$method() called"
                unless ( $call->isa($pkg) || $pkg->isa($call) )
                    and ( $this->isa($pkg) );
            
            goto &$ref;
        }
    }

# Function's attribute.
# Uses to define, that this code can be used
# only inside this class. NOT for his childs.
# @param string $this - package where Pony::Object were used.
# @param string $pkg - name of package, where this function defined.
# @param ref $symbol - reference to perl symbol.
# @param coderef $ref - reference to function's code.

sub makePrivate
    {
        my ( $this, $pkg, $symbol, $ref ) = @_;
        my $method = *{$symbol}{NAME};
        
        no warnings 'redefine';
        
        *{$symbol} = sub
        {
            my $this = $_[0];
            my $call = caller;
            
            confess "Private ${pkg}::$method() called"
                unless $pkg->isa($call) && ref $this eq $pkg;
            
            goto &$ref;
        }
    }


# Function's attribute.
# Uses to define, that this code can be used public.
# @param string $this - package where Pony::Object were used.
# @param string $pkg - name of package, where this function defined.
# @param ref $symbol - reference to perl symbol.
# @param coderef ref - reference to function's code.

sub makePublic
    {
        my ( $this, $pkg, $symbol, $ref ) = @_;
        my $method = *{$symbol}{NAME};
        
        no warnings 'redefine';
        
        *{$symbol} = sub
        {
            ${$pkg.'::this'} = $_[0];
            my $call = caller;
            
            goto &$ref;
        }
    }


# Function's attribute.
# Define abstract attribute.
# It means, that it doesn't conteins realisation,
# but none abstract class, which will extends it,
# MUST implement it.
#
# @param string $this - package where Pony::Object were used.
# @param string $pkg - name of package, where this function defined.
# @param ref $symbol - reference to perl symbol.
# @param coderef $ref - reference to function's code.

sub makeAbstract
    {
        my ( $this, $pkg, $symbol, $ref ) = @_;
        my $method = *{$symbol}{NAME};
        
        # Can't define abstract method
        # in none-abstract class.
        
        confess "Abstract ${pkg}::$method() defined in non-abstract class"
            unless $this->META->{isAbstract};
        
        # Push abstract method
        # into object meta.
        push @{ $this->META->{abstracts} }, $method;
        
        # Can't call abstract method.
        #
        
        no warnings 'redefine';
        
        *{$symbol} = sub
        {
            confess "Abstract ${pkg}::$method() called";
        }
    }


# This function calls when we need to get
# properties (with thier default values)
# form classes which our class extends to our class.
# @param string - caller package.

sub propertiesInheritance
    {
        my $this = shift;
        my %classes;
        my @classes = @{ $this.'::ISA' };
        my @base;
        
        # Get all parent's properties
        while ( @classes )
        {
            my $c = pop @classes;
            next if exists $classes{$c};
            
            %classes = (%classes, $c => 1);
            
            push @base, $c;
            push @classes, @{ $c.'::ISA' };
        }
        
        for my $base ( reverse @base )
        {
            if ( $base->can('ALL') )
            {
                my $all = $base->ALL();
                
                for my $k ( keys %$all )
                {
                    unless ( exists ${$this.'::ALL'}{$k} )
                    {
                        %{ $this.'::ALL' } = ( %{ $this.'::ALL' },
                                               $k => $all->{$k} );
                    }
                }
            }
        }
    }


# Get perl symbol by ref.
# @param string - caller package.
# @param string - package, where it defines.
# @param coderef - reference to method.

sub findsym
    {
        my ( $this, $pkg, $ref ) = @_;
        my $symcache = $this->META->{symcache};
        
        return $symcache->{$pkg, $ref} if $symcache->{$pkg, $ref};
        
        my $type = 'CODE';
        
        for my $sym ( values %{$pkg."::"} )
        {
            next unless ref ( \$sym ) eq 'GLOB';
            
            return $symcache->{$pkg, $ref} = \$sym
                if *{$sym}{$type} && *{$sym}{$type} == $ref;
        }
    }

1;

__END__

=head1 NAME

Pony::Object the object system.

=head1 OVERVIEW

Pony::Object is an object system, which provides simple way to use cute objects.

=head1 SYNOPSIS

    use Pony::Object;

=head1 DESCRIPTION

When some package uses Pony::Object, it's becomes strict (and shows warnings)
and modern (can use perl 5.10 features like as C<say>). Also C<dump> function
is redefined and shows data structure. It's useful for debugging.

=head2 Specific moments

Besides new function C<dump> Pony::Object has other specific moments.

=head3 has

Keyword C<has> declares new fields.
All fields are public. You can also describe object methods via C<has>...
If you want.

    package News;
    use Pony::Object;
    
        # Fields
        has 'title';
        has text => '';
        has authors => [ qw/Alice Bob/ ];
        
        # Methods
        sub printTitle
            {
                my $this = shift;
                say $this->title;
            }

        sub printAuthors
            {
                my $this = shift;
                print @{ $this->authors };
            }
    1;

    package main;
    
    my $news = new News;
    $news->printAuthors();
    $news->title = 'Something important';
    $news->printTitle();

Pony::Object fields assigned via "=". For example: $obj->field = 'a'.

=head3 new

Pony::Object doesn't have method C<new>. In fact, of course it has. But C<new> is an
internal function, so you should not use it if you want not have additional fun.
Instead of this Pony::Object has C<init> function, where you can write the same,
what you wish write in C<new>. C<init> is after-hook for C<new>.

    package News;
    use Pony::Object;
    
        has title => undef;
        has lower => undef;
        
        sub init
            {
                my $this = shift;
                $this->title = shift;
                $this->lower = lc $this->title;
            }
    1;

    package main;
    
    my $news = new News('Big Event!');
    
    print $news->lower;

=head3 ALL

If you wanna get all default values of Pony::Object-based class
(fields, of course), you can call C<ALL> method. I don't know why you need them,
but you can do it.

    package News;
    use Pony::Object;
    
        has 'title';
        has text => '';
        has authors => [ qw/Alice Bob/ ];
        
    1;

    package main;
    
    my $news = new News;
    
    print for keys %{ $news->ALL() };

=head3 META

One more internal method. It provides access to special hash C<%META>.
You can use it for Pony::Object introspection but do not trust it. It can be
changed in next versions.

    my $news = new News;
    say dump $news->META;

=head3 toHash

Get object's data structure and return it in hash.

    package News;
    use Pony::Object;
    
        has title => 'World';
        has text => 'Hello';
        
    1;

    package main;
    
    my $news = new News;
    print $news->toHash()->{text};
    print $news->toHash()->{title};

=head3 dump

Return string which shows object current struct.

    package News;
    use Pony::Object;
    
        has title => 'World';
        has text => 'Hello';
        
    1;

    package main;
    
    my $news = new News;
    $news->text = 'Hi';
    print $news->dump();

Returns

    $VAR1 = bless( {
      'text' => 'Hi',
      'title' => 'World'
    }, 'News' );

=head3 protected, private properties

For properties you can use C<has> keyword if your variable starts with _ (for
protected) or __ (for private).

    package News;
    use Pony::Object;
    
        has text => '';
        has __authors => [ qw/Alice Bob/ ];
        
        sub getAuthorString
            {
                my $this = shift;
                return join(' ', @{ $this->__authors });
            }
        
    1;

    package main;
    
    my $news = new News;
    say $news->getAuthorString();

Or the same but with keywords C<public>, C<protected> and C<private>.

    package News;
    use Pony::Object;
    
        public text => '';
        private authors => [ qw/Alice Bob/ ];
        
        sub getAuthorString
            {
                my $this = shift;
                return join(' ', @{ $this->authors });
            }
        
    1;

    package main;
    
    my $news = new News;
    say $news->getAuthorString();

=head3 protected, private method

To define access for methods you can use attributes C<Public>, C<Private> and
C<Protected>.

    package News;
    use Pony::Object;
    
        public text => '';
        private authors => [ qw/Alice Bob/ ];
        
        sub getAuthorString : Public
            {
                return shift->joinAuthors(', ');
            }
        
        sub joinAuthors : Private
            {
                my $this = shift;
                my $delim = shift;
                
                return join( $delim, @{ $this->authors } );
            }
    1;

    package main;
    
    my $news = new News;
    say $news->getAuthorString();

=head3 Inheritance

To define base classes you should set them as params on Pony::Object use.
For example, use Pony::Object 'Base::Class';

    package FirstPonyClass;
    use Pony::Object;
    
        # properties
        has a => 'a';
        has d => 'd';
        
        # method
        has b => sub
            {
                my $this = shift;
                   $this->a = 'b';
                   
                return ( @_ ?
                            shift:
                            'b'  );
            };
        
        # traditional perl method
        sub c { 'c' }
    
    1;

    package SecondPonyClass;
    # extends FirstPonyClass
    use Pony::Object qw/FirstPonyClass/;
    
        # Redefine property.
        has d => 'dd';
        
        # Redefine method.
        has b => sub
            {
                my $this = shift;
                   $this->a = 'bb';
                   
                return ( @_ ?
                            shift:
                            'bb'  );
            };
        
        # New method.
        has e => sub {'e'};
    
    1;

=head3 Singletons

For singletons Pony::Object has simple syntax. You just should declare that
on use Pony::Object;

    package Notes;
    use Pony::Object 'singleton';
    
        has list => [];
        
        sub add
            {
                my $this = shift;
                push @{ $this->list }, @_;
            }
        
        sub flush
            {
                my $this = shift;
                $this->list = [];
            }
    
    1;

    package main;
    use Notes;
    
    my $n1 = new Notes;
    my $n2 = new Notes;
    
    $n1->add( qw/eat sleep/ );
    $n1->add( 'Meet with Mary at 8 o`clock' );
    
    $n2->flush;
    
    # Em... When I must meet Mary? 

=head3 Abstract methods and classes

You can use use abstract methods and classes in the following way:

    # Let's define simple interface for texts.
    package Text::Interface;
    use Pony::Object -abstract; # Use 'abstract' or '-abstract'
                                # params to define abstract class.
    
        sub getText : Abstract; # Use 'Abstract' attribute to
        sub setText : Abstract; # define abstract method.
    
    1;

    # Now we can define base class for texts.
    # It's abstract too but now it has some code.
    package Text::Base;
    use Pony::Object abstract => 'Text::Interface';
    
        protected text => '';
        
        sub getText : Public
            {
                my $this = shift;
                return $this->text;
            }
    
    1;

    # And in the end we can write Text class.
    package Text;
    use Pony::Object 'Text::Base';
    
        sub setText : Public
            {
                my $this = shift;
                $this->text = shift;
            }
    
    1;

    # Main file.
    package main;
    use Text;
    use Text::Base;
    
    my $text = new Text::Base;  # Raises an error!
    
    my $text = new Text;
    $text->setText('some text');
    print $text->getText();     # Returns 'some text';

Don't forget, that perl looking for function from left to right in list of
inheritance packages. You should define abstract classes in the end of
Pony::Object param list.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 - 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
