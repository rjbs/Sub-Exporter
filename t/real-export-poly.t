#!perl
use strict;
use warnings;

use Test::More 'no_plan';

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
BEGIN { main::use_ok('Test::SubExportB'); };

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
BEGIN { main::use_ok('Test::SubExportB', xyzzy => { -as => 'plugh' }); };

main::is(
  plugh,
  "Nothing happens.",
  "RENAME: default export xyzzy=>plugh works as expected"
);

package Test::SubExporter::SAILOR;
BEGIN { main::use_ok('Test::SubExportB', ':sailor'); };

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
BEGIN {
  main::use_ok('Test::SubExportB', hello_sailor => { game => 'zork3' });
};

main::is(
  hello_sailor,
  "Something happens!",
  "Z3: custom hello_sailor works as expected"
);

package Test::SubExporter::FROTZ_SAILOR;
BEGIN { main::use_ok('Test::SubExportB', -sailor => { -prefix => 'frotz_' }); };

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
