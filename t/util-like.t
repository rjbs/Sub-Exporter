#!perl -T
use strict;
use warnings;

use Test::More tests => 8;
BEGIN { use_ok("Sub::Exporter"); }
BEGIN { use_ok("Sub::Exporter::Util"); }

use lib 't/lib';
use Test::SubExporter::Faux;

my ($reset, $export, $exports);
BEGIN { ($reset, $export, $exports) = faux_exporter; }

my %generator;
BEGIN {
  %generator = (
    foo   => sub { sub { 1 } },
    bar   => sub { sub { 2 } },
    baz   => sub { sub { 3 } },
    BAR   => sub { sub { 4 } },
    xyzzy => sub { sub { 5 } },
  );
}

  BEGIN {
    isa_ok($export, 'CODE');

    package Thing;
    use Sub::Exporter -setup => {
      exporter   => $export,
      collectors => {
        -like => Sub::Exporter::Util::like
      },
      exports => \%generator,
    };
  }

package main;

my $code = sub {
  $reset->();
  Thing->import(@_);
};

$code->(qw(foo xyzzy));
exports_ok(
  $exports,
  [ [ foo => {} ], [ xyzzy => {} ] ],
  "the basics work normally"
);

$code->(-like => qr/^b/i);
exports_ok(
  $exports,
  [ [ BAR => {} ], [ baz => {} ], [ bar => {} ] ],
  "give me everything starting with b or B (qr//)"
);

$code->(-like => [ qr/^b/i ]);
exports_ok(
  $exports,
  [ [ BAR => {} ], [ baz => {} ], [ bar => {} ] ],
  "give me everything starting with b or B ([qr//])"
);

$code->(-like => [ qr/^b/i => undef ]);
exports_ok(
  $exports,
  [ [ BAR => {} ], [ baz => {} ], [ bar => {} ] ],
  "give me everything starting with b or B ([qr//=>undef])"
);

# XXX: must use verbose exporter
$code->(-like => [ qr/^b/i => { -prefix => 'like_' } ]);
everything_ok(
  $exports,
  [
    [
      BAR => {
        class      => 'Thing',
        generator  => $generator{BAR},
        name       => 'BAR',
        arg        => {},
        collection => { -like => [ qr/^b/i => { -prefix => 'like_' } ] },
        as         => 'like_BAR',
        into       => 'main',
      },
    ],
    [
      bar => {
        class      => 'Thing',
        generator  => $generator{bar},
        name       => 'bar',
        arg        => {},
        collection => { -like => [ qr/^b/i => { -prefix => 'like_' } ] },
        as         => 'like_bar',
        into       => 'main',
      },
    ],
    [
      baz => {
        class      => 'Thing',
        generator  => $generator{baz},
        name       => 'baz',
        arg        => {},
        collection => { -like => [ qr/^b/i => { -prefix => 'like_' } ] },
        as         => 'like_baz',
        into       => 'main',
      },
    ],
  ],
  'give me everything starting with b or B as like_$_ ([qr//=>{...}])'
);
