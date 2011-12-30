#!/usr/bin/perl -w

package goah::Db;

use strict;
use utf8;
use base qw(Rose::DB);

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


__PACKAGE__->use_private_registry;

__PACKAGE__->register_db(
	driver   => $dbtype,
	database => $dbname,
	host     => $dbserver,
	username => $dbuser,
	password => $dbpass
);

1;

