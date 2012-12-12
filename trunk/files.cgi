#!/usr/bin/perl -w

=begin nd

Script: files.cgi

  An script to handle file managemen from GoaH. Basically this script
  is an modified version of index.cgi -file.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.
  See LICENSE and COPYRIGHT -files for full details.

About: TODO

  Currently this file only creates PDF documents for invoices. Basic
  functionality to include referrals and other documents is built but
  it's currently disabled.

=cut


use CGI::Carp qw(fatalsToBrowser);

use strict;
use warnings;
use utf8;

use CGI qw(:standard);
use Template;

use lib qw(.);
use goah::Auth;

use POSIX;

use Locale::TextDomain ('GoaH', getcwd()."/locale");

my $uid=0;
my $sessid;
my $auth=0;

my $q = new CGI;

# Read information from cookie, and check session id.
my $cookie = $q->cookie('goah');
if($cookie && length($cookie)>1) {
        my @tmp = split(/\./,$cookie);
        $uid = $tmp[0];
        $sessid = $tmp[1];
        $auth = goah::Auth->CheckSessionid($uid,$sessid);
} 

# If login isn't valid let's check if user has given login/password information.
# This check is made only if login isn't validated earlier
if($auth == 0) {

	# Check if user has given information and make sure they're not empty
	if($q->param('user') && $q->param('pass')) {
			
		# Check input values
		$uid = goah::Auth->CheckLogin($q->param('user'),$q->param('pass'));
		if($uid!=0) {
			$auth=1; # Login ok
		} else {
			$auth=-1; # Incorrect username/password
		}
	} elsif($q->param('user') || $q->param('pass') ) {
		$auth=-1;
	}

}

$auth=1;

# We're logged in to system
if($auth==1) {

        my %params;
        $params{'gettext'} = sub { return __($_[0]); };
        $params{'userid'} = $uid;
        $params{'module'} = $q->param('module');
        $params{'file'} = $q->param('file');
        $params{'info'} = $q->param('info');
        $params{'action'} = $q->param('action');

	# Read data directory
	use goah::Modules::Systemsettings;
 	my $tmp_dir = goah::Modules::Systemsettings->ReadSetup('files_datadir',1);

	my %dir;
	if ($tmp_dir) {%dir=%$tmp_dir;}

        $params{'dir'} = $dir{'value'};

        if ($params{'action'} eq 'upload') {
                FileUpload(\%params);
        }

	#
	# Function: FileUpload
	#
	# Module for file upload. Process is controlled with hash-variables
	# which are passed as hashref from another module.
	#
	# Parameters:
	#
	#   Hashref
	#
	#   Required
	#
	#   userid - User id of user who made upload
	#   file - Filename
	#   module - Module id
	#
	# Returns:
	#
	#   1 for success
	#

	sub FileUpload {

        	my %vars = %{$_[0]};
		my $upload_fh = $q->upload("file");

		# Check does module have directory
		unless (-e $vars{'dir'}.'/'.$vars{'module'}){
			mkdir $vars{'dir'}.'/'.$vars{'module'} or die "$!";
		}

		open ( UPFILE, ">$vars{'dir'}/$vars{'module'}/$vars{'file'}" ) or die "$!";
		binmode UPFILE;

		while ( <$upload_fh> ) {
			print UPFILE;
		}

		close UPFILE;
	
		print header( -charset => 'UTF-8');	
		
		# Debugging, should be removed
		my ($key, $value);
		while (($key, $value) = each(%vars)) {
			print "$key "."$value"."<br />";
		}
	}	

} else {
	# Normal login
	print header( -charset => 'UTF-8');
	print "<h1>NOT LOGGED IN!</h1>\n";
}

1;


