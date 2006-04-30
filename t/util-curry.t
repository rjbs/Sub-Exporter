#!perl -T
use strict;
use warnings;

use Test::More tests => 8;
BEGIN { use_ok("Sub::Exporter"); }

  BEGIN {
    package Thing;
    BEGIN { main::use_ok('Sub::Exporter::Util', 'curry_class'); }
    use Sub::Exporter -setup => {
      exports => {
        return_invocant => curry_class,
      },
    };

    sub return_invocant { return $_[0] }
  }
  
  BEGIN {
    package Thing::Subclass;
    our @ISA = qw(Thing);
  }

package Test::SubExporter::CURRY::0;

BEGIN { Thing->import(qw(return_invocant)); }

main::is(
  Thing->return_invocant,
  "Thing",
  "method call on Thing returns Thing",
);

main::is(
  Thing::Subclass->return_invocant,
  "Thing::Subclass",
  "method call on Thing::Subclass returns Thing::Subclass",
);

main::is(
  return_invocant(),
  'Thing',
  'return of method class-curried from Thing is Thing'
);

package Test::SubExporter::CURRY::1;

BEGIN { Thing::Subclass->import(qw(return_invocant)); }

main::is(
  Thing->return_invocant,
  "Thing",
  "method call on Thing returns Thing",
);

main::is(
  Thing::Subclass->return_invocant,
  "Thing::Subclass",
  "method call on Thing::Subclass returns Thing::Subclass",
);

main::is(
  return_invocant(),
  'Thing::Subclass',
  'return of method class-curried from Thing::Subclass is Thing::Subclass'
);
