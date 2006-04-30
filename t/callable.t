#!/usr/bin/perl -w
# Testing for _CALLABLE
# written by RJBS for ADAMK's Params::Util; tests here for inlined _CALLABLE
# in Sub::Exporter

use strict;
use lib ();
use UNIVERSAL 'isa';
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		chdir ($FindBin::Bin = $FindBin::Bin); # Avoid a warning
		lib->import( catdir( updir(), 'lib' ) );
	}
}


use Test::More;
use Scalar::Util qw(blessed reftype);
use overload;

sub  c_ok { ok(  _CALLABLE($_[0]), "callable: $_[1]"      ) }
sub nc_ok { ok( ! _CALLABLE($_[0]), "not callable: $_[1]" ) }

my @callables = (
  "callable itself"                         => \&_CALLABLE,
  "a boring plain code ref"                 => sub {},
  'an object with overloaded &{}'           => C::O->new,
  'a object build from a coderef'           => C::C->new,
  'an object with inherited overloaded &{}' => C::O::S->new, 
  'a coderef blessed into CODE'             => (bless sub {} => 'CODE'),
);

my @uncallables = (
  "undef"                                   => undef,
  "a string"                                => "a string",
  "a number"                                => 19780720,
  "a ref to a ref to code"                  => \(sub {}),
  "a boring plain hash ref"                 => {},
  'a class that builds from coderefs'       => "C::C",
  'a class with overloaded &{}'             => "C::O",
  'a class with inherited overloaded &{}'   => "C::O::S",
  'a plain boring hash-based object'        => UC->new,
  'a non-coderef blessed into CODE'         => (bless {} => 'CODE'),
);

plan tests => (@callables + @uncallables) / 2 + 2;

# Import the function
use_ok( 'Sub::Exporter' );
Sub::Install::install_sub({ code => '_CALLABLE', from => 'Sub::Exporter' });
ok( defined *_CALLABLE{CODE}, '_CALLABLE imported ok' );

while ( @callables ) {
  my ($name, $object) = splice @callables, 0, 2;
  c_ok($object, $name);
}

while ( @uncallables ) {
  my ($name, $object) = splice @uncallables, 0, 2;
  nc_ok($object, $name);
}





# callable: is a blessed code ref
package C::C;
sub new { bless sub {} => shift; }





# callable: overloads &{}
# but!  only objects are callable, not class
package C::O;
sub new { bless {} => shift; }
use overload '&{}'  => sub { sub {} };
use overload 'bool' => sub () { 1 };





# callable: subclasses C::O
package C::O::S;
use base 'C::O';





# uncallable: some boring object with no codey magic
package UC;
sub new { bless {} => shift; }
