package Spaghetti::Form::Admin::News::FromTopic;
use Pony::Object qw/Pony::View::Form/;

    use Spaghetti::Form::Decorator;

    has action => '/admin/news/from/topic';
    has method => 'post';
    has id     => 'form-admin-news-from-topic';

    sub create
        {
            my $this = shift;
               $this->decorator = new Spaghetti::Form::Decorator;
            
            $this->addElement
            (
                title => text =>
                {
                    required    => 1,
                    label       => 'Title',
                    validators  => { Length => [4, 64] }
                }
            );
            
            $this->addElement
            (
                url => text =>
                {
                    required    => 1,
                    label       => 'Url',
                    validators  => { Length => [0, 64] }
                }
            );
            
            $this->addElement
            (
                legend => textarea =>
                {
                    required    => 1,
                    label       => 'Legend',
                    validators  => { Length => [10, 140] }
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
            
            $this->addElement( submit => submit => {ignore => 1} );
        }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

