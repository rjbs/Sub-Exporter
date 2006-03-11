#!perl
use strict;
use warnings;

use Test::More tests => 17;

BEGIN { use_ok('Sub::Exporter'); }

use lib 't/lib';

{
  package Test::SubExporter::BUILT;

  my $import = Sub::Exporter::_polymorphic_build_exporter(qw(X));

  sub X { return "expected" }

  package Test::SubExporter::BUILT::CONSUMER;

  $import->('Test::SubExporter::BUILT', ':all');
  main::is(X(), "expected", "manually constructed importer worked");
}

package Test::SubExporter::DEFAULT;
main::use_ok('Test::SubExportB');
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
main::use_ok('Test::SubExportB', xyzzy => { -as => 'plugh' });
use subs qw(plugh);

main::is(
  plugh,
  "Nothing happens.",
  "RENAME: default export xyzzy=>plugh works as expected"
);

package Test::SubExporter::SAILOR;
main::use_ok('Test::SubExportB', ':sailor');;
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
main::use_ok('Test::SubExportB', hello_sailor => { game => 'zork3' });
use subs qw(hello_sailor);

main::is(
  hello_sailor,
  "Something happens!",
  "Z3: custom hello_sailor works as expected"
);

package Test::SubExporter::FROTZ_SAILOR;
main::use_ok('Test::SubExportB', -sailor => { -prefix => 'frotz_' });
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
