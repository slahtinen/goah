#!/usr/bin/perl -w

=begin nd

Package: goah::Db::Referralrows

  Database definition for referral rows. Rows contain information about
  referral rows, like basket row id, how many units has been sent on referral
  and how much there's remaining goods on single row.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Db::Referralrows;
use base qw(goah::Db::Object);

__PACKAGE__->meta->setup
        (
	table      => 'Referralrows',
	columns    => [ qw(id refid rowid sent remaining rowinfo) ],
	pk_columns => 'id',
	unique_key => 'id',
);

1;
