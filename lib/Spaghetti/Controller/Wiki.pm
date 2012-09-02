package Spaghetti::Controller::Wiki;
use Mojo::Base 'Mojolicious::Controller';

  use Text::Diff;
  use Wiki::Document;
  use Wiki::Revision;
  
  sub create
    {
      my $this = shift;
      my $rev = new Wiki::Revision;
      my $doc = new Wiki::Document;
      
      $doc->set( url      => $this->param('url'),
                 title    => $this->param('title'),
                 text     => $this->param('text'),
                 createAt => time,
                 modifyAt => time );
      
      
    }
  
  sub read
    {
      my $this = shift;
      my $a = q{
        1
        2
        3
        4
        5
        6
        7
        8
        9
        0
        1
        2
        3
        4
        5
        6
        7
        8
        9
        9
      };
      my $b = q{
        1
        2
        3
        4
        5
        6
        71
        81
        91
        0
        1
        2
        3
        4
        5
        6
        7
        8
        9
        9
      };
      
      my $c = diff \$a, \$b;
      say $this->dumper($c);
      die;
    }
  
  sub update
    {
    
    }
  
  sub delete
    {
    
    }

1;
