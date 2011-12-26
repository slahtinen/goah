#!/usr/bin/perl -w

=begin nd

Package: goah::Database::Incomingshipmentrows

  Database definition for incoming shipment rows used by GoaH. Database rows store
  information about productid and price plus additional information.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Database::Incomingshipmentrows;
use base 'goah::Database';

__PACKAGE__->table('Incomingshipmentrows');
__PACKAGE__->columns(All => qw/id shipmentid productid purchase amount sold rowinfo/);

1;
