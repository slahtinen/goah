#!/usr/bin/perl -w

=begin nd

Package: goah::Database::Inventoryrows

  Database definition for inventory rows used by GoaH. Database rows store
  information about productid and amounts, plus optional information

About: License

  This software is copyright (c) 2010 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Database::Inventoryrows;
use base 'goah::Database';

__PACKAGE__->table('Inventoryrows');
__PACKAGE__->columns(All => qw/id inventoryid productid amount_before amount_after rowinfo/);

1;
