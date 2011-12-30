#!/usr/bin/perl -w -CSDA

=begin nd

Package: goah::Db::Manufacturers

  Database definition for Manufacturers table. Table rows contain basic
  information about product manufacturers.

  This module uses Rose::DB instead of Class::DBI, which should speed up
  the process.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut


package goah::Db::Manufacturers;
use base qw(goah::Db::Object);

use strict;
use utf8;
use warnings;

__PACKAGE__->meta->setup
        (
	table      => 'Manufacturers',
	columns    => [ qw(id name www info ean_gtin) ],
	pk_columns => 'id',
	unique_key => 'id',
);

1;
