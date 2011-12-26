#!/usr/bin/perl -w

=begin nd

Package: goah::Database::Persons

  Database definition for Persons -table. Table rows contain basic
  information about individual person. 

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Database::Persons;
use base 'goah::Database';

__PACKAGE__->table('Persons');
__PACKAGE__->columns(All => qw/id companyid firstname lastname title phone mobile fax email locationid/);

1;
