#!/usr/bin/perl -w

=begin nd

Package: goah::Db::Locations

  Db definition for company locations. Table rows contain information
  for locations (address, phone number etc) assigned to companies.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut


package goah::Db::Locations;
use base qw(goah::Db::Object);

__PACKAGE__->meta->setup
        (
	table      => 'Locations',
	columns    => [ qw(id companyid defshipping defbilling addr1 addr2 postalcode postaloffice country phone fax email info hidden) ],
	pk_columns => 'id',
	unique_key => 'id',
);

1;
