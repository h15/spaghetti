package Forum::Form::Thread::Create;
use Pony::Object qw/Pony::View::Form/;

    has action => '/thread/create';
    has method => 'post';
    has id     => 'form-thread-create';

    sub create
        {
            my $this = shift;
            
            $this->addElement
            (
                text => textarea =>
                {
                    required    => 1,
                    label       => 'Text',
                }
            );
            
            $this->addElement
            (
                parentId => hidden =>
            );
            
            $this->addElement
            (
                topicId => hidden =>
            );
            
            $this->addElement( submit => submit => {ignore => 1} );
        }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

