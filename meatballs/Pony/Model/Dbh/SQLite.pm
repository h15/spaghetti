package Pony::Model::Dbh::SQLite;
use Pony::Object 'singleton';
use DBI;

    has dbh => undef;
    
    sub init
        {
            my $this = shift;
            my $file = shift;
            
            $this->dbh = DBI->connect
                         (
                             "dbi:SQLite:dbname=$file",
                             '', '',
                             { RaiseError => 1 }
                         )
                         or die $DBI::errstr;
        }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
