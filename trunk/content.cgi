#!/usr/bin/perl -w

=begin nd

Script: content.cgi

  Helper script to read and print content from the database to
  be used on GoaH2 sites. We use separate script outside index.cgi
  so that it's possible to load partial content to page instead
  of the whole page and make user experience more convinient.

  This script is basically an simplified version of the index.cgi 
  -script and content-type from this is always text/html.

About: License

  This software is copyright (C) 2009 by Tietovirta Oy and associates.  
  See LICENSE and COPYRIGHT -files for full details.

About: More information

  - Website: <http://www.goah.org>

  GoaH project is sponsored by Tietovirta Oy <http://www.tietovirta.fi>

=cut

use strict;
use warnings;
use utf8;
use Encode;

use CGI qw(:standard);
use Template;
use POSIX;

use goah::Auth;

my $q = CGI->new();
print $q->header( -charset => 'UTF-8' );

# Read information from cookie, and check session id. If login
# fails then whole script will stop immediately since we handle
# login process and others directly via index.cgi
my $keksi = $q->cookie('goah');
my $uid;
if($keksi && length($keksi)>1) {
	my @tmp = split(/\./,$keksi);
	$uid = $tmp[0];
	my $sessid = $tmp[1];
	my $auth = goah::Auth->CheckSessionid($uid,$sessid);

	if($auth == 0) {
		print "Not logged in.";
		exit;
	}	
} else {
	print "Not logged in.";
	exit;
}

#
# Check that we have active module as well so that we can actually
# do something meaningful
#
unless($q->param('module')) {
	print "No active module.";
	exit;
}

use goah::Modules::Personalsettings;
my $settref = goah::Modules::Personalsettings->ReadSettings($uid);

use goah::Modules;
my $modref = goah::Modules->StartModule($q->param('module'),$uid,$settref);

# Process return value from module and assign them into
# templatevars -hash
my %templatevars;
unless($modref == 0) {
	my %mod = %$modref;

	my $key;
	my $value;
	while(($key,$value) = each (%mod)) {
		$templatevars{$key} = $value;
	}
} else {
	print "Error with module ".$q->param('module')."\n";
	goah::Modules->AddMessage('error',"Error with module ".$q->param('module'));
}

# Create Template, which moves users to login page or in the system
#
# Get path, so we can find template-files
#use Template::Constants qw( :debug );
$templatevars{'messages'} = sub { goah::Modules::GetMessages($uid); };
$templatevars{'page'} = 'main_content.tt2';
my $templateinc = getcwd().'/templates/';
my $templatevariables = \%templatevars;
my $template = Template->new( {
	ABSOLUTE => 1,
	INCLUDE_PATH=>$templateinc,
	POST_CHOMP => 1
} );
$template->process($templateinc.$templatevars{'page'},$templatevariables) or
			die "ERR! ".$template->error();

1;
