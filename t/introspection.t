#!perl -T
use strict;
use warnings;

=head1 TEST PURPOSE

This tests the ability to introspect a Sub::Exporter based class.

=cut

use Test::More tests => 1;

{
    package An::Exporter;
    use strict;
    use warnings;
    use Sub::Exporter -setup => {
        exports => [ 'a' ]
    };

    sub a { 'a' }
}

is_deeply(
    An::Exporter->can('import')->config->{exports},
    { a => undef },
    "Accessed the config data"
);
