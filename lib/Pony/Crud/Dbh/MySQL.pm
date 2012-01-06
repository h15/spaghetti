package Pony::Crud::Dbh::MySQL;
use Pony::Object 'singleton';
use DBI;

    has dbh => undef;
    
    sub init
        {
            my $this = shift;
            my $auth = shift;
            my $conn = sprintf 'DBI:mysql:database=%s;host=%s',
                                $auth->{dbname}, $auth->{host};
            
            $this->dbh = DBI->connect
                         (
                             $conn,
                             $auth->{user},
                             $auth->{password},
                             {
                                RaiseError => 1,
                                mysql_enable_utf8 => 1
                             }
                         )
                         or die $DBI::errstr;
        }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
