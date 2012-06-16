#!/usr/bin/env perl

use strict;
use warnings;
use Test::LeakTrace::Script;

# Load application class
use lib 'lib';
use Spaghetti::Defaults;
use Spaghetti;

# Start application
Spaghetti->start;
