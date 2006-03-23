#!perl -T
use strict;
use warnings;

=head1 TEST PURPOSE

These tests exercise that the polymorphic exporter-builder used when
Sub::Exporter's -import group is invoked.

They use Test::SubExporter::DashSetup, bundled in ./t/lib, which uses this
calling style.

=cut

use Test::More tests => 33;

BEGIN { use_ok('Sub::Exporter'); }

our $exporting_class = 'Test::SubExporter::DashSetup';

use lib 't/lib';

for my $iteration (1..2) {
  {
    package Test::SubExporter::SETUP;
    use Sub::Exporter -setup => qw(X);

    sub X { return "desired" }

    package Test::SubExporter::SETUP::CONSUMER;

    Test::SubExporter::SETUP->import(':all');
    main::is(X(), "desired", "constructed importer (via -setup LIST) worked");
  }

  package Test::SubExporter::DEFAULT;
  main::use_ok($exporting_class);
  use subs qw(xyzzy hello_sailor);

  main::is(
    xyzzy,
    "Nothing happens.",
    "DEFAULT: default export xyzzy works as expected"
  );

  main::is(
    hello_sailor,
    "Nothing happens yet.",
    "DEFAULT: default export hello_sailor works as expected"
  );

  package Test::SubExporter::RENAME;
  main::use_ok($exporting_class, xyzzy => { -as => 'plugh' });
  use subs qw(plugh);

  main::is(
    plugh,
    "Nothing happens.",
    "RENAME: default export xyzzy=>plugh works as expected"
  );

  package Test::SubExporter::SAILOR;
  main::use_ok($exporting_class, ':sailor');;
  use subs qw(xyzzy hs_works hs_fails);

  main::is(
    xyzzy,
    "Nothing happens.",
    "SAILOR: default export xyzzy works as expected"
  );

  main::is(
    hs_works,
    "Something happens!",
    "SAILOR: hs_works export works as expected"
  );

  main::is(
    hs_fails,
    "Nothing happens yet.",
    "SAILOR: hs_fails export works as expected"
  );

  package Test::SubExporter::Z3;
  main::use_ok($exporting_class, hello_sailor => { game => 'zork3' });
  use subs qw(hello_sailor);

  main::is(
    hello_sailor,
    "Something happens!",
    "Z3: custom hello_sailor works as expected"
  );

  package Test::SubExporter::FROTZ_SAILOR;
  main::use_ok($exporting_class, -sailor => { -prefix => 'frotz_' });
  use subs map { "frotz_$_" }qw(xyzzy hs_works hs_fails);

  main::is(
    frotz_xyzzy,
    "Nothing happens.",
    "FROTZ_SAILOR: default export xyzzy works as expected"
  );

  main::is(
    frotz_hs_works,
    "Something happens!",
    "FROTZ_SAILOR: hs_works export works as expected"
  );

  main::is(
    frotz_hs_fails,
    "Nothing happens yet.",
    "FROTZ_SAILOR: hs_fails export works as expected"
  );
}
