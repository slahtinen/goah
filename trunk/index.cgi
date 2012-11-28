#!/usr/bin/perl -w 
##!/usr/bin/perl -w -d:NYTProf
# -d:DProf

=begin nd

Script: index.cgi

"Master" file to trigger pretty much everything trough
GoaH processing. File contains functionality for use login 
and cookie management. Functionality is controlled by HTTP 
-variables.

If user hasn't logged in login form is displayed, and if users login
is valid production interface is shown.

About: License

This software is copyright (c) 2009 by Tietovirta Oy and associates.
See LICENSE and COPYRIGHT -files for full details.

About: More information

- Website: <http://www.goah.org>

GoaH project is sponsored by Tietovirta Oy <http://www.tietovirta.fi>

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
# String: theme
#
#   Theme
my $theme;

#
# String: viewport
#
#   Users viewport (currently desktop or tablet)
my $viewport;

#
# String: loginperiod
#
# Login period to store in the cookie
my $loginperiod;

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
        $theme = $tmp[2];
        $auth = goah::Auth->CheckSessionid($uid,$sessid);
} 

# 
# String: viewcookie
#
#  Viewport cookie from login. This is used to switch GongoUI theme
#	between desktop/tablet layouts.
#
my $viewcookie = $q->cookie('viewport');
if($viewcookie && length($viewcookie)>1) {
        my @vtmp = split(/\./,$viewcookie);
        $viewport = $vtmp[0];
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
		} elsif($uid==-1) {
			$auth=-2;
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
$templatevars{'goahversion'} = '2.1.0 beta';
$templatevars{'demomode'} = $Config{'goah.demomode'};

# Store users viewport information to switch between GongoUI desktop or tablet modes
$templatevars{'viewport'} = $viewport;

# Read theme from login, or use one from cookie. Get fallback from config.
if ($q->param('theme')) {
		$templatevars{'theme'} = $q->param('theme');
} elsif (length($theme) > 1) {
		$templatevars{'theme'} = $theme;
} else {
		$templatevars{'theme'} = $Config{'goah.theme'};
}


# We're logged in to system
if($auth==1) {

	use goah::Modules::Personalsettings;
	my $settref = goah::Modules::Personalsettings->ReadSettings($uid);
	my %settings = %$settref;
	unless($settings{'locale'} eq '') {
		setlocale(LC_ALL,$settings{'locale'});
		$templatevars{'locale'} = setlocale(LC_ALL);
	} 

	# Create new (renew) session id
	$sessid = goah::Auth->CreateSessionid($uid);
	
	# Move q->param('action') into own variable
	my $action = '';
	if($q->param('action')) {
		$action = $q->param('action');
		$templatevars{'action'}=$action;
	}

	if($sessid=~/^([0-9])+$/ && $sessid==-1) {
		$action='disabled';

		$keksi = cookie ( -name => 'goah', -value => '0', -expires => '0' );
		$viewport = cookie ( -name => 'viewport', -value => '0', -expires => '0' );
		$templatevars{'page'} = 'login.tt2';
		$templatevars{'function'} = 'accountdisabled';

	} else {
		# Read users login period
		$loginperiod = $q->param('loginperiod');

		# Create cookie which has only one value. Value is assembled
		# by combining userid, session id and theme with a dot.
		$keksi = $q->cookie ( -name => 'goah',
				  -value => $uid.'.'.$sessid.'.'.$templatevars{'theme'},
				  -expires => '+'.$loginperiod.'h');
				  

		$templatevars{'page'} = 'main.tt2';
		$templatevars{'uid'} = $uid;


		# Make an extra check so that logout works as it should
		if($q->param('module') && $q->param('module') eq 'logout') {
			$action = 'logout';
		}

		# Check if user want's to log out
		if ($action eq 'logout') {

			# Destroy session from database
			goah::Auth->DestroySessionid($uid);

			$keksi = cookie ( -name => 'goah',
					  -value => '0',
					  -expires => '0');
					  
			$viewport = cookie ( -name => 'viewport',
					  -value => '0',
					  -expires => '0');
					  
			$templatevars{'page'} = 'login.tt2';
			$templatevars{'function'} = 'logout';
		}
	}

	print header( -cookie => $keksi,
		      -charset => 'UTF-8');

	# Check that information isn't processed if there's no
	# need for that
	unless ($action eq 'logout' || $action eq 'disabled') {

		# goah::Modules contains functions for reading active modules
		# from database and it triggers execution of active modules
		use goah::Modules;

		# Do the 'cron'-ish run for recurring baskets. Further on, if
		# there's more of this kind of functions I suppose we should
		# build someting more sophisticated for this, but for now this
		# should do.
		my $cronp = goah::Modules::Systemsettings->ReadSetup('runcron');
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
		my $runcron=0;
		unless($cronp eq "0") {
			my @cronarr=@$cronp;
			my $cron=$cronarr[0];
			my $datetxt=$cron->value;
			my @date=split("-",$datetxt);
		
			if($date[0] < $year+1900) {
				$runcron=1;
			}

			if($runcron==0 && $date[1] < $mon+1) {
				$runcron=1;
			}

			if($runcron==0 && $date[2] < $mday) {
				$runcron=1;
			}

		} else {
			$runcron=1;
		}

		if($runcron) {
			goah::Modules->AddMessage('info',__("Cron process triggered"));
			goah::Modules::Systemsettings->WriteSetupInt('runcron',sprintf("%04d-%02d-%02d",$year+1900,$mon+1,$mday));
			use goah::Modules::Basket;
			goah::Modules::Basket->RunCron();
		} else {
			#goah::Modules->AddMessage('debug',__("Cron process already ran for today"));
		}

		# 
		#  Read navigation first to variable and assign TT-variable 
		#  via that. If ReadTopNavi is assigned directly to TT there'll
		#  be several database queries when navigation is constructed
		#  on HTML-document
		#
		my $topmenu = goah::Modules->ReadTopNavi($uid);

		$templatevars{'navi'} = $topmenu;

		# If module is selected start it here. If there's no module selected, then start Basket
		# as default module.
		my $module="Basket";
		$module=$q->param('module') if ($q->param('module'));
		my $modref = goah::Modules->StartModule($module,$uid,$settref);
		
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
		
		$templatevars{'messages'} = sub { goah::Modules::GetMessages($uid); };

	}

} elsif( $auth == -1) {
	# User has given faulty login information, assign
	# proper template and information in templatevars -hash
	print header( -charset => 'UTF-8');
	$templatevars{'page'} = 'login.tt2';
	$templatevars{'function'} = 'wronglogin';
} elsif( $auth == -2) {
	print header( -charset => 'UTF-8');
	$templatevars{'page'} = 'login.tt2';
	$templatevars{'function'} = 'accountdisabled';
} else {
	# Normal login
	print header( -charset => 'UTF-8');
	$templatevars{'page'} = 'login.tt2';
	$templatevars{'messages'} = \&goah::Modules::GetMessages;	
}


#
# Browser version check
#
if($ENV{'HTTP_USER_AGENT'}=~/msie (\d)/) {
	if($1<7) {
		$templatevars{'page'}='oldbrowser.tt2';
	}
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
