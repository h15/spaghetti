
# Class: User::Object
# | Spaghetti's meatball.
# | Defines user model and some actions.
# Uses:
#   Pony::Model::Crud

package User::Object;
use Pony::Object;
use Pony::Model::Crud;

  protected _id => undef;
  protected _model => undef;
  protected _table => 'user';
  protected _storable => [qw/mail password name createAt modifyAt accessAt
                            banId banTime attempts threadId sshKeyCount/];
  
  
  # Function: init
  #   Constructor of user object. Generate properties form _storable.
  # Returns:
  #   User::Object
  
  sub init : Protected
    {
      my $this = shift;
      
      # Generate properties.
      Pony::Object::addPublic($this, $_) for @{ $this->_storable };
      
      $this->_model = new Pony::Model::Crud( $this->_table );
    }
  
  
  # Function: load
  #   Load from DB one object or set (if want array).
  # Parameters:
  #   where - hash or int - search db record condition.
  #   offset - int. Default 0.
  #   limit - int. Default 20.
  # Returns:
  #   Nothing or Array.
  
  sub load : Public
    {
      my $this = shift;
      my $where = shift;
      my $offset = shift || 0;
      my $limit = shift || 20;
      
      $where = {id => $where} unless ref $where;
      
      if ( wantarray )
      {
        return map { __PACKAGE__->new($_) }
          $this->_model->list($where, undef, undef, undef, $offset, $limit);
      }
      else
      {
        $this->setStorable( $this->_model->read($where) );
      }
    }
  
  
  # Function: save
  #   Save current state into db.
  
  sub save : Public
    {
      my $this = shift;
      
      # Update or create.
      if ( $this->getId() )
      {
        $this->_model->update( $this->getStorable(), {id => $this->getId()} );
      }
      else
      {
        $this->setId( $this->_model->create( $this->getStorable() ) );
      }
    }
  
  
  # Function: setId
  #   Id setter.
  # Parameters:
  #   id - scalar.
  
  sub setId : Public
    {
      my $this = shift;
      $this->_id = shift;
    }
  
  
  # Function: getId
  #   Id getter.
  # Returns:
  #   scalar or undef.
  
  sub getId : Public
    {
      my $this = shift;
      
      if ( defined $this->_id )
      {
        return $this->_id;
      }
      else
      {
        return undef;
      }
    }
  
  
  # Function: getStorable
  #   Get data from object (only storable fields).
  # Returns:
  #   HashRef.
  
  sub getStorable : Public
    {
      my $this = shift;
      my %o_data;
      
      %o_data = (%o_data, $_ => $this->$_) for @{ $this->_storable };
      
      return \%o_data;
    }
  
  
  # Function: setStorable
  #   Set data to storable fields.
  # Parameters:
  #   i_data - HashRef
  
  sub setStorable : Public
    {
      my $this = shift;
      my $i_data = shift;
      
      $this->$_ = $i_data->{$_} for @{ $this->_storable };
    }
  
1;
