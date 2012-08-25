package Spaghetti::Form::User::Registration;
use Pony::Object qw/Pony::View::Form/;

  use Spaghetti::Form::Decorator;

  has action => '/user/registration';
  has method => 'post';
  has id   => 'form-registration';

  sub create
    {
      my $this = shift;
         $this->decorator = new Spaghetti::Form::Decorator;
      
      $this->addElement
      (
        name => text =>
        {
          required  => 1,
          label     => 'Name',
          validators  =>
          {
            Length  => [ 3, 32 ]
          }
        }
      );
      
      $this->addElement
      (
        mail => text =>
        {
          required  => 1,
          label     => 'E-mail',
          validators  =>
          {
            Like  => qr/[\.\-\w\d]+\@(?:[\.\-\w\d]+\.)+[\w]{2,5}/,
          }
        }
      );
      
      $this->addElement
      (
        password => password =>
        {
          required  => 1,
          label     => 'Password',
          validators  =>
          {
            Length  => [ 8, 32 ],
          }
        }
      );
      
      $this->addElement
      (
        show => checkbox =>
        {
          ignore    => 1,
          label     => 'Visible',
          validators  =>
          {
            Length  => [ 3, 32 ]
          }
        }
      );
      
      $this->addElement( submit => submit => {ignore => 1} );
    }

1;
