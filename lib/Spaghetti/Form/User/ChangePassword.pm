package Spaghetti::Form::User::ChangePassword;
use Pony::Object qw/Pony::View::Form/;

    use Spaghetti::Form::Decorator;

    has action => '/user/change/password';
    has method => 'post';
    has id     => 'form-user-change-password';

    sub create
        {
            my $this = shift;
               $this->decorator = new Spaghetti::Form::Decorator;
            
            $this->addElement
            (
                oldPassword => password =>
                {
                    required    => 1,
                    label       => 'Old password',
                    validators  =>
                    {
                        Length  => [ 8, 32 ],
                    }
                }
            );
            
            $this->addElement
            (
                newPassword => password =>
                {
                    required    => 1,
                    label       => 'New password',
                    validators  =>
                    {
                        Length  => [ 8, 32 ],
                    }
                }
            );
            
            $this->addElement( submit => submit => {ignore => 1} );
        }

1;
