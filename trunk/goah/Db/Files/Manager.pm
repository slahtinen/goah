#!/usr/bin/perl -w -CSDA

=begin nd

Package: goah::Database::Files::Manager

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.
  See LICENSE and COPYRIGHT -files for full details.

=cut

use strict;
use utf8;
use warnings;

package goah::Db::Files::Manager;
use base qw(Rose::DB::Object::Manager);

sub object_class { 'goah::Db::Files' };

__PACKAGE__->make_manager_methods('files');

1;
