
# Class: Thread::Object
# | Spaghetti's meatball.
# | Defines thread model and some actions.
# Uses:
#   Pony::Model::ActiveRecord::MySQL

package Thread::Object;
use Pony::Object qw/Pony::Model::ActiveRecord::MySQL/;

  protected _id => undef;
  protected _model => undef;
  protected _table => 'user';
  protected _storable => [qw/mail password name createAt modifyAt accessAt
                            banId banTime attempts threadId sshKeyCount/];

1;
