package Forum::Form::Admin::Thread::Create;
use Pony::Object qw/Pony::View::Form/;

    has action => '/admin/thread/create';
    has method => 'post';
    has id     => 'form-admin-thread-create';

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
                parentId => text =>
                {
                    required    => 1,
                    label       => 'Parent',
                    validators  =>
                    {
                        Like    => qr/\d+/,
                    }
                }
            );
            
            $this->addElement
            (
                topicId => text =>
                {
                    required    => 1,
                    label       => 'Topic',
                    validators  =>
                    {
                        Like    => qr/\d+/,
                    }
                }
            );
            
            $this->addElement
            (
                textId => text =>
                {
                    required    => 1,
                    label       => 'Text',
                    validators  =>
                    {
                        Like    => qr/\d+/,
                    }
                }
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

