#!/usr/bin/perl -w -CSDA

=begin nd

Package: goah::Db::Setup

  Definitions for 'Setup' database table. Rows contain simle key-value -pairs
  with additional info about setting category.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut


package goah::Db::Setup;
use base qw(goah::Db::Object);

use strict;
use utf8;
use warnings;

__PACKAGE__->meta->setup
        (
	table      => 'Setup',
	columns    => [ qw(id category item value sort def) ],
	pk_columns => 'id',
	unique_key => 'id',
);

1;
