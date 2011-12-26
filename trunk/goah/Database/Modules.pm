#!/usr/bin/perl -w

=begin nd

Package: goah::Database::Modules

  Database definitions for Modules -table. Table rows contain very
  basic information about active modules. This table is used currently
  as an only source about active modules, but it's very possible to 
  extend the functionality.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Database::Modules;
use base 'goah::Database';

__PACKAGE__->table('modules');
__PACKAGE__->columns(All => qw/id name file sort/);  

1;
