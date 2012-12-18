#!/usr/bin/perl -w

=begin nd

Package: goah::Database::Invoices

  Database definition for invoices. Table contains 'full' information
  about the invoice minus actual invoice rows.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

See also:

  <goah::Database::Invoicehistory>
  <goah::Database::Invoicerows>

=cut


package goah::Database::Invoices;
use base 'goah::Database';

__PACKAGE__->table('Invoices');
__PACKAGE__->columns(All => qw/id invoicenumber companyid locationid billingid referralid created due referencenumber delayinterest customerreference state payment_condition received ordernumber/);  

1;
