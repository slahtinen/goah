#!/usr/bin/perl -w -CSDA

=begin nd

Package: goah::Db::Files

  An database definition for storing file upload/download information.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.
  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Db::Files;
use base qw(goah::Db::Object);

use strict;
use utf8;
use warnings;

__PACKAGE__->meta->setup
        (
	table      => 'Files',
	columns	   => [ qw(id userid moduleid date mimetype md5 datadir int_filename orig_filename status public expires downloads info) ],
	pk_columns => 'id',
	unique_key => 'id',
);


1;
