#!/usr/bin/perl -w -CSDA

=begin nd

Package: goah::Database::Suppliers

  An database definition for storing supplier data. Rows contain basic
  information about suppliers which are stored to database. This data
  isn't linked directly from anywhere.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Database::Suppliers;
use base 'goah::Database';

use strict;
use utf8;
use warnings;

__PACKAGE__->table('Suppliers');
__PACKAGE__->columns(All => qw/id name www contact info/);  



1;
