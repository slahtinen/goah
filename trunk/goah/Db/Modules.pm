#!/usr/bin/perl -w

=begin nd

Package: goah::Db::Modules

  Db definitions for Modules -table. Table rows contain very
  basic information about active modules. This table is used currently
  as an only source about active modules, but it's very possible to 
  extend the functionality.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Db::Modules;
use base qw(goah::Db::Object);

__PACKAGE__->meta->setup
        (
	table      => 'modules',
	columns    => [ qw(id name file sort) ],
	pk_columns => 'id',
	unique_key => 'id',
);

1;
