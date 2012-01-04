#!/usr/bin/perl -w 

=begin nd

Package: goah::Db::Personalsettings

  Db definition for GoaH users personal settings. 

About: License

  This software is copyritght (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Db::Personalsettings;
use base qw(goah::Db::Object);

use strict;
use utf8;
use warnings;

__PACKAGE__->meta->setup
        (
	table      => 'Personalsettings',
	columns    => [ qw(id userid setting value) ],
	pk_columns => 'id',
	unique_key => 'id',
);

1;
