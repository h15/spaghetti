package Spaghetti::Form::Admin::Project::Create;
use Pony::Object qw/Pony::View::Form/;

    use Spaghetti::Form::Decorator;

    has action => '/admin/project/create';
    has method => 'post';
    has id     => 'form-admin-project-create';

    sub create
        {
            my $this = shift;
               $this->decorator = new Spaghetti::Form::Decorator;
            
            $this->addElement
            (
                title => text =>
                {
                    required    => 1,
                    label       => 'Name',
                    validators  =>
                    {
                        Length    => [ 2, 256 ],
                    }
                }
            );
            
            $this->addElement
            (
                url => text =>
                {
                    required    => 1,
                    label       => 'Url',
                    validators  =>
                    {
                        Length    => [ 2, 128 ],
                    }
                }
            );
            
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
                owner => text =>
                {
                    required    => 1,
                    label       => 'Owner',
                    validators  =>
                    {
                        Like    => qr/\d+/,
                    }
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
            
            $this->addElement( submit => submit => {ignore => 1} );
        }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

