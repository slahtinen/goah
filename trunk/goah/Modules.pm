#!/usr/bin/perl -w

=begin nd

Package: goah::Modules

  This file handles running individual modules and receiving
  notification messages from them. These activities include
  reading menu and passing variables to main program.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.
  See LICENSE and COPYRIGHT -files for full details.

=cut


package goah::Modules;

use strict;
use warnings;
use utf8;

#######################################################################
# Group: Variables
#
#

#
# Array: messages
#
#   Message array for this package. Every module has an access to this
#   table via AddMessage -function. Messages are printed to user via
#   main template.
#
my @messages; 

#
# String: q
#
#   Global CGI instance for this module
#
my $q;

use Cwd;
use Locale::TextDomain ('GoaH', getcwd()."/locale");

#
# Function: ReadTopNavi
#  
#  Function is used to read active modules and their top level navigation.
#  Additionally modules and other functions are grouped so that everything
#  printed into separate "categories".
#
# Parameters:
#
#   uid - User id so that we can check if user has disabled some of the modules
#
# Returns:
#
#   Fail - 0 (applies also if there's no active modules)
#   Success - Hash reference to top menu structure
#
sub ReadTopNavi {

	if($_[0]=~/goah::Modules/) {
		shift;
	}

	# Read active modules first
	my $modref = __PACKAGE__->GetActiveModules();

	my @modules;
	if($modref == 0) {	
		return 0;
	} else {
		@modules = @$modref;
	}

	# Read user settings from the database
	# NOTE: At this point we only check if user has enabled debug mode
	my $debugmode=0;
	if($_[0]) {
		use goah::Modules::Personalsettings;
		my $settref=goah::Modules::Personalsettings->ReadSettings($_[0]);
		if($settref) {
			my %settings=%$settref;
			if($settings{'showdebug'} eq 'on') {
				$debugmode=1;
			}
		}
	}

	# Loop trough modules and assign them to category
	# 'modules' which is hardcoded to navigation template
	my $mod;
	my %modmenu;
	my %topmenu;
	my $sort;
	my $i=100000;
	foreach (@modules) {
		$mod = $_->file;
		
		if($_->sort eq '') {
			$sort = $i+$_->id;
		} else {
			$sort = $i+$_->sort.'.'.$_->id;
		}

		# Hardcoded module to skip depending on debug mode. This will be removed
		# with proper module selection
		if($debugmode == 0 && $mod=~/Sandbox/) {
			next;
		}
		$topmenu{'modules'}{$sort}{'module'} = $mod;
		$topmenu{'modules'}{$sort}{'name'} =__($_->name);
		$i++;
	}

	# Add additional functions
	$topmenu{'settings'}{0}{'module'} = 'Personalsettings';
	$topmenu{'settings'}{0}{'name'} =__("Personal settings");

	$topmenu{'settings'}{1}{'module'} = 'logout';
	$topmenu{'settings'}{1}{'name'} =__("Logout");

	# Return hash reference
	return \%topmenu;
}

#
# Function: GetActiveModules
#
#   Function reads all modules from the database and confirms that they
#   actually do exist. 
#
#   This function can (and will) be modified to respect ACL's as well, but
#   since we don't have any ACL policy we don't need the function either.
#
# Parameters: 
#
#   none
#
# Returns:
#
#   Fail - 0
#   Success - Reference to Class::DBI result set
#
sub GetActiveModules {

	use goah::Database::Modules;
	my @modules = goah::Database::Modules->retrieve_all_sorted_by('sort');

	# We skip check for module existence by now, so the function
	# description isn't really valid.

	if(scalar(@modules) == 0) {
		print "<p class='debug'>".gettext("No modules")."</p>\n";
		return 0;
	} else {
		return \@modules;
	}
}

#
# Function: StartModule
#
#   "Start" an module based on given parameters
#
# Parameters:
#
#   mod - Module name (filename without an extension)
#   uid - User id which is passed to module 
#
# Returns:
#
#  An reference to variables returned by activated
#  module. These are passed quite directly to template
#  toolkit.
#   
sub StartModule {
	my $mod = $_[1];
	my $uid = $_[2];
	my $settref = $_[3];

	require "goah/Modules/".$mod.".pm";
	my $modref = "goah::Modules::$mod"->Start($uid,$settref);
	return $modref;
}


# 
# Function: AddMessage
#
#   Function to add content to GoaH2 message system.
#
# Parameters:
#   level - Message level, debug/error/warn/info
#   content - Actual message
#   file - File, where this function is called. Just use __FILE__
#   line - Line from the file where function is called. Just use __LINE__
#   callerpackage - Package where the function was originally called
#   callerfile - Filename where the function was originally called
#   callerline - Line number of callers filename
#
sub AddMessage {

	my @values=([$_[1],$_[2],$_[3],$_[4],$_[5],$_[6],$_[7]]);
	push (@messages,@values);
	return 1;
}

#
# Function: GetMessages
#
#   Read and return messages from the variable <messages>
#
# Parameters:
#
#   uid - User ID, so that debug messages can be filtered according to user settings
#
# Returns:
#
#   Array which contains various messages from system run
#
sub GetMessages {

	if($_[0]=~/goah::Modules/) {
		shift;
	}

	# Messages -array requires at least 2 items so that it's processed correctly.
	# If there's only one item TT will interpet is an two cell table (0,1) instead of 
	# table of tables (0 => [0,1}).
	__PACKAGE__->AddMessage('','');

	my $debug=0;

	if($_[0]) {
		use goah::Modules::Personalsettings;
		my $settingsref=goah::Modules::Personalsettings->ReadSettings($_[0]);
		if($settingsref != 0) {
			my %tmp = %$settingsref;
			if($tmp{'showdebug'} && $tmp{'showdebug'} eq 'on') {
				$debug=1;
			}
		}
	}

	# If debug messages are disabled then remove them from the array
	if($debug==0) {
		my ($i,$tmp,@tmp2,@tmp3);
		for($i=0;$i<scalar(@messages);$i++) {
			$tmp = $messages[$i];
			@tmp2 = @$tmp;
			unless($tmp2[0] eq 'debug') {
				push(@tmp3,[@tmp2]);	
			}
		}
		@messages=@tmp3;
	}

	return @messages;
}

1;
