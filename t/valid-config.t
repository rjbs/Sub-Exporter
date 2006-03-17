#!perl -T
use strict;
use warnings;

=head1 TEST PURPOSE

These tests make sure that invalid configurations passed to build_exporter
throw exceptions.

=cut

use Test::More tests => 2;

BEGIN { use_ok('Sub::Exporter'); }

eval {
  Sub::Exporter::build_exporter({
    exports    => [ qw(foo) ],
    collectors => [ qw(foo) ],
  })
};

like($@, qr/used in both/, "can't use one name in exports and collectors");
