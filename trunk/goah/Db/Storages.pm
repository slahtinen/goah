#!/usr/bin/perl -w -CSDA

=begin nd

Package: goah::Db::Storages

  Db definitions for storage locations. Rows contain simple information
  about the storage locations.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Db::Storages;
use base qw(goah::Db::Object);

use strict;
use utf8;
use warnings;

__PACKAGE__->meta->setup
        (
	table      => 'Storages',
	columns    => [ qw(id name location info remote def) ],
	pk_columns => 'id',
	unique_key => 'id',
);

1;
