#!/usr/bin/perl -w

=begin nd

Package: goah::Database::Basketrows

  Database definition for basket rows used by GoaH. Database rows store
  information about productid and price plus additional information.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Database::Basketrows;
use base 'goah::Database';

__PACKAGE__->table('Basketrows');
__PACKAGE__->columns(All => qw/id basketid productid purchase sell amount rowinfo code name vat/);  


1;
