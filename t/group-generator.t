#!perl -T
use strict;
use warnings;

=head1 TEST PURPOSE

These tests check export group expansion, name prefixing, and option merging.

=cut

use Test::More 'no_plan';

BEGIN { use_ok('Sub::Exporter'); }

my $import_target;

my $alfa  = sub { 'alfa'  };
my $bravo = sub { 'bravo' };

my $config = {
  exports => [ ],
  groups  => {
    alphabet => sub { { a => $alfa, b => $bravo } },
  }
};

my @single_tests = (
  # [ comment, \@group, \@output ]
  # [ "simple group 1", [ ':A' => undef ] => [ [ a => undef ] ] ],
  [
    "simple group generator",
    [ -alphabet => undef ],
    [ [ a => $alfa ], [ b => $bravo ] ],
  ],
  [
    "simple group generator with prefix",
    [ -alphabet => { -prefix => 'prefix_' } ],
    [ [ prefix_a => $alfa ], [ prefix_b => $bravo ] ],
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
  # [ $comment, \@groups, \@output ]
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

