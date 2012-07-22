
# Class: Thread::Object
# | Spaghetti's meatball.
# | Defines thread model and some actions.
# Uses:
#   Pony::Model::ActiveRecord::MySQL

package Thread::Object;
use Pony::Object qw/Pony::Model::ActiveRecord::MySQL/;

  protected _id => undef;
  protected _model => undef;
  protected _table => 'thread';
  protected _storable => [qw/owner author createAt modifyAt parentId legend
                              topicId text title treeOfTree prioritet/];

1;
