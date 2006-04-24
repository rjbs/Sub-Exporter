#!perl -T
use strict;
use warnings;

use Test::More tests => 20;
BEGIN { use_ok("Sub::Exporter"); }

  BEGIN {
    package Thing;
    use Sub::Exporter -setup => {
      exports => {
        bar => sub { sub { 1 } },
        foo => sub {
          my ($c, $n, $a) = @_;
          sub { return $c . ($a->{arg}) }
        }
      },
    };
  }

  BEGIN {
    package Thing::Mixin;
    BEGIN { main::use_ok("Sub::Exporter::Util", 'mixin_exporter'); }
    use Sub::Exporter -setup => {
      exporter => mixin_exporter,
      exports  => {
        bar => sub { sub { 1 } },
        foo => sub {
          my ($c, $n, $a) = @_;
          sub { return $c . ($a->{arg}) }
        }
      },
    };
  }

package Test::SubExporter::MIXIN::0;

BEGIN {
  Thing->import(
    { exporter => Sub::Exporter::Util::mixin_exporter },
    -all => { arg => '0' },
  );
}

package Test::SubExporter::MIXIN::1;

BEGIN {
  Thing->import(
    { exporter => Sub::Exporter::Util::mixin_exporter },
    -all => { arg => '1' },
  );
}

package Test::SubExporter::MIXIN::2;

BEGIN {
  Thing::Mixin->import(
    -all => { arg => '2' },
  );
}

package Test::SubExporter::MIXIN::3;

BEGIN {
  Thing::Mixin->import(
    -all => { arg => '3' },
  );
}

package main;

my @pkg = map { "Test::SubExporter::MIXIN::$_" } (0 .. 3);

for (0 .. $#pkg) {
  my $ext = $_ > 1 ? '::Mixin' : '';
  my $val = eval { $pkg[$_]->foo } || ($@ ? "died: $@" : undef);

  is(
    $val,
    "Thing$ext$_",
    "mixed in method in $pkg[$_] returns correctly"
  );

  is($pkg[$_]->bar, 1, "bar method for $pkg[$_] is ok, too");
}

my @super = map {; no strict 'refs'; [ @{$_ . "::ISA"} ] } @pkg;

for my $x (0 .. $#pkg) {
  is(@{$super[$x]}, 1, "one parent for $pkg[$x]: @{$super[$x]}");
  for my $y (($x + 1) .. $#pkg) {
    isnt("@{$super[$x]}", "@{$super[$y]}", "parent($x) ne parent($y)")
  }
}
