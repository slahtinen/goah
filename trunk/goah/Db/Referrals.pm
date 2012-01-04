#!/usr/bin/perl -w

=begin nd

Package: goah::Db::Referrals

  Db definition for basic referral information. Rows contain
  only basic information to individual referral, such as creation
  date and who created it. Actual referral content is stored to Referralrows 
  -table

See also:

  <goah::Db::Referralrows>

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Db::Referrals;
use base qw(goah::Db::Object);

__PACKAGE__->meta->setup
        (
	table      => 'Referrals',
	columns    => [ qw(id refnum orderid created due sent info) ], 
	pk_columns => 'id',
	unique_key => 'id',
);

1;
