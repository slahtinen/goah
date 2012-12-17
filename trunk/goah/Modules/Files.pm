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
use Try::Tiny;

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
			2  => 'target_id',
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
#   0 - target_id:	Id to identify request. Search multiple rows.
#   1 - int_filename: 	Internal filename
#
#
# Returns:
#
#   Hashref which contains selected database rows
#

sub GetFileRows {

	shift if($_[0]=~/goah::Modules::Files/);
	my @vars = @_;
	my $target_id = $_[0];
	my $int_filename = $_[1];
	my %dbdata;

	use goah::Db::Files::Manager;

	if (($int_filename) || ($target_id) ) {

		my $frow_ref;

		if (($int_filename) && !($target_id)) {
        		$frow_ref = goah::Db::Files::Manager->get_files( query => [ int_filename => "$int_filename" ] );
        		my @frow = @$frow_ref;

			my $dbrow;
			foreach $dbrow (@frow) {
				while (my ($key, $value) = each(%filesdbfieldnames)) {
					$dbdata{$value} = $dbrow->{$value};
				}
			}
			unless ($dbdata{'int_filename'}) {
				return 0;
			}
		}

		if (($target_id) && !($int_filename)) {
        		$frow_ref = goah::Db::Files::Manager->get_files( query => [ target_id => "$target_id" ] );
        		my @frow = @$frow_ref;

			my $dbrow;
			my $counter = 10000;
			foreach $dbrow (@frow) {
				while (my ($key, $value) = each(%filesdbfieldnames)) {
					if ($dbrow->int_filename) {
						$dbdata{$counter}{$value} = $dbrow->{$value};
					}
				}

				unless ($dbrow->int_filename) {
					return 0;
				}
				$counter++;
			}

			# Debugging
			# use CGI;
			# my $q = new CGI;
			# print $q->header();
			#die print @frow;
			# foreach (keys %dbdata) {
			#	if ($dbdata{$_}->{'id'} > 0) {
			#		print $dbdata{$_}->{'id'}."<br />";
			#	}
			# }
		}

	}

return (\%dbdata);
}

1;








