#!/usr/bin/perl -w

=begin nd

Package: goah::Db::Invoices

  Db definition for invoices. Table contains 'full' information
  about the invoice minus actual invoice rows.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

See also:

  <goah::Db::Invoicehistory>
  <goah::Db::Invoicerows>

=cut


package goah::Db::Invoices;
use base qw(goah::Db::Object);

__PACKAGE__->meta->setup
        (
	table      => 'Invoices',
	columns    => [ qw(id invoicenumber companyid locationid billingid referralid created due referencenumber delayinterest customerreference state payment_condition received) ],
	pk_columns => 'id',
	unique_key => 'id',
);

1;
