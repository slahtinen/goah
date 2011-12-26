#!/usr/bin/perl -w

=begin nd

Package: goah::Database::customergroupsandtypes

  Simple key-value table to contain customer groups and types. 

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut


package goah::Database::customergroupsandtypes;
use base 'goah::Database';

__PACKAGE__->table('customergroupsandtypes');
__PACKAGE__->columns(All => qw/id type name/);  

1;
