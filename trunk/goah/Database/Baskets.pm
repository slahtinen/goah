#!/usr/bin/perl -w

=begin nd

Package: goah::Database::Baskets

  Database definition for Baskets -table. Table contains information for individual
  baskets like companyid and shipping & billing locations.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

See also:

  <goah::Database::Basketrows>

=cut


package goah::Database::Baskets;
use base 'goah::Database';
use utf8;

__PACKAGE__->table('Baskets');
__PACKAGE__->columns(All => qw/id companyid locationid billingid created updated ordernum state info ownerid lasttrigger dayinmonth repeat nexttrigger/);  



1;
