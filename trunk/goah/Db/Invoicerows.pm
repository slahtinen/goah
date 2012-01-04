#!/usr/bin/perl -w

=begin nd

Package: goah::Db::Invoicerows

  Db definition for invoice row data. Rows include information
  for individual row (productid, prices, amount).

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

See also:

  <goah::Db::Invoices>

=cut


package goah::Db::Invoicerows;
use base qw(goah::Db::Object);

__PACKAGE__->meta->setup
        (
	table      => 'Invoicerows',
	columns    => [ qw(id invoiceid productid purchase sell amount rowinfo code name) ],
	pk_columns => 'id',
	unique_key => 'id',
);

1;
