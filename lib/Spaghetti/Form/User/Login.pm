package Spaghetti::Form::User::Login;
use Pony::Object qw/Pony::View::Form/;
    
    use Spaghetti::Form::Decorator;

    has action => '/user/login';
    has method => 'post';
    has id     => 'form-login';

    sub create
        {
            my $this = shift;
               $this->decorator = new Spaghetti::Form::Decorator;
            
            $this->addElement
            (
                mail => text =>
                {
                    required    => 1,
                    label       => 'E-mail',
                    validators  =>
                    {
                        Like    => qr/[\.\-\w\d]+\@(?:[\.\-\w\d]+\.)+[\w]{2,5}/,
                    }
                }
            );
            
            $this->addElement
            (
                password => password =>
                {
                    required    => 1,
                    label       => 'Password',
                    validators  =>
                    {
                        Length  => [ 8, 32 ],
                    }
                }
            );
            
            $this->addElement( submit => submit => {ignore => 1} );
        }

1;
