use strict;
use warnings;

use inc::Module::Install;

name          ('Sub-Exporter');
author        ('Ricardo SIGNES <rjbs@cpan.org>');
license       ('perl');
version_from  ('lib/Sub/Exporter.pm');

requires('Sub::Install' => 0.91);
requires('List::Util'   => 0.00); # unknown minimum
requires('Scalar::Util' => 0.00); # unknown minimum

sign(1);

# auto_install;
WriteAll();
