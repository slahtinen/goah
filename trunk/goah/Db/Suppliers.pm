#!/usr/bin/perl -w -CSDA

=begin nd

Package: goah::Db::Suppliers

  An database definition for storing supplier data. Rows contain basic
  information about suppliers which are stored to database. This data
  isn't linked directly from anywhere.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Db::Suppliers;
use base qw(goah::Db::Object);

use strict;
use utf8;
use warnings;

__PACKAGE__->meta->setup
        (
	table      => 'Suppliers',
	columns    => [ qw(id name www contact info) ],
	pk_columns => 'id',
	unique_key => 'id',
);

1;
