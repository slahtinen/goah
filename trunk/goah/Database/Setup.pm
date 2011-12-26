#!/usr/bin/perl -w -CSDA

=begin nd

Package: goah::Database::Setup

  Definitions for 'Setup' database table. Rows contain simle key-value -pairs
  with additional info about setting category.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut


package goah::Database::Setup;
use base 'goah::Database';

use strict;
use utf8;
use warnings;

__PACKAGE__->table('Setup');
__PACKAGE__->columns(All => qw/id category item value sort def/);  

1;
