use strict;
use warnings;

use inc::Module::Install;

name          ('Sub-Exporter');
author        ('Ricardo SIGNES <rjbs@cpan.org>');
license       ('perl');
version_from  ('lib/Sub/Exporter.pm');

requires('Sub::Install'  => 0.92 ); # exporter, needed to actually export
requires('Data::OptList' => 0.100); # used to process options
requires('Params::Util'  => 0.14 ); # _CODELIKE

WriteAll();
