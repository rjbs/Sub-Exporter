
use strict;
use warnings;
package Test::SubExporter::Faux;

use base qw(Exporter);

our @EXPORT = qw(faux_exporter exports_ok everything_ok);

sub faux_exporter {
  my ($verbose) = @_;
  $verbose = 1;

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
  my ($got, $expected, $comment) = @_;
  my $got_simple = [ map { [ $_->[0], $_->[1]{arg} ] } @$got ];
  my @g = sort { ($a->[0] cmp $b->[0]) || ($a->[1] <=> $b->[1]) } @$got_simple;
  my @e = sort { ($a->[0] cmp $b->[0]) || ($a->[1] <=> $b->[1]) } @$expected;
  main::is_deeply(\@e, \@g, $comment);
}

sub everything_ok {
  my ($got, $expected, $comment) = @_;
  my @g = sort { ($a->[0] cmp $b->[0]) || ($a->[1] <=> $b->[1]) } @$got;
  my @e = sort { ($a->[0] cmp $b->[0]) || ($a->[1] <=> $b->[1]) } @$expected;
  main::is_deeply(\@e, \@g, $comment);
}

1;
