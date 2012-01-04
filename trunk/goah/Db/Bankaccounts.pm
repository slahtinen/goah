#!/usr/bin/perl -w -CSDA

=begin nd

Package: goah::Db::Bankaccounts

  Database definitions for Bankaccounts -table. Rows contain
  information about company accounts in domestic and in IBAN
  format.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Db::Bankaccounts;
use base qw(goah::Db::Object);

use strict;
use utf8;
use warnings;

__PACKAGE__->meta->setup
        (
	table      => 'Bankaccounts',
	columns    => [ qw(id companyid domestic iban comment bankname bic) ],
	pk_columns => 'id',
	unique_key => 'id',
);

1;
