package Spaghetti::Controller::Wiki;
use Mojo::Base 'Mojolicious::Controller';

  use Wiki::Document;
  use Wiki::Revision;
  
  sub create
    {
      my $this = shift;
      my $rev = new Wiki::Revision;
      my $doc = new Wiki::Document;
      
      $
      
      $doc->set( url      => $this->param('url'),
                 title    => $this->param('title'),
                 text     => $this->param('text'),
                 createAt => time,
                 modifyAt => time );
      
      
    }
  
  sub read
    {
    
    }
  
  sub update
    {
    
    }
  
  sub delete
    {
    
    }

1;
