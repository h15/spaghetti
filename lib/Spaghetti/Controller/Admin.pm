package Spaghetti::Controller::Admin;
use Mojo::Base 'Mojolicious::Controller';
    
    use Pony::Stash;
    use Pony::Model::Crud::MySQL;
    
    our @rights;
    
    sub auth
        {
            my $this = shift;
            
            my $u2g = Pony::Model::Crud::MySQL
                       ->new('userToGroup')
                         ->read({userId => $this->user->{id}, groupId => 1});
            
            return 1 if $u2g;
            return 0;
        }
    
    sub access
        {
            my $this = shift;
            
            unless ( @rights )
            {
                my $rights = Pony::Stash->get('accessFilter');
                
                for my $r ( sort keys %$rights )
                {
                    my ( $k, $v ) = %{ $rights->{$r} };
                    next if $k !~ /^[.0-9*]+$/;
                    
                    $k =~ s/\*/\\d+/g;
                    $k =~ s/\./\\./g;
                    
                    $v = ( $v eq 'allow' ? 1 : 0 );
                    
                    push @rights, {$k => $v};
                }
                
                my ( $allow, $deny ) = @$rights{qw/allow deny/};
            }
            
            my $ip = $this->tx->remote_address;
            
            for my $rule ( @rights )
            {
                my ( $mask, $ret ) = %$rule;
                return $ret if $ip =~ /^$mask$/;
            }
            
            return 0;
        }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

