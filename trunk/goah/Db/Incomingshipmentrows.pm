#!/usr/bin/perl -w

=begin nd

Package: goah::Db::Incomingshipmentrows

  Db definition for incoming shipment rows used by GoaH. Db rows store
  information about productid and price plus additional information.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Db::Incomingshipmentrows;
use base qw(goah::Db::Object);

__PACKAGE__->meta->setup
        (
	table      => 'Incomingshipmentrows',
	columns    => [ qw(id shipmentid productid purchase amount sold rowinfo) ],
	pk_columns => 'id',
	unique_key => 'id',
);

1;
