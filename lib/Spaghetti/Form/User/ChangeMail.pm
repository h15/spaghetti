package Spaghetti::Form::User::ChangeMail;
use Pony::Object qw/Pony::View::Form/;

    has action => '/user/change/mail';
    has method => 'post';
    has id     => 'form-user-change-mail';

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
