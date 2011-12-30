#!/usr/bin/perl -w -CSDA

=begin nd

Package: goah::Database::Products

  Database definition for products -table. Table rows contain basic
  information about individual product which is enough to create an
  invoice.

  This module uses Rose::DB instead of Class::DBI, which should speed up
  the process.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut


package goah::Db::Products;
use base qw(goah::Db::Object);

use strict;
use utf8;
use warnings;

__PACKAGE__->meta->setup
        (
	table      => 'products',
	columns    => [ qw(id code name manufacturer groupid storage supplier purchase sell vat unit info hidden in_store barcode) ],
	pk_columns => 'id',
	unique_key => 'code',
);

1;
