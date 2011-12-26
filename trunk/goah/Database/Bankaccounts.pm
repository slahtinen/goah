#!/usr/bin/perl -w

=begin nd

Package: goah::Database::Bankaccounts

  Database definitions for Bankaccounts -table. Rows contain
  information about company accounts in domestic and in IBAN
  format.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Database::Bankaccounts;
use base 'goah::Database';

__PACKAGE__->table('Bankaccounts');
__PACKAGE__->columns(All => qw/id companyid domestic iban comment bankname bic/);

1;
