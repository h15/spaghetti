use Mojo::Base -strict;

use Test::More tests => 4;
use Test::Mojo;

use_ok 'Forum';

my $t = Test::Mojo->new('Forum');
$t->get_ok('/welcome')->status_is(200)->content_like(qr/Mojolicious/i);
