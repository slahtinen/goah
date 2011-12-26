#!/usr/bin/perl -w 
# -d:DProf

=begin nd

Script: csv.cgi

Enable CSV output from GoaH

About: License

This software is copyright (c) 2009 by Tietovirta Oy and associates.
See LICENSE and COPYRIGHT -files for full details.

=cut

use strict;
use warnings;
use utf8;

use goah::GoaH; # Generic helper functions

my $cref=goah::GoaH->GetConfig;
my %Config=%$cref;

use POSIX;
use lib qw(.);
use CGI::Carp qw(fatalsToBrowser);
use Encode;
use CGI qw(:standard);
use Template;
use goah::Auth;

use Locale::TextDomain ('GoaH', getcwd()."/locale");
setlocale(LC_ALL, 'C');

# Check if default locale is set
use goah::Modules::Systemsettings;
my $locref = goah::Modules::Systemsettings->ReadSetup('locale');
if($locref != 0) {
	my @loc = @$locref;
	setlocale(LC_ALL,$loc[0]->item);
}

#
# String: uid
#   
#   User id
#
my $uid=0;

#
# String: sessid
#
#   Session id
#
my $sessid;

#
# String: auth
#
#   Authentication state. 0=Not authenticated, 1=Authentication ok, -1=Wrong credientials
#
my $auth=0;

#
# String: q
#
#    CGI.pm instance
#
my $q = CGI->new();

# Read information from cookie, and check session id.

# 
# String: keksi
#
#   Authentication cookie to and from user
#
my $keksi = $q->cookie('goah');
if($keksi && length($keksi)>1) {
        my @tmp = split(/\./,$keksi);
        $uid = $tmp[0];
        $sessid = $tmp[1];
        $auth = goah::Auth->CheckSessionid($uid,$sessid);
} 

if($Config{'goah.demomode'} eq 1) {
	$auth=1;
}

# If login isn't valid let's check if user has given login/password information.
# This check is made only if login isn't validated earlier
if($auth == 0) {

	# Check if user has given information and make sure they're not empty
	if($q->param('user') && $q->param('pass')) {
			
		# Tarkistetaan syötetyt tiedot
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

#
# Hash: templatevars
#
#   Variables for template toolkit. This hash contains both
#   global settings and variables from modules.
#
my %templatevars; 

$templatevars{'gettext'} = sub { return __($_[0]); };
$templatevars{'locale'} = setlocale(LC_ALL);
$templatevars{'goahversion'} = '2.0.0 beta';
$templatevars{'demomode'} = $Config{'goah.demomode'};

$auth=1;
# We're logged in to system
if($auth==1) {
	
        print $q->header( -type => 'text/csv',
			  -charset => 'UTF-8',
			  -'content-disposition' => 'attachment; filename=goah.csv');

	use goah::Modules::Personalsettings;
	my $settref = goah::Modules::Personalsettings->ReadSettings($uid);
	my %settings = %$settref;
	unless($settings{'locale'} eq '') {
		setlocale(LC_ALL,$settings{'locale'});
		$templatevars{'locale'} = setlocale(LC_ALL);
	} 

	$templatevars{'page'} = 'main_csv.tt2';
	$templatevars{'uid'} = $uid;

	# Move q->param('action') into own variable
	my $action = '';
	if($q->param('action')) {
		$action = $q->param('action');
		$templatevars{'action'}=$action;
	}

	# goah::Modules contains functions for reading active modules
	# from database and it triggers execution of active modules
	use goah::Modules;

	# If module is selected start it here
	if($q->param('module')) {
		my $modref = goah::Modules->StartModule($q->param('module'),$uid);

		# Process return value from module and assign them into
		# templatevars -hash
		unless($modref == 0) {
			my %mod = %$modref;
	
			my $key;
			my $value;
			while(($key,$value) = each (%mod)) {
				$templatevars{$key} = $value;
			}
		} else {
			goah::Modules->AddMessage('error',"Error with module ".$q->param('module'));
		}
		
	}

} else {
	print "Nothing to display";
	exit;
}

# Create Template, which moves users to login page or in the system
#
# Get path, so we can find template-files
my $templatedef = getcwd().'/templates/'; # Fallback template directory
my $templateinc = getcwd().'/templates/'.$templatevars{'theme'}.'/'; #Overwrite template directory

#
# String: templatevariables
#
#   Reference for <%templatevars> data
#
my $templatevariables = \%templatevars;

#
# String: template
#   
#   Template::Toolkit instance
#
my $template = Template->new( {
			ABSOLUTE => 1,
			INCLUDE_PATH=>[$templateinc,$templatedef],
			POST_CHOMP => 1
			} );
$template->process($templatevars{'page'},$templatevariables) or 
		die "ERR! ".$template->error();

1;
