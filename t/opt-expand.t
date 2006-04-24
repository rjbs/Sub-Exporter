#!perl -T
use strict;
use warnings;

=head1 TEST PURPOSE

These tests test option list expansion (from an option list into a hashref).

=cut

use Sub::Install;
use Test::More 'no_plan';

BEGIN { use_ok('Data::OptList'); }

# let's get a convenient copy to use:
Sub::Install::install_sub({
  code => 'expand_opt_list',
  from => 'Data::OptList',
  as   => 'EXP',
});

is_deeply(
  EXP([]),
  {},
  "empty opt list expands properly",
);

is_deeply(
  EXP([ qw(foo bar baz) ]),
  { foo => undef, bar => undef, baz => undef },
  "opt list of just names expands",
);

is_deeply(
  EXP([ qw(foo :bar baz) ]),
  { foo => undef, ':bar' => undef, baz => undef },
  "opt list of names expands with :group names",
);

is_deeply(
  EXP([ foo => { a => 1 }, ':bar', 'baz' ]),
  { foo => { a => 1 }, ':bar' => undef, baz => undef },
  "opt list of names and values expands",
);

is_deeply(
  EXP([ foo => { a => 1 }, ':bar' => undef, 'baz' ]),
  { foo => { a => 1 }, ':bar' => undef, baz => undef },
  "opt list of names and values expands, ignoring undef",
);

is_deeply(
  EXP({ foo => { a => 1 }, -bar => undef, baz => undef }, 0, 'HASH'),
  { foo => { a => 1 }, -bar => undef, baz => undef },
  "opt list of names and values expands with must_be",
);

is_deeply(
  EXP({ foo => { a => 1 }, -bar => undef, baz => undef }, 0, ['HASH']),
  { foo => { a => 1 }, -bar => undef, baz => undef },
  "opt list of names and values expands with [must_be]",
);

eval { EXP({ foo => { a => 1 }, -bar => undef, baz => undef }, 0, 'ARRAY'); };
like($@, qr/HASH-ref values are not/, "exception tossed on invaild ref value");

eval { EXP({ foo => { a => 1 }, -bar => undef, baz => undef }, 0, ['ARRAY']); };
like($@, qr/HASH-ref values are not/, "exception tossed on invaild ref value");
