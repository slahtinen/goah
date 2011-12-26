#!/usr/bin/perl -w

=begin nd

Package: goah::Database::Incomingshipments

  Database definition for Incomingshipments -table. Table contains information for incoming
  shipments, such as supplier id and date & time.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut


package goah::Database::Incomingshipments;
use base 'goah::Database';
use utf8;

__PACKAGE__->table('Incomingshipments');
__PACKAGE__->columns(All => qw/id supplierid destination created due updated shipmentnum received info/);

1;
