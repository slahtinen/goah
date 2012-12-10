#!/usr/bin/perl -w -CSDA

=begin nd

Package: goah::Db::Email

  An database definition for storing tasks.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.
  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Db::Email;
use base qw(goah::Db::Object);

use strict;
use utf8;
use warnings;

__PACKAGE__->meta->setup
        (
	table      => 'Email',
	columns	   => [ qw(id userid messageid type timestamp delivered sender recipient cc bcc subject body attachments) ],
	pk_columns => 'id',
	unique_key => 'id',
);


1;
