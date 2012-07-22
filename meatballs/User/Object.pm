
# Class: User::Object
# | Spaghetti's meatball.
# | Defines user model and some actions.
# Uses:
#   Pony::Model::ActiveRecord::MySQL

package User::Object;
use Pony::Object qw/Pony::Model::ActiveRecord::MySQL/;
use Digest::MD5 "md5_hex";

  protected _id => undef;
  protected _model => undef;
  protected _table => 'user';
  protected _storable => [qw/mail password name createAt modifyAt accessAt
                            banId banTime attempts sshKeyCount/];
  
  sub init : Public
    {
      my $this = shift;
      
      $this->SUPER::init($this);
    }
  
  sub setPassword : Public
    {
      my $this = shift;
      $this->password = md5_hex( $this->mail . $this->password );
    }
  
1;
