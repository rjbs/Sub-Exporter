#!perl -T
use strict;
use warnings;

=head1 TEST PURPOSE

These tests check export group expansion, name prefixing, and option merging.

=cut

use Test::More tests => 34;

BEGIN { use_ok('Sub::Exporter'); }

my $import_target;

my $config = {
  exports => [ qw(a b c) ],
  groups  => {
    A => [ 'a' ],
    B => [ qw(b c) ],
    C => [ qw(a b :C) ],
    D => [ qw(:A :B) ],

    a_as_b       => [  a => { -as => 'b' } ],
    prefixed_A   => [ -A => { -prefix => 'alfa_' } ],
    diprefixed_A => [ -prefixed_A => { -prefix => 'bravo_' } ],
    a_to_subref  => [  a => { -as => \$import_target }, 'b' ],
    prefixed_a_s => [ -a_to_subref => { -prefix => 'alfa_' } ],
  }
};

my @single_tests = (
  [ "simple group 1", [ ':A' => undef ] => [ [ a => undef ] ] ],
  [ "simple group 2", [ ':B' => undef ] => [ [ b => undef ], [ c => undef ] ] ],

  [
    "group of groups",
    [ ':D' => undef ],
    [ [ a => undef ], [ b => undef ], [ c => undef ] ],
  ],
  [
    "recursive group",
    [ ':C' => undef ],
    [ [ a => undef ], [b => undef ] ],
  ],
  [
    "group with empty args",
    [ -A => { } ],
    [ [ a => undef ] ],
  ],
  [
    "group with prefix",
    [ -A => { -prefix => 'alpha_' } ],
    [ [ a => { -as => 'alpha_a' } ] ],
  ],
  [
    "recursive group with prefix",
    [ -C => { -prefix => 'kappa_' } ],
    [ [ a => { -as => 'kappa_a' } ], [ b => { -as => 'kappa_b' } ] ],
  ],
  [
    "group that renames",
    [ -a_as_b => undef ],
    [ [ a => { -as => 'b' } ] ],
  ],
  [
    "group that renames, with options",
    [ -a_as_b => { foo => 10 } ],
    [ [ a => { -as => 'b', foo => 10 } ] ],
  ],
  [
    "group that renames, with a prefix",
    [ -a_as_b => { -prefix => 'not_really_' } ],
    [ [ a => { -as => 'not_really_b' } ] ],
  ],
  [
    "recursive group with a built-in prefix",
    [ -prefixed_A => undef ],
    [ [ a => { -as => 'alfa_a' } ] ],
  ],
  [
    "recursive group with built-in and passed-in prefix",
    [ -prefixed_A => { -prefix => 'bravo_' } ],
    [ [ a => { -as => 'bravo_alfa_a' } ] ],
  ],
  [
    "multi-prefixed group",
    [ -diprefixed_A => undef ],
    [ [ a => { -as => 'bravo_alfa_a' } ] ],
  ],
  [
    "multi-prefixed group with prefix",
    [ -diprefixed_A => { -prefix => 'charlie_' } ],
    [ [ a => { -as => 'charlie_bravo_alfa_a' } ] ],
  ],
  [
    "group that exports to scalar (unusual)",
    [ -a_to_subref => undef ],
    [ [ a => { -as => \$import_target } ], [ b => undef ] ],
  ],
  [
    "group that exports to scalar, with prefix",
    [ -a_to_subref => { -prefix => 'jubju' } ],
    [ [ a => { -as => \$import_target } ], [ b => { -as => 'jubjub' } ] ],
  ],
);

for my $test (@single_tests) {
  my ($label, $given, $expected) = @$test;
  
  my @got = Sub::Exporter::_expand_group(
    'Class',
    $config,
    $given,
    {},
  );

  is_deeply(\@got, $expected, "expand_group: $label");
}

for my $test (@single_tests) {
  my ($label, $given, $expected) = @$test;
  
  my $got = Sub::Exporter::_expand_groups(
    'Class',
    $config,
    [ $given ],
  );

  is_deeply($got, $expected, "expand_groups: $label [single test]");
}

my @multi_tests = (
  [
    "group and export",
    [ [ ':A', undef ], [ c => undef ] ],
    [ [  a => undef ], [ c => undef ] ]
  ],
);

for my $test (@multi_tests) {
  my ($label, $given, $expected) = @$test;
  
  my $got = Sub::Exporter::_expand_groups(
    'Class',
    $config,
    $given,
  );

  is_deeply($got, $expected, "expand_groups: $label");
}

