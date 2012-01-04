#!/usr/bin/perl -w

=begin nd

Package: goah::Db::Incomingshipments

  Db definition for Incomingshipments -table. Table contains information for incoming
  shipments, such as supplier id and date & time.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut


package goah::Db::Incomingshipments;
use base qw(goah::Db::Object);
use utf8;

__PACKAGE__->meta->setup
        (
	table      => 'Incomingshipments',
	columns    => [ qw(id supplierid destination created due updated shipmentnum received info) ],
	pk_columns => 'id',
	unique_key => 'id',
);

1;
