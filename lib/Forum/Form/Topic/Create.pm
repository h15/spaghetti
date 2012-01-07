package Forum::Form::Topic::Create;
use Pony::Object qw/Pony::View::Form/;

    has action => '/forum/new/topic';
    has method => 'post';
    has id     => 'form-createTopic';

    sub create
        {
            my $this = shift;
            
            $this->addElement
            (
                title => text =>
                {
                    required    => 1,
                    label       => 'Title',
                    validators  =>
                    {
                        Length  => [ 2, 100 ],
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
