#!/usr/bin/perl -w

=begin nd

Package: goah::Db::Baskethistory

  Db definition for basket history rows used by GoaH. Db rows store
  information about changes on basket

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Db::Baskethistory;
use base qw(goah::Db::Object);

__PACKAGE__->meta->setup
        (
	table      => 'Baskethistory',
	columns    => [ qw(id basketid rowid time uid action info) ],
	pk_columns => 'id',
	unique_key => 'id',
);

1;
