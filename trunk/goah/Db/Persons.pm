#!/usr/bin/perl -w

=begin nd

Package: goah::Db::Persons

  Database definition for Persons -table. Table rows contain basic
  information about individual person. 

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Db::Persons;
use base qw(goah::Db::Object);

__PACKAGE__->meta->setup
        (
	table      => 'Persons',
	columns    => [ qw(id companyid firstname lastname title phone mobile fax email locationid) ],
	pk_columns => 'id',
	unique_key => 'id',
);

1;
