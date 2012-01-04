#!/usr/bin/perl -w

=begin nd

Package: goah::Db::customergroupsandtypes

  Simple key-value table to contain customer groups and types. 

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Db::customergroupsandtypes;
use base qw(goah::Db::Object);

__PACKAGE__->meta->setup
        (
	table      => 'customergroupsandtypes',
	columns    => [ qw(id type name) ],
	pk_columns => 'id',
	unique_key => 'id',
);

1;
