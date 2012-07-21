#!/usr/bin/perl

use File::Basename 'dirname';
use File::Spec;

use constant APP_PATH =>
  join '/', File::Spec->splitdir(dirname(__FILE__)), '..';

use lib APP_PATH . '/lib';
use lib APP_PATH . '/meatballs';

use Pony::Stash;
use Spaghetti;

Pony::Stash->new(APP_PATH . '/config/application.yaml');

Spaghetti->start;
