#!/usr/bin/perl -w

=begin nd

Package: goah::Db::Companies

  Database definition for companies used by GoaH. This database
  stores both customer and owner information.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Db::Companies;
use base qw(goah::Db::Object);

__PACKAGE__->meta->setup
        (
	table      => 'Companies',
	columns    => [ qw(id vat_id name custtype payment_condition delay_interest reclamation_time www bank_accounts isowner description hidden firstname) ],
	pk_columns => 'id',
	unique_key => 'id',
);

1;
