#!/usr/bin/perl -w

=begin nd

Package: goah::Db::Inventoryrows

  Db definition for inventory rows used by GoaH. Db rows store
  information about productid and amounts, plus optional information

About: License

  This software is copyright (c) 2010 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Db::Inventoryrows;
use base qw(goah::Db::Object);

__PACKAGE__->meta->setup
        (
	table      => 'Inventoryrows',
	columns    => [ qw(id inventoryid productid amount_before amount_after rowinfo) ],
	pk_columns => 'id',
	unique_key => 'id',
);

1;
