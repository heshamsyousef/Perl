


use strict;
use warnings;

use Data::Dumper;

use Test::More;
plan tests => 2;

use FindBin qw($Bin);
use lib "$Bin/..";

use_ok('Person');
can_ok( 'Person', 'sort_names' );

## Missing: test plan for sort_names

exit 0;