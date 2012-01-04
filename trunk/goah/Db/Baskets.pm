#!/usr/bin/perl -w

=begin nd

Package: goah::Db::Baskets

  Db definition for basket rows used by GoaH. Db rows store
  information about productid and price plus additional information.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Db::Baskets;
use base qw(goah::Db::Object);

__PACKAGE__->meta->setup
        (
	table      => 'Baskets',
	columns    => [ qw(id companyid locationid billingid created updated ordernum state info ownerid lasttrigger dayinmonth repeat nexttrigger) ],
	pk_columns => 'id',
	unique_key => 'id',
);

1;
