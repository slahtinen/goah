#!/usr/bin/perl -w -CSDA

=begin nd

Package: goah::Database::Productgroups

  Database definition for Productgroups -table. Table rows contain
  simple mechanism to represent product groups. Product group assignment
  is not stored to this table.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Database::Productgroups;
use base 'goah::Database';

use strict;
use utf8;
use warnings;

__PACKAGE__->table('Productgroups');
__PACKAGE__->columns(All => qw/id type name parent info grouptype/);  



1;
