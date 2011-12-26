#!/usr/bin/perl -w

=begin nd

Package: goah::Database::Referrals

  Database definition for basic referral information. Rows contain
  only basic information to individual referral, such as creation
  date and who created it. Actual referral content is stored to Referralrows 
  -table

See also:

  <goah::Database::Referralrows>

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Database::Referrals;
use base 'goah::Database';

__PACKAGE__->table('Referrals');
__PACKAGE__->columns(All => qw/id refnum orderid created due sent info/);


1;
