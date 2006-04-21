
use strict;
use warnings;
package Test::SubExporter::Faux;

use base qw(Exporter);

our @EXPORT_OK = qw(faux_exporter exports_ok);

sub faux_exporter {
  my ($verbose) = @_;

  my @exported;

  my $reset = sub { @exported = () };

  my $export = sub {
    my ($class, $generator, $name, $arg, $collection, $as, $into) = @_;
    my $everything = { 
      class      => $class,
      generator  => $generator,
      name       => $name,
      arg        => $arg,
      collection => $collection,
      as         => $as,
      into       => $into,
    };
    push @exported, [ $name, ($verbose ? $everything : $arg) ];
  };

  return ($reset, $export, \@exported);
}

sub exports_ok {
  my ($expected, $got, $comment) = @_;
  my @e = sort { ($a->[0] cmp $b->[0]) || ($a->[1] <=> $b->[1]) } @$expected;
  my @g = sort { ($a->[0] cmp $b->[0]) || ($a->[1] <=> $b->[1]) } @$got;
  main::is_deeply(\@e, \@g, $comment);
}

1;
