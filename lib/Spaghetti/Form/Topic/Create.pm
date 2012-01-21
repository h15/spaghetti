package Spaghetti::Form::Topic::Create;
use Pony::Object qw/Pony::View::Form/;

    use Spaghetti::Form::Decorator;

    has action => '/thread/new/topic';
    has method => 'post';
    has id     => 'form-createTopic';

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
                    validators  =>
                    {
                        Length  => [ 2, 64 ],
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
                parentId => hidden =>
            );
            
            $this->addElement
            (
                topicId => hidden =>
            );
            
            $this->addElement( submit => submit => {ignore => 1} );
        }

1;
