#!/usr/bin/perl -w -CSDA

=begin nd

Package: goah::Db::Productgroups

  Database definition for Productgroups -table. Table rows contain
  simple mechanism to represent product groups. Product group assignment
  is not stored to this table.

  This module uses Rose::DB instead of Class::DBI, which should speed up
  the process.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Db::Productgroups;
use base qw(goah::Db::Object);

use strict;
use utf8;
use warnings;

__PACKAGE__->meta->setup
        (
	table      => 'Productgroups',
	columns    => [ qw(id type name parent info grouptype) ],
	pk_columns => 'id',
	unique_key => 'id',
);

1;
