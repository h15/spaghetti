package Wiki::Document;
use Pony::Object qw/Pony::Model::ActiveRecord::MySQL/;

  protected _id => undef;
  protected _model => undef;
  protected _table => 'wikiDocument';
  protected _storable => [qw/revisionId title text url createAt modifyAt/];
  
  sub init : Public
    {
      my $this = shift;
      
      $this->SUPER::init($this);
    }

1;
