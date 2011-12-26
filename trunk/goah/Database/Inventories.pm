#!/usr/bin/perl -w

=begin nd

Package: goah::Database::Inventories

  Database definition for Inventories -table. Table contains information about inventories

About: License

  This software is copyright (c) 2010 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut


package goah::Database::Inventories;
use base 'goah::Database';
use utf8;

__PACKAGE__->table('Inventories');
__PACKAGE__->columns(All => qw/id created info done/);

1;
