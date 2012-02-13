package Spaghetti::Controller::Item::CreateProject;
use Pony::Object;
    
    use Digest::MD5 'md5_hex';
    use Pony::Crud::MySQL;
    use Pony::Stash;
    
    has call => undef;
    has size => 1;
    has user => undef;
    
    sub init
        {
            my $this = shift;
               $this->user = shift;
               $this->size = shift if @_;
        }
    
    sub run
        {
            my $this  = shift;
            my $topic = Pony::Stash->get('project')->{topic};
            my $owner = $this->user;
            
            # Prepare models.
            #
            
            my $thModel = new Pony::Crud::MySQL('thread');
            my $teModel = new Pony::Crud::MySQL('text');
            my $prModel = new Pony::Crud::MySQL('project');
            
            # Create records in database.
            #
            
            my $thId = $thModel->create
                       ({
                            author   => $owner,
                            owner    => $owner,
                            createAt => time,
                            modifyAt => time,
                            parentId => $topic,
                            topicId  => $topic,
                       });
                       
            my $teId = $teModel->create
                       ({
                            threadId => $thId,
                            text     => '',
                       });
            
            $thModel->update( { textId => $teId },
                              { id     => $thId } );
            
            $prModel->create
            ({
                id      => $thId,
                url     => md5_hex( rand ) . md5_hex( rand ),
                title   => 'Project name',
                repos   => 0,
                maxRepo => $this->size
            });
        }
    
1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

