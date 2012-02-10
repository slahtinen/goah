#!/usr/bin/perl -w

=begin nd

Package: goah::Database::users

  Database definition for user accounts. Rows store information about actual user
  credientials, an person information it's linked to and data about current session.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut


package goah::Database::users;
use base 'goah::Database';

__PACKAGE__->table('users');
__PACKAGE__->columns(All => qw/id accountid login pass last_active remote_addr session_id disabled/);  

1;
