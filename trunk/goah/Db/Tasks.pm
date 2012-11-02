#!/usr/bin/perl -w -CSDA

=begin nd

Package: goah::Db::Tasks

  An database definition for storing tasks.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.
  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Db::Tasks;
use base qw(goah::Db::Object);

use strict;
use utf8;
use warnings;

__PACKAGE__->meta->setup
        (
	table      => 'Tasks',
	columns	   => [ qw(id companyid userid assigneeid priority type day hours inthours description no_billing longdescription completed) ],
	pk_columns => 'id',
	unique_key => 'id',
);


1;
