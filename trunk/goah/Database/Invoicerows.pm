#!/usr/bin/perl -w

=begin nd

Package: goah::Database::Invoicerows

  Database definition for invoice row data. Rows include information
  for individual row (productid, prices, amount).

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

See also:

  <goah::Database::Invoices>

=cut


package goah::Database::Invoicerows;
use base 'goah::Database';

__PACKAGE__->table('Invoicerows');
__PACKAGE__->columns(All => qw/id invoiceid productid purchase sell amount rowinfo code name vat/);  


1;
