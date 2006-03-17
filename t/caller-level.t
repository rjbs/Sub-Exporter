#!perl -T

use strict;
use warnings;

use Test::More tests => 6;

BEGIN { 
  use_ok('Sub::Exporter'); 
}

BEGIN {
  package MyExport1;
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
  package MyExport2;
  use strict;
  use warnings;
  
  sub import {
    my $package = shift;
    my $caller  = caller(0);
    MyExport1->import( { into => $caller }, @_ );
  }
  
  1;
}

MyExport2->import('A');

can_ok(__PACKAGE__, 'A' );
cmp_ok(__PACKAGE__->can('A'), '==', MyExport1->can('A'), 'sub A was exported');

MyExport2->import(':all');

can_ok(__PACKAGE__, 'A', 'B' );

cmp_ok(__PACKAGE__->can('A'), '==', MyExport1->can('A'), 'sub A was exported');
cmp_ok(__PACKAGE__->can('B'), '==', MyExport1->can('B'), 'sub B was exported');
