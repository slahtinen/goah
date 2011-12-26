#!/usr/bin/perl -w -CSDA

=begin nd

Package: goah::Modules::Sandbox

  Module to take care of external scripts for GoaH test and development.

About: License

  This software is copyritght (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Modules::Sandbox;

use Cwd;
use Locale::TextDomain ('Sandbox', getcwd()."/locale");

use strict;
use warnings;
use utf8;
use Encode;

#
# String: module
#
#   Defines module internal name to be used in control flow
my $module='Sandbox';

#
# Hash: submenu
#
#   Defines sumenu items for the module
#
my %submenu;

#
# Function: Start
#
# Start the actual module. Module process is controlled via HTTP
# variables which are created internally inside the module.
#
# Parameters:
#
#   None
#
# Returns:
#
#   Hash containing relevant bits for frameset generation
#
sub Start {

	GetSubmenu();
	my %variables;

	$variables{'function'} = 'modules/Sandbox/sandbox';
	$variables{'module'} = $module;
	$variables{'gettext'} = sub { return __($_[0]); };
	$variables{'submenu'} = \%submenu;

	use CGI;
	my $q = new CGI;
	
	use Cwd;
	my $dir=getcwd()."/external";
	if($q->param('action')) {

		my $a = $q->param('action');
		if(-d "$dir/$a" ) {
			$dir = $dir."/".$a;
		}
		$variables{'dir'} = $a;

	} 

	# Read files in desired directory
	opendir(D,$dir) or die("Can't open dir $dir!");
	my @files;
	while (my $f=readdir(D)) {
		unless ( -d "$dir/$f" ) {
			if($variables{'dir'}) {
				push(@files,$variables{'dir'}."/".$f);
			} else {
				push(@files,$f);
			}
		}
	}

	$variables{'files'}=\@files;
	
	return \%variables;
}


#
# Function: GetSubmenu
#
#  Read submenu based on directories under external scripts
#
# Parameters: 
#
#  None
#
# Returns: 
#   
#  Always 1, actual data is stored to module wide hash %submenu 
#
sub GetSubmenu {

	use Cwd;
	my $dir = getcwd()."/external";
	my $n=0; # Simple counter for menu items

	opendir(D,$dir) or die("Can't read dir $dir!");

	while (my $f=readdir(D)) {

		if (-d "$dir/$f" ) {
			unless ($f eq '..' || $f eq '.') {
				goah::Modules->AddMessage('debug',"Added dir $f");
				$submenu{$n}=({ title => "$f/", action => $f })
			}
		}
	}

	return 1;
}

1;
