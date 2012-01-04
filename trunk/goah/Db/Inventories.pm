#!/usr/bin/perl -w

=begin nd

Package: goah::Db::Inventories

  Db definition for Inventories -table. Table contains information about inventories

About: License

  This software is copyright (c) 2010 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut


package goah::Db::Inventories;
use base qw(goah::Db::Object);
use utf8;

__PACKAGE__->meta->setup
        (
	table      => 'Inventories',
	columns    => [ qw(id created info done) ],
	pk_columns => 'id',
	unique_key => 'id',
);

1;
