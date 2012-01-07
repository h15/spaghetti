package Forum::Form::Admin::Group::Create;
use Pony::Object qw/Pony::View::Form/;

    has action => '/admin/group/new';
    has method => 'post';
    has id     => 'form-admin-group-create';

    sub create
        {
            my $this = shift;
            
            $this->addElement
            (
                name => text =>
                {
                    required    => 1,
                    label       => 'Name',
                    validators  =>
                    {
                        Length  => [ 1, 64 ],
                    }
                }
            );
            
            $this->addElement
            (
                desc => textarea =>
                {
                    required    => 1,
                    label       => 'Description'
                }
            );
            
            $this->addElement
            (
                prioritet => text =>
                {
                    label       => 'Prioritet',
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

