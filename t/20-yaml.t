use strict;
use warnings;

use Test::More;
use Data::Remember YAML => file => 't/test.yml';
use YAML::Syck;

BEGIN { YAML::Syck::DumpFile('t/test.yml', {}); }

require 't/test-brain.pl';

unlink 't/test.yml';
