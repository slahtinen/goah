#!/usr/bin/perl -w

=begin nd

Package: goah::Database::Invoicehistory

  Database definition for invoice history data. Table contains
  generic history information for invoice history.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut


package goah::Database::Invoicehistory;
use base 'goah::Database';

__PACKAGE__->table('Invoicehistory');
__PACKAGE__->columns(All => qw/id invoiceid time action startstate endstate info/);  



1;
