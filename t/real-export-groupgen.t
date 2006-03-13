#!perl -T
use strict;
use warnings;

=head1 TEST PURPOSE

These tests check export group expansion, specifically the expansion of groups
that use group generators, more specifically when actually imported.

=cut

use Test::More tests => 3;

use lib 't/lib';

BEGIN {
  use_ok('Test::SubExportC');
  Test::SubExportC->import(
    -generated => { xyz => 1 }, col1 => { value => 2 }
  );
}

for (qw(foo bar)) {
  is_deeply(
    main->$_(),
    {
      name  => $_,
      class => 'Test::SubExportC',
      group => 'generated',
      arg   => { xyz => 1 }, 
      collection => { col1 => { value => 2 } },
    },
    "generated foo does what we expect",
  );
}
