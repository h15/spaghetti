package Mojolicious::Plugin::Access;
use Pony::Object 'Mojolicious::Plugin';

    use Pony::Stash;
    use Pony::Crud::MySQL;
    
    has sql => '
                    SELECT `id` FROM `thread` WHERE `id`=%d AND `id` IN
                    (
                        SELECT `threadId` FROM `threadToDataType`
                        WHERE `dataTypeId` IN
                        (
                            SELECT `dataTypeId` FROM `access`
                            WHERE `RWCD` & %d != 0 AND `groupId` IN
                            (
                                SELECT `groupId` FROM `userToGroup`
                                WHERE `userId`=%d
                            )
                        )
                    )
                ';
    
    has const => {
                    r   => 1,
                    w   => 2,
                    c   => 4,
                    d   => 8
                 };
    
    sub register
        {
            my ( $this, $app ) = @_;
            
            $app->helper
            (
                access => sub
                {
                    my ( $self, $tid, $right ) = @_;
                    my $uid = $self->user->{id};
                    
                    my $q = sprintf $this->sql, int($tid),
                                $this->const->{$right}, int($uid);
                    
                    my @t = Pony::Crud::MySQL->new('thread')->raw($q);
                    
                    return 1 if @t;
                    return 1 if grep { $_ == 1 } @{ $self->user->{groups} };
                    return 0;
                }
            );
        }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

