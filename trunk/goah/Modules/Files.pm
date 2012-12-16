#!/usr/bin/perl -w

=begin nd

Package: goah::Modules::Files

  Module to manage file actions

About: License

  This software is copyritght (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Modules::Files;

use Cwd;
use Locale::TextDomain ('Files', getcwd()."/locale");

use strict;
use warnings;
use utf8;
use Encode;

#
# String: module
#
#   Defines module internal name to be used in control flow
my $module='Files';

#
# Hash: filesdbfieldnames 
#
#   Database structure in a hash. Via this it's possible to
#   create simple function for database queries
#

my %filesdbfieldnames = (
			0  => 'id',
			1  => 'userid',
			2  => 'moduleid',
			3  => 'date',
			4  => 'mimetype',
			5  => 'md5',
			6  => 'datadir',
			7  => 'int_filename',
			8  => 'orig_filename',
			9  => 'status',
			10 => 'public',
			11 => 'expires',
			12 => 'downloads',
			13 => 'info',
			14 => 'module'
);

#
# Function: GetFileRows
#
# Module process is controlled with variables which
# are passed from another module or files.cgi as hashref. 
#
# Parameters:
#
#   Variables from module or files.cgi.
#
#   Required
#
#   At least One of these variables should be given.
#
#   0 - Moduleid to identify request (moduleid field from database)
#   1 - Internal filename (int_filename from database)
#
#
# Returns:
#
#   Hashref which contains selected database rows
#

sub GetFileRows {

	shift if($_[0]=~/goah::Modules::Files/);
	my @vars = @_;
	my $moduleid = $_[0];
	my $int_filename = $_[1];
	my %dbdata;

	use goah::Db::Files::Manager;

	# Get one row (searched with filename)
	if ($int_filename) {
        	my $frow_ref = goah::Db::Files::Manager->get_files( query => [ int_filename => "$int_filename" ] );
        	my @frow = @$frow_ref;
		
		# Just for debugging
		# use CGI;
		# my $q = new CGI;
		# print $q->header();

		my $dbrow;
		foreach $dbrow (@frow) {
			while (my ($key, $value) = each(%filesdbfieldnames)) {
				$dbdata{$value} = $dbrow->{$value};
			}
		}

	return (\%dbdata);
	}

}

1;








