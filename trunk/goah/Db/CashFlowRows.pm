#!/usr/bin/perl -w -CSDA

=begin nd

Package: goah::Db::CashFlowRows

  An database definition for storing cash flow entries.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.
  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Db::CashFlowRows;
use base qw(goah::Db::Object);

use strict;
use utf8;
use warnings;

__PACKAGE__->meta->setup
        (
	table      => 'CashFlowRows',
	columns	   => [ qw(id timestamp module amount related_uids related_companies related_moduleids info longdesc) ],
	pk_columns => 'id',
	unique_key => 'id',
);

1;
