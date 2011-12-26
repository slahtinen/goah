#!/usr/bin/perl -w

=begin nd

Package: goah::Database

  Definitions for database connection

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.
  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Database;

use strict;
use warnings;
use utf8;

use base 'Class::DBI';

# Include additional plugins for Class::DBI
use Class::DBI::Plugin::RetrieveAll;
use Class::DBI::AbstractSearch;

use Cwd;

use goah::GoaH;
my $cref=goah::GoaH->GetConfig;
my %Config=%$cref;

#######################################################################
# Group: Variables
#

# 
# String: dbtype
#
#   Defines database type (SQLite, MySQL, PostgreSQL etc)
#
my $dbtype = $Config{'database.type'};

#
# String: dbserver
#
#   Address for database server
#
my $dbserver = 'localhost';

#
# String: dbuser
#
#   Database username
#
my $dbuser = '';

#
# String: dbpass
#
#   Database user's password
#
my $dbpass = '';

#
# String: dbname
#
#   Database name
#
my $dbname = $Config{'database.name'};

if($dbtype=~/sqlite/i && !(-e $dbname)) {
	print "Content-type: text/html\n\n";
	print "<h1>Database file missing! No sqlite file at $dbname, aborting!</h1>\n";
	exit;
}

# Create connection to database. Currently there's no error handling, so system
# will just crash if connection is unavailable
__PACKAGE__->connection("dbi:$dbtype:dbname=$dbname",$dbuser,$dbpass);


1;
