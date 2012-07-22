
# Class: Pony::Model::ActiveRecord::MySQL
#   An abstract class for ActiveRecord pattern support.
# Uses:
#   Pony::Model::Crud

package Pony::Model::ActiveRecord::MySQL;
use Pony::Object -abstract;
use Pony::Model::Crud;

  protected _id => undef;
  protected _model => undef;
  protected _table => undef;
  protected _storable => [];
  
  
  # Function: init
  #   Constructor of user object. Generate properties form _storable.
  # Returns:
  #   User::Object
  
  sub init : Public
    {
      my $this = shift;
      
      # Generate properties.
      public $_ for @{ $this->_storable };
      
      $this->_model = new Pony::Model::Crud::MySQL( $this->_table );
      
      return $this;
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
        my $data = $this->_model->read($where);
        
        if ( defined $data )
        {
          $this->setStorable($data);
          $this->setId( $data->{id} );
        }
      }
      
      return $this;
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
      
      return $this;
    }
  
  
  # Function: setId
  #   Id setter.
  # Parameters:
  #   id - scalar.
  
  sub setId : Public
    {
      my $this = shift;
      $this->_id = shift;
      
      return $this;
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

  sub set : Public
    {
      my $this = shift;
      my $i_data = shift;
      
      $this->$_ = $i_data->{$_} for keys %$i_data;
      
      return $this;
    }

1;
