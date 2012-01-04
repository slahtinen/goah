#!/usr/bin/perl -w

=begin nd

Package: goah::Db::Invoicehistory

  Db definition for invoice history data. Table contains
  generic history information for invoice history.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut


package goah::Db::Invoicehistory;
use base qw(goah::Db::Object);

__PACKAGE__->meta->setup
        (
	table      => 'Invoicehistory',
	columns    => [ qw(id invoiceid time action startstate endstate info) ],
	pk_columns => 'id',
	unique_key => 'id',
);

1;
