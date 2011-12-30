#!/usr/bin/perl -w

package goah::Db::Object;

use goah::Db;

use base qw(Rose::DB::Object);

sub init_db { goah::Db->new }

1;
