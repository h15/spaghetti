package Wiki::Revision;
use Pony::Object qw/Pony::Model::ActiveRecord::MySQL/;

  protected _id => undef;
  protected _model => undef;
  protected _table => 'wikiRevision';
  protected _storable => [qw/next prev isCurrent documentId
                          author createAt diff/];
  
  sub init : Public
    {
      my $this = shift;
      
      $this->SUPER::init($this);
    }

1;
