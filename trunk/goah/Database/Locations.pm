#!/usr/bin/perl -w

=begin nd

Package: goah::Database::Locations

  Database definition for company locations. Table rows contain information
  for locations (address, phone number etc) assigned to companies.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut


package goah::Database::Locations;
use base 'goah::Database';

__PACKAGE__->table('Locations');
__PACKAGE__->columns(All => qw/id companyid defshipping defbilling addr1 addr2 postalcode postaloffice country phone fax email info hidden/);


1;
