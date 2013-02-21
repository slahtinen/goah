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
use Locale::TextDomain ('Tracking', getcwd()."/locale");

use strict;
use warnings;
use utf8;
use Encode;
use CGI;

use goah::Modules::Customermanagement;

my $uid;
my $settref;

my %timetrackstatuses;
my %timetrackingdb;

my %submenu = (
	0 => { title => __("Reporting"), action => 'reporting' }
);

#
# Function InitVars
#
#   Initialize variables required for processing. This is required so
#   that the process doesn't attempt to access functions without proper
#   information
#
# Parameters:
#   
#   None
#
# Return:
#
#   Always 0
#
sub InitVars {

	%timetrackstatuses = (
		0 => { id => 0, name => __("Normal"), selected => 1, hidden => 0 },
		1 => { id => 1, name => __("Evening"), selected => 0, hidden => 0 },
		2 => { id => 2, name => __("Night"), selected => 0, hidden => 0 },
		3 => { id => 3, name => __("Other"), selected => 0, hidden => 0 },
	);

	%timetrackingdb = (
		0 => { field => 'id', name => 'id', type => 'hidden', required => '0' },
		1 => { 
			field => 'companyid', 
			name => __("Customer"), 
			type => 'selectbox', 
			required => '1', 
			data => goah::Modules::Customermanagement->ReadAllCompanies(1) 
		},
		2 => { field => 'userid', name => 'userid', type => 'hidden', required => '1' },
		3 => { field => 'type', name => __('Work type'), type => 'selectbox', required => '1', data => \%timetrackstatuses },
		4 => 	{ 	field => 'productcode', 
				name => __('Product'), 
				type => 'selectbox', 
				required => '1', 
				data => goah::Modules::Productmanagement->ReadProductsByGrouptype(1,$uid) },
		5 => { field => 'day', name => __('Date'), type => 'textfield', required => '1' },
		6 => { field => 'hours', name => __("Working hours"), type => 'textfield', required => '1' },
		7 => { field => 'inthours', name => __("Internal hours"), type => 'textfield', required => '0' },
		8 => { field => 'description', name => __('Description'),  type => 'textarea', required => '1' },
		#8 => { field => 'project', name => __("Project"), type => "textarea", required => '0' },
		#9 => { field => 'personnel', name => __("Related personnel"), type => 'textarea', required => '0' },
		9 => { field => 'project', name => __("Project"), type => "hidden", required => '0' },
		91 => { field => 'personnel', name => __("Related personnel"), type => 'hidden', required => '0' },
		#92 => { field => 'no_billing', name => __("Internal"), type => 'checkbox', required => '0' },
		93 => { field => 'basket_id', name => __("Imported to basket"), type => 'checkbox', required => '0' },
		94 => { 
			field => 'longdescription', 
			name => __("Long description, only for internal use"), 
			type => "textarea", 
			required => 0 
		},
		
	);

	return 0;
}



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

	unless(scalar(keys(%timetrackingdb)) || scalar(keys(%timetrackstatuses)) ) {
		InitVars();
	}

        $variables{'function'} = 'modules/Tracking/timetracking';
        $variables{'module'} = 'Tracking';
        $variables{'gettext'} = sub { return __($_[0]); };
        $variables{'submenu'} = \%submenu;
	$variables{'timetrackingdb'} = \%timetrackingdb;


	# Helper variables to generate an selectbox for search parameters on reporting
	$variables{'yesnoselect'} = { 	0 => { key => 'yesno', value => __("All hours") },
					1 => { key => 'yes', value => __("Only debit hours") },
					2 => { key => 'no', value => __("Only internal hours") } };
	$variables{'debitselect'} = { 	0 => { key => 'unimported', value => __("Only not imported hours") },
					1 => { key => 'imported', value => __("Only imported hours") },
					2 => { key => 'all', value => __("All hours") } };
	
	my ($sec,$min,$hour,$mday,$mon,$yearnow,$wday,$yday,$isdst) = localtime(time);
	$yearnow+=1900;
	$mon++;
	$variables{'datenow'} = sprintf("%02d.%02d.%04d",$mday,$mon,$yearnow);
	
	if($q->param('action')) {
		
		if($q->param('action') eq 'writenewhours') {
			if(WriteHours($uid)) {
				goah::Modules->AddMessage('info',__("Hours tracked"),__FILE__,__LINE__);
			} else {
				goah::Modules->AddMessage('error',__("Couldn't write hours to database!"),__FILE__,__LINE__);
			}
		} elsif($q->param('action') eq 'writeeditedhours') {
			if(WriteHours($uid)) {
				if($q->param('delete')) {
					goah::Modules->AddMessage('info',__("Time monitoring item removed from the database."),__FILE__,__LINE__);
				} else {
					goah::Modules->AddMessage('info',__("Time monitoring info updated."),__FILE__,__LINE__);
				}
			} else {
				goah::Modules->AddMessage('error',__("Couldn't update information into database!"),__FILE__,__LINE__);
			}
			if($q->param('fromreporting')) {
				$variables{'function'} = "modules/Tracking/reporting";
				$variables{'dbdata'}=ReadHours('','','','','yes','unimported');
				$variables{'dbcompanies'}=goah::Modules::Customermanagement->ReadAllCompanies(1);
				$variables{'dbusers'}=goah::Modules::Systemsettings->ReadOwnerPersonnel();
				$variables{'timetrackstatuses'}=\%timetrackstatuses;
			}

		} elsif($q->param('action') eq 'edithourtracking') {
			$variables{'function'} = "modules/Tracking/edithourtracking";
			$variables{'dbdata'} = ReadData('hours',"id".$q->param('target'));
			$variables{'fromreporting'}=$q->param('fromreporting') if($q->param('fromreporting'));

		} elsif($q->param('action') eq 'reporting') {
			$variables{'function'} = "modules/Tracking/reporting";
			$variables{'dbdata'} = ReadHours('all','all');
			$variables{'dbcompanies'}=goah::Modules::Customermanagement->ReadAllCompanies(1);
			$variables{'dbusers'}=goah::Modules::Systemsettings->ReadOwnerPersonnel();
			$variables{'timetrackstatuses'}=\%timetrackstatuses;

			# Get data for actual search, or if no parameters are given, search for hours
			# at current month
			if($q->param('subaction') && $q->param('subaction') eq 'search' && !($q->param('submit-reset'))) {
				my $company;
				my $uid;
				my $startdate;
				my $enddate;
				my $searchdatestart;
				my $searchdateend;
				my $yesnoselect='yes';
				my $debitselect;

				$company = $q->param('customer') if($q->param('customer') && !($q->param('customer')=~/\*/) );
				$uid = $q->param('user') if($q->param('user'));
				$startdate = $q->param('fromdate') if($q->param('fromdate'));
				$enddate = $q->param('todate') if($q->param('todate'));
				$yesnoselect = $q->param('yesnoselect') if($q->param('yesnoselect'));
				$debitselect = $q->param('debitselect') if($q->param('debitselect'));
				
				if(length($startdate)) {
					unless($startdate=~/[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{4}/ || $startdate=~/[0-9]{1,2}\.[0-9]{1,2}/) {
						goah::Modules->AddMessage('error',__("Start date isn't formatted correctly. Ignoring filter."));
						$startdate='';
					} else {
						my @searchdate=split(/\./,$startdate);

						$searchdate[2]=$yearnow unless($searchdate[2]);

						$searchdatestart=sprintf("%04d-%02d-%02d",$searchdate[2],$searchdate[1],$searchdate[0]);
						$startdate=sprintf("%02d.%02d.%04d",@searchdate);
					}
				} 

				if(length($enddate)) {
					unless($enddate=~/[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{4}/ || $enddate=~/[0-9]{1,2}\.[0-9]{1,2}/) {
						goah::Modules->AddMessage('error',__("End date isn't formatted correctly. Ignoring filter."));
						$enddate='';
					} else {
						my @searchdate=split(/\./,$enddate);

						$searchdate[2]=$yearnow unless($searchdate[2]);

						$searchdateend=sprintf("%04d-%02d-%02d",$searchdate[2],$searchdate[1],$searchdate[0]);
						$enddate=sprintf("%02d.%02d.%04d",@searchdate);
					}
				}

				$variables{'dbdata'}=ReadHours($uid,$company,$searchdatestart,$searchdateend,$yesnoselect,$debitselect);
				$variables{'search_customer'}=$company;
				$variables{'search_owners'}=$uid;
				$variables{'search_startdate'}=$startdate;
				$variables{'search_enddate'}=$enddate;
				$variables{'search_yesnoselect'}=$yesnoselect;
				$variables{'search_debitselect'}=$debitselect;
				$variables{'search_longdesc'}='checked' if($q->param('search_longdesc'));

			} else {
				#$variables{'dbdata'}=ReadHours('','',sprintf("%04d-%02d-%02d",$yearnow,$mon,'01'),'','','unimported');
				$variables{'dbdata'}=ReadHours('','','','','yes','unimported');
			}

                } else {
                        goah::Modules->AddMessage('error',__("Module doesn't have function ")."'".$q->param('action')."'.");
                        $variables{'function'} = 'modules/blank';
                }

	}

	if($variables{'function'}=~/modules\/Tracking\/timetracking/) {
		#$variables{'latesthours'}=ReadHours($uid,'',$year.'-'.$mon.'-01');
		$variables{'latesthours'}=ReadHours($uid,'','-20','');
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

	my $trackingitem;
	my $update=0;

	# Check if we're updating an existing item or creating a new one
	if($q->param('target')) {
		$trackingitem = goah::Db::Timetracking->new(id => $q->param('target'));
		unless($trackingitem->load(speculative => 1, for_update => 1)) {
			goah::Modules->AddMessage('error',__("Couldn't load data from the database for modifications!"),__LINE__,__FILE__);
			return 0;
		}
		goah::Modules->AddMessage('debug',"Got data with id ".$trackingitem->id." and desc ".$trackingitem->description,__FILE__,__LINE__);
		$update=1;
		if($q->param('delete')) {
			return 1 if $trackingitem->delete;
			goah::Modules->AddMessage('error',__("Couldn't delete item from the database."),__FILE__,__LINE__);
			return 0;
		}
	}


	# Initialize database variables if they're missing
	unless(scalar(keys(%timetrackingdb)) || scalar(keys(%timetrackstatuses)) ) {
		InitVars();
	}

	# Update values to an array from http variables
        my %fieldinfo;
	my $forcedtype=0; # Helper variable to keep forced row type when it's automatically corrected from user input
        while(my($key,$value) = each (%timetrackingdb)) {
                %fieldinfo = %$value;
                if($fieldinfo{'required'} == '1' && !(length($q->param($fieldinfo{'field'}))) && !($fieldinfo{'field'} eq 'hours') ) {

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
			if(length($q->param($fieldinfo{'field'})) || $fieldinfo{'field'} eq 'hours' || $fieldinfo{'type'} eq 'checkbox') {
				my $tmpcol=$fieldinfo{'field'};

				if($tmpcol eq 'type' && $forcedtype) {
					goah::Modules->AddMessage('debug',"Forcedtype enabled, won't alter type field again!");
					next;
				}
				
				$dbdata{$tmpcol}=(decode('utf-8',$q->param($fieldinfo{'field'})));

				if($fieldinfo{'field'} eq 'hours') {

					# Read product information so that we can separate between time and
					# other types
					unless($q->param('productcode')) {
						my $msg=__("Can't add tracked hours to database! Product code is missing!");
						goah::Modules->AddMessage('error',$msg,__FILE__,__LINE__);
						return 0;
					}
					my $prodinfo_p = goah::Modules::Productmanagement->ReadData('products',$q->param('productcode'),$uid,$settref,1);
					unless($prodinfo_p) {
						my $msg=__("Can't read product data from the database! Can't add tracked hours!");
						goah::Modules->AddMessage('error',$msg,__FILE__,__LINE__);
						return 0;
					}
					my %prodinfo=%$prodinfo_p;

					if($prodinfo{'unit'}=~/^h/) {

						my $hours = $q->param($fieldinfo{'field'});
						$hours=~s/,/\./g;
						my $fhours = $hours; # Helper varible to check if we should include minutes-field in time

						if($hours=~/:/) {
							my @hoursarr=split(/:/,$hours);
							my $tmphours=$hoursarr[1]/60;
							$tmphours+=$hoursarr[0];
							$hours=$tmphours;
						} elsif(!$hours=~/\d+\.?\d*/) {
							goah::Modules->AddMessage('debug',__("Hours column not numeric! Setting hours -value to 0!"),__FILE__,__LINE__);
							$hours=0;
						}

						
						if($q->param('minutes')>0 && !($fhours=~/:/) && !($fhours=~/\./) ) {
							$hours+=$q->param('minutes')/60;
						}
						$dbdata{$tmpcol}=$hours;

					} else {
						
						unless($q->param('amount') && $q->param('amount')=~/^\d+\.?\d*/) {
							goah::Modules->AddMessage('error',__("Amount column not numeric! Setting amount -value to 0!"));
							$dbdata{$tmpcol}=0;
						} else {
							$dbdata{$tmpcol}=$q->param('amount');
						}

						if($dbdata{'type'} ne 3) {
							my $msg="Tracked type not 'other' even if given value isn't hours and minutes! ";
							$msg.="Forcing type to 3";
							goah::Modules->AddMessage('debug',$msg,__FILE__,__LINE__);
							$dbdata{'type'}=3;
							$forcedtype=1;
						}
					}
				}	

				# Record internal hours, these will be included no matter what the tracking type is
				if($fieldinfo{'field'} eq 'inthours') {

					my $hours=$q->param($fieldinfo{'field'});
					$hours=~s/,/\./g;
					my $fhours=$hours; # Helper variable for checking if we should include minutes-field in total time

					if($hours=~/:/) {
						my @hoursarr=split(/:/,$hours);
						my $tmphours=$hoursarr[1]/60;
						$tmphours+=$hoursarr[0];
						$hours=$tmphours;
					} elsif(!$hours=~/\d+\.?\d*/) {
						goah::Modules->AddMessage('warn',__("Hours column not numeric! Setting hours -value to 0!"));
						$hours=0;
					}

					if($q->param('intminutes')>0 && !($fhours=~/:/) && !($fhours=~/\./) ) {
						$hours+=$q->param('intminutes')/60;
					}
					$dbdata{$tmpcol}=$hours;
				}

				if($fieldinfo{'field'} eq 'day') {
					my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
					$year+=1900;    
					$mon++; 

					if($q->param('day')=~/[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{4}/) {
						$dbdata{$tmpcol}=goah::GoaH::FormatDate($q->param('day')." 00:00:01");
					} elsif($q->param('day')=~/[0-9]{1,2}\.[0-9]{1,2}/) {
						$dbdata{$tmpcol}=goah::GoaH::FormatDate($q->param('day').".".$year." 00:00:01");
					} else {
						goah::Modules->AddMessage('warn',__("Incorrectly formatted date!  Using current date."),__LINE__,__FILE__);
						$dbdata{$tmpcol}=sprintf("%04d-%02d-%02d",$year,$mon,$mday);
					}

				}

				if($fieldinfo{'type'} eq 'checkbox') {
					if($q->param($tmpcol) eq 'on') {
						if($fieldinfo{'field'} eq 'basket_id') {
							$dbdata{$tmpcol}=-1;
						} else {
							$dbdata{$tmpcol}=1;
						}
					} else {
						$dbdata{$tmpcol}=0;
					}
				}

				# Update existing tracking item
				$trackingitem->$tmpcol($dbdata{$tmpcol}) if $update;
			}
                }
        }

	# Create new tracking item
	$trackingitem = goah::Db::Timetracking->new(%dbdata) unless $update;
	return 1 if ($trackingitem->save);
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
#   formattime - If we should recalculate hours field to separate hours/minutes -field. 1=disable formatting, defaults to 0
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

	unless(scalar(keys(%timetrackingdb)) || scalar(keys(%timetrackstatuses)) ) {
		InitVars();
	}

	my %data;
	my $field;
	foreach my $key (keys %timetrackingdb) {
		$field = $timetrackingdb{$key}{'field'};
		if($field eq 'day') {
			$data{$field} = goah::GoaH::FormatDate($datap->$field);
		} elsif ($field eq 'hours' || $field eq 'inthours') {
			$data{$field}=$datap->$field;

			# It's possible to skip hour formatting with function parameter, hence the if-block
			if(!($_[2]) || $_[2] eq '0') {

				my $minfield='minutes';
				$minfield='intminutes' if($field eq 'inthours');

				$data{$field}=~s/\.\d*$//;
				$data{$minfield}=$datap->$field;
				$data{$minfield}=~s/^\d*/0/;
				$data{$minfield}=sprintf("%.0f",60*$data{$minfield});

			}
		} else {
			$data{$field} = $datap->$field;	
		}
	}

	return \%data;
}


# 
# Function: ReadHours
#
#   Function to maintain searches for hour tracking
#
# Parameters:
#
#   0 - user id's, either single value or array reference
#   1 - customer id's, either single value or array reference
#   2 - starting day, in YYYY-MM-DD, or negative value to read -1*n last entries
#   3 - ending day, in YYYY-MM-DD
#   4 - which hours to read, all (yesno), billable(yes), internal(no), not in basket(open), optional parameter
#   5 - which hours to read, all (all), ones imported to basket(imported), ones not imported to basket(unimported), optional parameter
#
# Returns:
#
#   Success - Hash reference to retrieved data
#   Fail - 0
#
sub ReadHours {

	shift if ($_[0]=~/goah::Modules::Tracking/);
	
	use goah::Db::Timetracking::Manager;

	my %dbsearch;

	if($_[0]) {
		$dbsearch{'userid'}=$_[0];
		goah::Modules->AddMessage('debug',"Searching with uid ".$dbsearch{'userid'},__FILE__,__LINE__);
	}
	if($_[1]) {
		$dbsearch{'companyid'}=$_[1];
		goah::Modules->AddMessage('debug',"Searching with companyid ".$dbsearch{'companyid'},__FILE__,__LINE__);
	}
	# Start date, no end date
	if($_[2] && !($_[3])) {
		unless($_[2]<0) {
			$dbsearch{'day'} = { ge => $_[2] };
			goah::Modules->AddMessage('debug',"Searching with startdate ".$_[2],__FILE__,__LINE__);
		}
	}
	# End date, no start date
	if($_[3] && !($_[2])) {
		$dbsearch{'day'} = { le => $_[3] };
		goah::Modules->AddMessage('debug',"Searching with enddate ".$dbsearch{'day'},__FILE__,__LINE__);
	}
	# Both start and end date
	if($_[2] && $_[3]) {
		$dbsearch{'and'} = [ day => { ge => $_[2] }, day => { le => $_[3] } ];
		goah::Modules->AddMessage('debug',"Searching with start and end date ".$dbsearch{'day'},__FILE__,__LINE__);
	}

	# Limit search by billable/internal
	if($_[4]) {
		if($_[4]=~/^yes$/i) {
			goah::Modules->AddMessage('debug',"Searching debit hours",__FILE__,__LINE__);
			$dbsearch{'hours'} = { gt => 0 };
		}

		if($_[4]=~/^no$/i) {
			goah::Modules->AddMessage('debug',"Searching internal hours",__FILE__,__LINE__);
			$dbsearch{'inthours'} = { gt => 0 };
		}

		# Limit search for only hours not moved to basket
		# This implies billable -option
		if($_[4]=~/^open$/i) {
			goah::Modules->AddMessage('debug',"Searching open, debit hours",__FILE__,__LINE__);
			$dbsearch{'hours'} = { gt => 0 };
			$dbsearch{'or'} = [ basket_id => '', basket_id => 0 ];
			$dbsearch{'productcode'} = { ne => '' };
		}
	}

	# Limit search by imported to basket -status
	if($_[5]) {
		if($_[5]=~/^unimported$/i) {
			goah::Modules->AddMessage('debug',"Searching only unimported hours",__FILE__,__LINE__);
			$dbsearch{'or'}= [ basket_id => '', basket_id => 0 ];
		}

		if($_[5]=~/^imported$/i) {
			goah::Modules->AddMessage('debug',"Searching only imported hours",__FILE__,__LINE__);
			$dbsearch{'or'} = [ basket_id => { gt => 0 }, basket_id => -1 ];
		}
	}

	my $datap; 
	
	if($_[2]<0) {
		goah::Modules->AddMessage('debug',"Limiting search by result count",__FILE__,__LINE__);
		$datap = goah::Db::Timetracking::Manager->get_timetracking(\%dbsearch, sort_by => 'day DESC', limit => -1*$_[2]);
	} else {
		$datap = goah::Db::Timetracking::Manager->get_timetracking(\%dbsearch, sort_by => 'day DESC');
	}
	
	return 0 unless $datap;

	my @data=@$datap;
	return 0 unless scalar(@data);

	unless(scalar(keys(%timetrackingdb)) || scalar(keys(%timetrackstatuses)) ) {
		InitVars();
	}

	# Pack found data into hash and return data
	my %tdata;
	my $i=10000000;
	my %totalhours;
	foreach my $row (@data) {
		$i++;
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
			if($field eq 'userid') {
				my $personp=goah::Modules::Systemsettings->ReadOwnerPersonnel($row->userid);
				unless($personp==0) {
					my %person=%$personp;
					$tdata{$i}{'username'}=$person{'lastname'}." ".$person{'firstname'};
				} else {
					$tdata{$i}{'username'}=__("Not available!");
				}
			}
			if($field eq 'productcode') {
				my $prodinfop=goah::Modules::Productmanagement->ReadData('products',$row->productcode,$uid,$settref,1);
				if($prodinfop==0) {
					$tdata{$i}{'productcode'}=__("Not available!");
					$tdata{$i}{'productname'}=__("Not available!");
				} else {
					my %prodinfo=%$prodinfop;
					$tdata{$i}{'productcode'}=$prodinfo{'code'};
					$tdata{$i}{'productname'}=$prodinfo{'name'};
				}
			}

			if($field eq 'day') {
				$tdata{$i}{$field} = goah::GoaH::FormatDate($row->$field);
			}
			if ($field eq 'hours' || $field eq 'inthours') {
				$tdata{$i}{$field}=$row->$field;
				$tdata{$i}{$field}=~s/\.\d*$//;

				my $minfield='minutes';
				$minfield='intminutes' if($field eq 'inthours');

				$tdata{$i}{$minfield}=$row->$field;
				$tdata{$i}{$minfield}=~s/^\d*/0/;
				if($tdata{$i}{$minfield} > 0) {
					$tdata{$i}{$minfield}=sprintf("%.0f",60*$tdata{$i}{$minfield});
				} else {
					$tdata{$i}{$minfield}=0;
				}

				# Calculate total hours
				if($field eq 'hours') {
					my $billing=1;
					$billing = 0 if($row->no_billing);
					$totalhours{$row->type}{$billing}+=$row->$field;
				}
				if($field eq 'inthours') {
					$totalhours{$row->type}{0}+=$row->$field;
				}
			}
			if ($field eq 'longdescription') {
				$tdata{$i}{$field}=$row->$field;
				$tdata{$i}{$field}=~s/\n/<br\/>\n/g;

				$tdata{$i}{'longdescription_tooltip'}=$row->$field;
				if(length($tdata{$i}{'longdescription_tooltip'})>100) {
					$tdata{$i}{'longdescription_tooltip'}=substr($tdata{$i}{'longdescription_tooltip'},0,100);
					$tdata{$i}{'longdescription_tooltip'}.='...';
				}
			}
		}
	}	
	goah::Modules->AddMessage('debug',"Got ".($i-10000000)." rows from the database.",__FILE__,__LINE__);

	# Go trough hours and cacl total hours
	# Warning: Here be dragons.
	foreach my $t (keys(%totalhours)) {
		
		# $t = Row type (normal/night/evening)
		# -1 index = total sums on this index
		# 0 index = total for internal hours
		# 1 index = total for billed hours

		goah::Modules->AddMessage('debug',"Total hour count for key $t ".$totalhours{$t}{1}."/".$totalhours{$t}{0},__FILE__,__LINE__);

		$tdata{-1}{$t}{'hours'}{-1}=$totalhours{$t}{0}+$totalhours{$t}{1}; # Total hours for current type

		unless($t == 3) {
			# Exclude other -type from total hours
			$tdata{-1}{-1}{'hours'}{-1}+=$totalhours{$t}{0}+$totalhours{$t}{1}; # Total for all types
		}

		$tdata{-1}{$t}{'hours'}{0}=$totalhours{$t}{0}; # Total internal hours for current type
		$tdata{-1}{$t}{'hours'}{1}=$totalhours{$t}{1}; # Total billed hours for current ype
		$tdata{-1}{-1}{'hours'}{0}+=$totalhours{$t}{0} unless($t eq 3); # Total internal hours for all types
		$tdata{-1}{-1}{'hours'}{1}+=$totalhours{$t}{1} unless($t eq 3); # Total billed hours for all types

		$tdata{-1}{$t}{'hours'}{-1}=~s/\.\d*$//; # Total
		$tdata{-1}{$t}{'hours'}{0}=~s/\.\d*$//; # Internal
		$tdata{-1}{$t}{'hours'}{1}=~s/\.\d*$//; # Billing

		# Reset values if they're missing
		$tdata{-1}{$t}{'hours'}{-1}=0 unless($tdata{-1}{$t}{'hours'}{-1});
		$tdata{-1}{$t}{'hours'}{0}=0 unless($tdata{-1}{$t}{'hours'}{0});
		$tdata{-1}{$t}{'hours'}{1}=0 unless($tdata{-1}{$t}{'hours'}{1});
		
		# Reset variables
		$tdata{-1}{$t}{'minutes'}{-1}=0;
		$tdata{-1}{$t}{'minutes'}{0}=0;
		$tdata{-1}{$t}{'minutes'}{1}=0;

		# Calculate totals and strip out numbers right from decimal separator
		$tdata{-1}{$t}{'minutes'}{-1}=$totalhours{$t}{0}+$totalhours{$t}{1};
		$tdata{-1}{$t}{'minutes'}{0}=$totalhours{$t}{0};
		$tdata{-1}{$t}{'minutes'}{1}=$totalhours{$t}{1};

		$tdata{-1}{$t}{'minutes'}{-1}=~s/^\d*/0/;
		$tdata{-1}{$t}{'minutes'}{0}=~s/^\d*/0/;
		$tdata{-1}{$t}{'minutes'}{1}=~s/^\d*/0/;

		# Calculate minutes correctly from decimals
		$tdata{-1}{$t}{'minutes'}{-1}=sprintf("%.0f",60*$tdata{-1}{$t}{'minutes'}{-1}) if($tdata{-1}{$t}{'minutes'}{-1} > 0);
		$tdata{-1}{$t}{'minutes'}{0}=sprintf("%.0f",60*$tdata{-1}{$t}{'minutes'}{0}) if($tdata{-1}{$t}{'minutes'}{0} > 0);
		$tdata{-1}{$t}{'minutes'}{1}=sprintf("%.0f",60*$tdata{-1}{$t}{'minutes'}{1}) if($tdata{-1}{$t}{'minutes'}{1} > 0);
	}

	# Reset variables
	$tdata{-1}{-1}{'minutes'}{-1}=0;
	$tdata{-1}{-1}{'minutes'}{0}=0;
	$tdata{-1}{-1}{'minutes'}{1}=0;

	# Total hour count for retrieved hours
	$tdata{-1}{-1}{'minutes'}{-1}=$tdata{-1}{-1}{'hours'}{-1};
	$tdata{-1}{-1}{'hours'}{-1}=~s/\.\d*$//;
	$tdata{-1}{-1}{'minutes'}{-1}=~s/^\d*/0/;

	$tdata{-1}{-1}{'minutes'}{0}=$tdata{-1}{-1}{'hours'}{0};
	$tdata{-1}{-1}{'hours'}{0}=~s/\.\d*$//;
	$tdata{-1}{-1}{'minutes'}{0}=~s/^\d*/0/;

	$tdata{-1}{-1}{'minutes'}{1}=$tdata{-1}{-1}{'hours'}{1};
	$tdata{-1}{-1}{'hours'}{1}=~s/\.\d*$//;
	$tdata{-1}{-1}{'minutes'}{1}=~s/^\d*/0/;

	$tdata{-1}{-1}{'minutes'}{-1}=sprintf("%.0f",60*$tdata{-1}{-1}{'minutes'}{-1}) if($tdata{-1}{-1}{'minutes'}{-1}>0);
	$tdata{-1}{-1}{'minutes'}{0}=sprintf("%.0f",60*$tdata{-1}{-1}{'minutes'}{0}) if($tdata{-1}{-1}{'minutes'}{0}>0);
	$tdata{-1}{-1}{'minutes'}{1}=sprintf("%.0f",60*$tdata{-1}{-1}{'minutes'}{1}) if($tdata{-1}{-1}{'minutes'}{1}>0);

	return \%tdata;
}

#
# Function: AddHoursToBasket
#
#   An function to add tracked hours into an basket by assigning an
#   basket id for individual row
#
# Parameters:
#
#   rowid - Database id for hours
#   basketid - Basket id to assign, can be empty
#
# Returns:
#
#   Success - 1
#   Fail - 0
#
sub AddHoursToBasket {

	shift if ($_[0]=~/goah::Modules::Tracking/);

	# Use direct database calls to speed things up
	use goah::Db::Timetracking;
	my $datap = goah::Db::Timetracking->new(id => $_[0]);

	unless($datap->load(speculative => 1)) {
		goah::Modules->AddMessage('error',__("Couldn't read any data from the database with id ").$_[0],__FILE__,__LINE__);
		return 0;
	}

	if($_[1]>0) {
		$datap->basket_id($_[1]);
	} else {
		$datap->basket_id(-1);
	}

	return 1 if($datap->save);
	return 0;
}

#
# Function: RemoveHoursFromBasket
#
#   An function to remove basket assignment from tracked hours on 
#   individual row
#
# Parameters:
#
#   rowid - Database id for hours to unassign
#   changetointernal - If set then just assign hours to internal ones instead of billable hours
#
# Return:
#
#   Success - 1
#   Fail - 0
#
sub RemoveHoursFromBasket {

	shift if($_[0]=~/goah::Modules::Tracking/);

	use goah::Db::Timetracking;
	my $datap = goah::Db::Timetracking->new(id => $_[0]);

	unless($datap->load(speculative => 1)) {
		goah::Modules->AddMessage('error',__("Couldn't read any hour data from the database with id ").$_[0],__FILE__,__LINE__);
		return 0;
	}

	$datap->basket_id('');
	if($_[1]) {
		my $inthours=$datap->inthours;
		$inthours+=$datap->hours;
		$datap->inthours($inthours);
		$datap->hours(0);
	}

	return 1 if($datap->save);
	return 0;
}

#
# Function: UpdateHoursFromBasket
#   
#   An function to maintain tracked hours according to changes made on baskets.
#   If basket amount is bigger than the tracked hours then increase hours into tracking,
#   if basket amount is smaller then remove hours from tracking and add the remainder
#   into internal hours
#
# Parameters:
#
#   rowid - Database id for hours to alter
#   amount - Amount to use on calculations
#
# Returns:
#
#   Success - 1
#   Fail - 0
#
sub UpdateHoursFromBasket {

	shift if($_[0]=~/goah::Modules::Tracking/);

	use goah::Db::Timetracking;
	my $datap = goah::Db::Timetracking->new(id => $_[0]);

	unless($datap->load(speculative => 1)) {
		goah::Modules->AddMessage('error',__("Couldn't read any hour data from the database with id ").$_[0],__FILE__,__LINE__);
		return 0;
	}


	$datap->orighours($datap->hours) unless($datap->orighours);
	$datap->originthours($datap->inthours) unless($datap->originthours);
	

	if($_[1]>$datap->orighours) {

		$datap->hours($_[1]);

	} elsif($_[1]<$datap->orighours) {
		
		my $sep=$datap->orighours-$_[1];
		my $inthours=$datap->originthours;
		$inthours+=$sep;
		
		$datap->hours($_[1]);
		$datap->inthours($inthours);
	}

	return 1 if($datap->save);
	return 0;

}


# 
# Function: DeleteBasket
#
#   An cleanup function to delete tracked hours from the
#   basket when the basket itself is deleted.
#
# Parameters:
#
#   basketid - Basket id which is removed
#
# Returns:
#
#   Success (or no hours) - 1 
#   Fail - 0
#
sub DeleteBasket {

	shift if ($_[0]=~/goah::Modules::Tracking/);

	unless($_[0] && $_[0]=~/^[0-9]+$/) {
		goah::Modules->AddMessage('error',__("Given basket id not numeric!"),__FILE__,__LINE__);
		return 0;
	}
	
	use goah::Db::Timetracking::Manager;
	my $datap = goah::Db::Timetracking::Manager->get_timetracking( { basket_id => $_[0] } );
	
	unless($datap) {
		goah::Modules->AddMessage('debug',"No rows found with basketid, this is fine.",__FILE__,__LINE__);
		return 1;
	}

	my @rows=@$datap;
	foreach my $r (@rows) {
		$r->basket_id(0);
		$r->update;
	}

	return 1;
}

1;
