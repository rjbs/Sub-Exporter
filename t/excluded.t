#!perl -T

=head1 TEST PURPOSE

Check "bang-syntax": import a group while excluding some particular names

=cut

package E;
use strict;
use warnings;

use Sub::Exporter -setup => {
  exports => [ map {$_ => \&generator} qw/a b c d/ ],
  groups => {
    g1 => [qw/a b/],
    g2 => [qw/c d/],
   },
 };

sub generator {
  my ($class, $name, $arg, $col) = @_;
  return sub { "${class}::${name}" };
}

package main;

use strict;
use warnings;
use Test::More tests => 2;

E->import(qw/:all !b !d/);

is(a(), 'E::a', 'a imported');
ok(!eval{b()}, 'b not imported');







