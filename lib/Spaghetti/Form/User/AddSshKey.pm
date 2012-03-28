package Spaghetti::Form::User::AddSshKey;
use Pony::Object qw/Pony::View::Form/;
    
    use Spaghetti::Form::OneColumnDecorator;

    has action => '/user/ssh';
    has method => 'post';
    has id     => 'form-user-add-ssh-key';
    
    sub create
        {
            my $this = shift;
               $this->decorator = new Spaghetti::Form::OneColumnDecorator;
            
            $this->addElement
            (
                key => textarea =>
                {
                    required    => 1,
                    label       => 'Public key',
                    validators  =>
                    {
                        Length  => [ 0, 400 ],
                    }
                }
            );
            
            $this->addElement( submit => submit => {ignore => 1} );
        }

1;
