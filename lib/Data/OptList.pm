
package Data::OptList;
use strict;
use warnings;

our $VERSION = '0.01';

# This produces an array of arrays; the inner arrays are name/value pairs.
# Values will be either "undef" or a reference.  $must_be is either a scalar or
# array of scalars; it defines what kind(s) of refs may be values.  If an
# invalid value is found, an exception is thrown.
# possible inputs:
#  undef    -> []
#  hashref  -> [ [ key1 => value1 ] ... ] # non-ref values become undef
#  arrayref -> every value followed by a ref becomes a pair: [ value => ref   ]
#              every value followed by undef becomes a pair: [ value => undef ]
#              otherwise, it becomes [ value => undef ] like so:
#              [ "a", "b", [ 1, 2 ] ] -> [ [ a => undef ], [ b => [ 1, 2 ] ] ]
#
# It would be nice for this 'canonicalized' form to have a canonical order,
# since it could be coming from a hash.
sub canonicalize_opt_list {
  my ($opt_list, $moniker, $require_unique, $must_be) = @_;

  return [] unless $opt_list;

  $opt_list = [
    map { $_ => (ref $opt_list->{$_} ? $opt_list->{$_} : ()) } keys %$opt_list
  ] if ref $opt_list eq 'HASH';

  my @return;
  my %seen;

  for (my $i = 0; $i < @$opt_list; $i++) {
    my $name = $opt_list->[$i];
    my $value;

    if ($require_unique) {
      Carp::croak "multiple definitions provided for $name" if $seen{$name}++;
    }

    if    ($i == $#$opt_list)             { $value = undef;            }
    elsif (not defined $opt_list->[$i+1]) { $value = undef; $i++       }
    elsif (ref $opt_list->[$i+1])         { $value = $opt_list->[++$i] }
    else                                  { $value = undef;            }

    if ($must_be and defined $value) {
      my $ref = ref $value;
      my $ok  = ref $must_be ? (grep { $ref eq $_ } @$must_be)
              :                ($ref eq $must_be);

      Carp::croak "$ref-ref values are not valid in $moniker opt list" if !$ok;
    }

    push @return, [ $name => $value ];
  }

  return \@return;
}

# This turns a canonicalized opt_list (see above) into a hash.
sub expand_opt_list {
  my ($opt_list, $moniker, $must_be) = @_;
  return {} unless $opt_list;
  return $opt_list if ref $opt_list eq 'HASH';

  $opt_list = canonicalize_opt_list($opt_list, $moniker, 1, $must_be);
  my %hash = map { $_->[0] => $_->[1] } @$opt_list;
  return \%hash;
}

1;
