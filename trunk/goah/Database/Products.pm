#!/usr/bin/perl -w -CSDA

=begin nd

Package: goah::Database::Products

  Database definition for products -table. Table rows contain basic
  information about individual product which is enough to create an
  invoice.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut


package goah::Database::Products;
use base 'goah::Database';

use strict;
use utf8;
use warnings;

__PACKAGE__->table('Products');
__PACKAGE__->columns(All => qw/id code name manufacturer groupid storage supplier purchase sell vat unit info hidden in_store barcode/);  

1;
