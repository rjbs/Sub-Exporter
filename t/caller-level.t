#!perl -T

use strict;
use warnings;

use Test::More tests => 9;

BEGIN { 
  use_ok('Sub::Exporter'); 
}

BEGIN {
  package Test::SubExport::FROM;
  use strict;
  use warnings;    
  use Sub::Exporter -setup => {
    exports => [ qw(A B) ],
    groups  => {
      default => [ ':all' ],
      a       => [ 'A'    ],
      b       => [ 'B'    ]
    }
  };

  sub A { 'A' }
  sub B { 'B' }

  1;    
}

BEGIN {
  package Test::SubExport::INTO;
  use strict;
  use warnings;
  
  sub import {
    my $package = shift;
    my $caller  = caller(0);
    Test::SubExport::FROM->import( { into => $caller }, @_ );
  }
  
  1;
}

BEGIN {
  package Test::SubExport::LEVEL;
  use strict;
  use warnings;
  
  sub import {
    my $package = shift;
    Test::SubExport::FROM->import( { into_level => 1 }, @_ );
  }
  
  1;
}

package Test::SubExport::INTO::A;
Test::SubExport::INTO->import('A');

main::can_ok(__PACKAGE__, 'A' );
main::cmp_ok(
  __PACKAGE__->can('A'), '==', Test::SubExport::FROM->can('A'),
  'sub A was exported'
);

package Test::SubExport::INTO::ALL;
Test::SubExport::INTO->import(':all');

main::can_ok(__PACKAGE__, 'A', 'B' );

main::cmp_ok(
  __PACKAGE__->can('A'), '==', Test::SubExport::FROM->can('A'),
  'sub A was exported'
);

main::cmp_ok(
  __PACKAGE__->can('B'), '==', Test::SubExport::FROM->can('B'),
  'sub B was exported'
);

package Test::SubExport::LEVEL::ALL;
Test::SubExport::LEVEL->import(':all');

main::can_ok(__PACKAGE__, 'A', 'B' );

main::cmp_ok(
  __PACKAGE__->can('A'), '==', Test::SubExport::FROM->can('A'),
  'sub A was exported'
);

main::cmp_ok(
  __PACKAGE__->can('B'), '==', Test::SubExport::FROM->can('B'),
  'sub B was exported'
);
