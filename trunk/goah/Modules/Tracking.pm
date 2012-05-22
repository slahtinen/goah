#!/usr/bin/perl -w 

=begin nd

Package: goah::Modules::Tracking

  This package is used to manage time and travels trakcing

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.
  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Modules::Tracking;

use Cwd;
use Locale::TextDomain ('Basket', getcwd()."/locale");

use strict;
use warnings;
use utf8;
use Encode;
use CGI;

use goah::Modules::Customermanagement;

my %timetrackstatuses = (
	0 => { id => 0, name => __("Normal"), selected => 1, hidden => 0 },
	1 => { id => 1, name => __("Evening"), selected => 0, hidden => 0 },
	2 => { id => 2, name => __("Night"), selected => 0, hidden => 0 }
);

my %timetrackingdb = (
	0 => { field => 'id', name => 'id', type => 'hidden', required => '0' },
	1 => { field => 'companyid', name => __("Customer"), type => 'selectbox', required => '1', data => goah::Modules::Customermanagement->ReadAllCompanies(1) },
	2 => { field => 'userid', name => 'userid', type => 'hidden', required => '1' },
	3 => { field => 'type', name => __('Work type'), type => 'selectbox', required => '1', data => \%timetrackstatuses },
	4 => { field => 'day', name => __('Date'), type => 'textfield', required => '1' },
	5 => { field => 'hours', name => __("Working hours"), type => 'textfield', required => '1' },
	6 => { field => 'description', name => __('Description'),  type => 'textarea', required => '1' },
	7 => { field => 'project', name => __("Project"), type => "textarea", required => '0' },
	8 => { field => 'personnel', name => __("Related personnel"), type => 'textarea', required => '0' },
);


my %submenu = (
);

my $uid;
my $settref;

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

        $variables{'function'} = 'modules/Tracking/timetracking';
        $variables{'module'} = 'Tracking';
        $variables{'gettext'} = sub { return __($_[0]); };
        $variables{'submenu'} = \%submenu;
	$variables{'timetrackingdb'} = \%timetrackingdb;


	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$year+=1900;
	$mon++;
	$variables{'datenow'} = sprintf("%02d.%02d.%04d",$mday,$mon,$year);
	
	if($q->param('action')) {
		
		if($q->param('action') eq 'writenewhours') {
			if(WriteHours($uid)) {
				goah::Modules->AddMessage('info',__("Hours tracked"),__FILE__,__LINE__);
			} else {
				goah::Modules->AddMessage('error',__("Coudln't write hours to database!"),__FILE__,__LINE__);
			}
		} elsif($q->param('action') eq 'writeeditedhours') {
			if(WriteHours($uid)) {
				if($q->param('delete')) {
					goah::Modules->AddMessage('info',__("Time monitoring item removed from the database."),__FILE__,__LINE__);
				} else {
					goah::Modules->AddMessage('info',__("Time monitoring info updated."),__FILE__,__LINE__);
				}
			} else {
				goah::Modules->AddMessage('error',__("Coudln't update information into database!"),__FILE__,__LINE__);
			}

		} elsif($q->param('action') eq 'edithourtracking') {
			$variables{'function'} = "modules/Tracking/edithourtracking";
			$variables{'dbdata'} = ReadData('hours',"id".$q->param('target'));

                } else {
                        goah::Modules->AddMessage('error',__("Module doesn't have function ")."'".$q->param('action')."'.");
                        $variables{'function'} = 'modules/blank';
                }

	}

	if($variables{'function'}=~/modules\/Tracking\/timetracking/) {
		$variables{'latesthours'}=ReadOwnLatesthours($uid);
		$variables{'timetrackstatuses'}=\%timetrackstatuses;
	}
		

	return \%variables;
}


#
# Function: WriteHours 
#
#   Write new/changed hours to tracking database.
#
# Parameters:
#
#    1 - Uid
#    Http parameters
#
# Returns:
#
#    1 - Success
#    0 - Error
#
sub WriteHours {

	shift if ($_[0]=~/goah::Modules::Tracking/);

	use goah::Db::Timetracking;
	my $q = new CGI;

	my %dbdata;

	my $prod;
	my $update=0;
	if($q->param('target')) {
		$prod = goah::Db::Timetracking->new(id => $q->param('target'));
		unless($prod->load(speculative => 1, for_update => 1)) {
			goah::Modules->AddMessage('error',__("Couldn't load data from the database for modifications!"),__LINE__,__FILE__);
			return 0;
		}
		goah::Modules->AddMessage('debug',"Got data with id ".$prod->id." and desc ".$prod->description,__FILE__,__LINE__);
		$update=1;
		if($q->param('delete')) {
			return 1 if $prod->delete;
			goah::Modules->AddMessage('error',__("Couldn't delete item from the database."),__FILE__,__LINE__);
			return 0;
		}
	} else {
		goah::Modules->AddMessage('debug',"No target! '".$q->param('target')."'",__FILE__,__LINE__);
	}

        my %fieldinfo;
        while(my($key,$value) = each (%timetrackingdb)) {
                %fieldinfo = %$value;
                if($fieldinfo{'required'} == '1' && !(length($q->param($fieldinfo{'field'}))) ) {
                        # Using variable just to make source look nicer
                        my $errstr = __('Required field').' <b>'.$fieldinfo{'name'}.'</b> '.__('empty!')." ";
 			goah::Modules->AddMessage('error',$errstr);
			return 0;
                } elsif($fieldinfo{'required'} == '1' && $fieldinfo{'type'} eq 'selectbox' && $q->param($fieldinfo{'field'}) eq "-1") {
                        my $errstr = __('Required dropdown field').' <b>'.$fieldinfo{'name'}.'</b> '.__('unselected!').' ';
                        $errstr.= __("Leaving value unaltered.");
                        goah::Modules->AddMessage('error',$errstr);
			return 0;
                } else {
			if(length($q->param($fieldinfo{'field'}))) {
				my $tmpcol=$fieldinfo{'field'};
				$dbdata{$tmpcol}=(decode('utf-8',$q->param($fieldinfo{'field'})));
				if($fieldinfo{'field'} eq 'hours') {
					my $hours = $q->param($fieldinfo{'field'});
					$hours=~s/,/\./g;
					unless($hours=~/\d+\.?\d+/) {
						goah::Modules->AddMessage('error',__("Hours column not numeric! Setting hours -value to 0!"));
						$dbdata{$tmpcol}=0;
					}
				}	
				$prod->$tmpcol($dbdata{$tmpcol}) if $update;
			}
                }
        }

	$prod = goah::Db::Timetracking->new(%dbdata) unless $update;
	return 1 if ($prod->save);
	return 0;

}

#
# Function: ReadData
#
#   An general read function for the database. This function
#   will handle pretty much all of the general data reading
#
# Parameters:
#
#   type - Which kind of data we're reading, currently only valid format is 'hours'
#   search - Search parameters, currently only accepted format is 'id00', where 00 is an valid database id
#
# Returns:
#   
#   Fail - 0
#   Success - An hash reference with search data
#
sub ReadData {

	shift if ($_[0]=~/goah::Modules::Tracking/);

	unless($_[0]=~/hours/) {
		goah::Modules->AddMessage('debug',"ReadData function called with invalid search parameters",__FILE__,__LINE__);
		return 0;
	}

	unless($_[1]=~/^id/) {
		goah::Modules->AddMessage('debug',"ReadData function called with invalid search parameters",__FILE__,__LINE__);
		return 0;
	}

	my $id=$_[1];
	$id=~s/^id//i;

	use goah::Db::Timetracking;
	my $datap = goah::Db::Timetracking->new(id => $id);
	
	unless($datap->load(speculative => 1)) {
		goah::Modules->AddMessage('error',__("Couldn't read any data from the database with id ").$id,__FILE__,__LINE__);
		return 0;
	}

	my %data;
	my $field;
	foreach my $key (keys %timetrackingdb) {
		$field = $timetrackingdb{$key}{'field'};
		$data{$field} = $datap->$field;	
	}

	return \%data;
}

#
# Function: ReadOwnLatesthours
#
#   An search function to retrieve latest markings from the 
#   hour tracking database for the user to review his work
#   when inserting new hours to database
#
# Parameters:
#
#   uid - User id who's trackings we should read
#
# Retrurns:
#
#   Success - Pointer to hash-variable
#   Fail - 0
#
sub ReadOwnLatesthours {

	shift if ($_[0]=~/goah::Modules::Tracking/);
	
	my $uid = $_[0];
	
	use goah::Db::Timetracking::Manager;
	my $datap = goah::Db::Timetracking::Manager->get_timetracking({ userid => $uid }, sort_by => 'day DESC', limit => 20);
	
	return 0 unless $datap;

	my @data=@$datap;
	# Pack found data into hash and return data
	my %tdata;
	my $i=10000000;
	foreach my $row (@data) {
		my $field;
		foreach my $key (keys %timetrackingdb) {
			$field = $timetrackingdb{$key}{'field'};
			$tdata{$i}{$field} = $row->$field;
			if($field eq 'companyid') {
				use goah::Modules::Customermanagement;
				my $companypointer = goah::Modules::Customermanagement->ReadCompanydata($row->companyid,1);
				unless($companypointer==0) {
					my %compdata = %$companypointer;
					$tdata{$i}{'companyname'}=$compdata{'name'}.' '.$compdata{'firstname'};
				} else {
					$tdata{$i}{'companyname'}=__("Not available!");
				}
			}
		}
		$i++;
	}	

	return \%tdata;
}

1;
