#!/usr/bin/perl -w -CSDA

=begin nd

Package: goah::Database::Referralrows::Manager

  This module uses Rose::DB instead of Class::DBI, which should speed up
  the process.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut

use strict;
use utf8;
use warnings;

package goah::Db::Referralrows::Manager;
use base qw(Rose::DB::Object::Manager);

sub object_class { 'goah::Db::Referralrows' };

__PACKAGE__->make_manager_methods('referralrows');

1;
