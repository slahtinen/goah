#!/usr/bin/perl -w -CSDA

=begin nd

Package: goah::Database::Manufacturers

  Database definition for Manufacturers table. Table rows contain basic
  information about product manufacturers.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Database::Manufacturers;
use base 'goah::Database';

use strict;
use utf8;
use warnings;

goah::Database::Manufacturers->table('Manufacturers');
goah::Database::Manufacturers->columns(All => qw/id name www info ean_gtin/);  



1;
