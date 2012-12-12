#!/usr/bin/perl -w 

=begin nd

Package: goah::Modules::CashFlow

  This package is used to manage cash flow calculations and
  data gathering.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.
  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Modules::CashFlow;

use Cwd;
use Locale::TextDomain ('CashFlow', getcwd()."/locale");

use strict;
use warnings;
use utf8;
use Encode;

use goah::Modules::Customermanagement;
use goah::Modules::Productmanagement;

# Hash: submenu
#
#   Submenu definition
#
my %submenu = ( 
		
	);


# Let's make this global for the module, hopefully it'll give some speedup
use CGI;


#
# Function: Start
#
#   Start the actual module. Module process is controlled via HTTP
#   variables which are created internally inside the module.
#
# Parameters:
#
#   0 - ??
#   id - User ID
#   settref - Reference to user settings
#
# Returns:
#
#   Reference to hash array which contains variables for Template::Toolkit
#   process for the module.
#
sub Start {

	$uid = $_[1];
	$settref = $_[2];

	my $q = CGI->new();
	my %variables;

	$variables{'module'} = 'CashFlow';
	$variables{'gettext'} = sub { return __($_[0]); };
	$variables{'submenu'} = \%submenu;

	$variables{'function'} = 'modules/CashFlow/showcashflow';

	use goah::Modules::Personalsettings;
	$variables{'usersettings'} = sub { goah::Modules::Personalsettings::ReadSettings($uid) };

	if($q->param('action')) {

	} else {

	}
		
	return \%variables;
}


1;
