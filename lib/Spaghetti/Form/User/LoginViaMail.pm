package Spaghetti::Form::User::LoginViaMail;
use Pony::Object qw/Pony::View::Form/;

    has action => '/user/login/mail';
    has method => 'post';
    has id     => 'form-login-via-mail';

    sub create
        {
            my $this = shift;
            
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
            
            $this->addElement( submit => submit => {ignore => 1} );
        }

1;
