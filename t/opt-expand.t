#!perl -T
use strict;
use warnings;

=head1 TEST PURPOSE

These tests test option list expansion (from an option list into a hashref).

=cut

use Test::More tests => 6;

BEGIN { use_ok('Sub::Exporter'); }

# let's get a convenient copy to use:
Sub::Install::install_sub({
  code => '_expand_opt_list',
  from => 'Sub::Exporter',
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
