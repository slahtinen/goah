#!/usr/bin/perl -w -CSDA

=begin nd

Package: goah::Db::Timetracking

  An database definition for storing time tracking data. 

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.
  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Db::Timetracking;
use base qw(goah::Db::Object);

use strict;
use utf8;
use warnings;

__PACKAGE__->meta->setup
        (
	table      => 'Timetracking',
	columns    => [ qw(id companyid userid type day description project personnel hours no_billing productcode) ],
	pk_columns => 'id',
	unique_key => 'id',
);

1;
