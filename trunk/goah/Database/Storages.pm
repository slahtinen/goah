#!/usr/bin/perl -w -CSDA

=begin nd

Package: goah::Database::Storages

  Database definitions for storage locations. Rows contain simple information
  about the storage locations.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Database::Storages;
use base 'goah::Database';

use strict;
use utf8;
use warnings;

__PACKAGE__->table('Storages');
__PACKAGE__->columns(All => qw/id name location info remote def/);  


1;
