#!/usr/bin/perl -w 

=begin nd

Package: goah::Modules::Personalsettings

  This package is used to manage users personal settings, like
  password and VAT display type.

About: License

  This software is copyritght (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.
 
=cut

package goah::Modules::Personalsettings;

use Cwd;
use Locale::TextDomain ('Personalsettings', getcwd()."/locale");

use strict;
use warnings;
use utf8;
use Encode;

# Let's make this global for the module, hopefully it'll give some speedup
use CGI;


use goah::Modules;

#
# Function: Start
#
#   Start the actual module. Module process is controlled via HTTP
#   variables which are created internally inside the module.
#
# Parameters:
#
#   None
#
# Returns:
#
#   Reference to hash array which contains variables for Template::Toolkit
#   process for the module.
#
sub Start {

	shift;

	my $uid = $_[0];

	my $q = CGI->new();
	my %variables;

	$variables{'module'} = 'Personalsettings';
	$variables{'gettext'} = sub { return __($_[0]); };

	if($q->param('action')) {

		if($q->param('action') eq 'writesettings') {

				if(WriteSettings($uid)==1) {
					goah::Modules->AddMessage('info',__("Personal settings updated."));
				} else {
					goah::Modules->AddMessage('error',__("Can't update personal settings."));
				}

		} else {
				goah::Modules->AddMessage('error',__("Module doesn't have function ")."'".$q->param('action')."'.");
				$variables{'function'} = 'modules/blank';
		}

	}

	$variables{'function'} = 'modules/Personalsettings/settings';
	$variables{'settings'} = ReadSettings($uid);
	$variables{'languages'} = goah::GoaH->ReadLanguages();

	return \%variables;
}


##################################
#
# Modules private functions
#

#
# Function: ReadSettings
#
#   Read all settings for user from database
#
# Parameters:
#
#   uid - User id from database
#
# Returns:
#  
#   Fail - 0 
#   Success - Hash reference to actual data
#
sub ReadSettings {

	if($_[0] && $_[0]=~/goah::Modules::Personalsettings/) {
		shift;
	}

	unless($_[0]) {
		goah::Modules->AddMessage('error',__("Can't read personal settings. User id is missing."),__FILE__,__LINE__);
		return 0;
	}
		
	use goah::Database::Personalsettings;
	my @data = goah::Database::Personalsettings->search_where({ userid => $_[0] });

	my %settings;
	my ($key,$value);
	foreach my $sett (@data) {
	
		$key = $sett->setting;
		$value = $sett->value;

		$settings{$key} = $value;
	}

	return \%settings;
}


#
# Function: WriteSettings
#
#   Write settings from form back to database
#
# Parameters: 
#
#   uid - User id from database
#   
#   Uses HTTP variables as well
#
# Returns:
#
#   Fail - 0 
#   Success - 1
#
sub WriteSettings {

	unless($_[0]) {
		goah::Modules->AddMessage('error',__("Can't write personal settings. User id is missing."));
		return 0;
	}

	my $q = new CGI;

	use goah::Database::Personalsettings;
	use goah::Database::users;

	# Assign setting variables to array so that we can loop trough them
	my @settings = qw/showvat activebasketselect pass1 decimals locale showdebug/;

	# Loop trought settings
	my @data;
	my $tmp;
	my $value;
	foreach my $set (@settings) {
		
		if($set eq 'pass1') {
			if($q->param('pass1') && ($q->param('pass1') eq $q->param('pass2')) ) {
				@data = goah::Database::users->search_where({ accountid => $_[0] });
				$tmp = $data[0];

				use Digest::MD5;
				my $md5 = new Digest::MD5;
				$md5->add($q->param('pass1'));
				$tmp->pass($md5->hexdigest());
				$tmp->update();
				$tmp->commit();
			} elsif($q->param('pass1') || $q->param('pass2')) {
				goah::Modules->AddMessage('error',__("Passwords doesn't match. Won't change password."));
			}
		} else {

			$value = $q->param($set);

			if($set eq 'activebasketselect') {
			
				unless($value=~/^([0-9])+$/ && $value >= 1) {
					$value = 1;
				}
			}

			@data = goah::Database::Personalsettings->search_where( { userid => $_[0],
										  setting => $set });

			if( scalar(@data) == 0 ) {

				goah::Database::Personalsettings->insert( { userid => $_[0],
										setting => $set,
										value => $value
									});
				goah::Modules->AddMessage('debug',"Created new setting $set for uid ".$_[0]);
			} else {
			
				$tmp = $data[0];
				$tmp->value($value);
				$tmp->update();
				$tmp->commit();

				goah::Modules->AddMessage('debug',"Updated setting $set for uid ".$_[0]);
			}
		}

	}
	return 1;
}

1;
