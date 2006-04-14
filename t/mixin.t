#!perl -T
use strict;
use warnings;

use Test::More 'no_plan';
BEGIN { use_ok("Sub::Exporter"); }

Thing->import(
  { exporter => Sub::Exporter::_export_mixin_gen },
  'foo',
);

use Data::Dump::Streamer;

Dump(\@main::ISA);

package Thing;
use Sub::Exporter -setup => {
  exports => [ qw(foo) ],
};

sub foo {
  return 'foo';
}
