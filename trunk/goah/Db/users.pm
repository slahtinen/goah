#!/usr/bin/perl -w

=begin nd

Package: goah::Db::users

  Db definition for user accounts. Rows store information about actual user
  credientials, an person information it's linked to and data about current session.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut


package goah::Db::users;
use base 'goah::Db';

__PACKAGE__->meta->setup
        (
	table      => 'users',
	columns    => [ qw(id accountid login pass last_active remote_addr session_id, session_active) ],
	pk_columns => 'id',
	unique_key => 'id',
);

1;
