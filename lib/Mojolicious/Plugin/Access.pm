package Mojolicious::Plugin::Access;
use Pony::Object 'Mojolicious::Plugin';

    use Pony::Stash;
    use Pony::Crud::MySQL;
    
    has sql => '
                    SELECT `id`, t.`owner` FROM `thread` AS t WHERE `id`=%d AND `id` IN
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
                    my $model = Pony::Crud::MySQL->new('thread');
                    
                    $tid = 0 unless defined $tid;
                    
                    # Deny access for anonymous.
                    #
                    
                    return 0 unless $uid;
                    
                    # Allow by database record.
                    #
                    
                    my $q = sprintf $this->sql, int($tid),
                                $this->const->{$right}, int($uid);
                    
                    my @t = $model->raw($q);
                    
                    return 1 if @t;
                    
                    # Allow write action for owner.
                    #
                    my $t = $model->read({id => $tid, owner => $uid}, ['owner']);
                    
                    return 1 if defined $t;
                    
                    return 1 if $right eq 'w' && $uid == $t->{owner};
                    
                    # Allow for admin.
                    #
                    
                    return 1 if grep { $_ == 1 } @{ $self->user->{groups} };
                    
                    # Deny for others.
                    #
                    
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

