#!/usr/bin/perl -w 

=begin nd

Package: goah::Database::Personalsettings

  Database definition for GoaH users personal settings. 

About: License

  This software is copyritght (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Database::Personalsettings;
use base 'goah::Database';

use strict;
use utf8;
use warnings;

goah::Database::Personalsettings->table('Personalsettings');
goah::Database::Personalsettings->columns(All => qw/id userid setting value/);  

1;
