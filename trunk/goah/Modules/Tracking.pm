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

my $uid;
my $settref;

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
	4 => 	{ 	field => 'productcode', 
			name => __('Product'), 
			type => 'selectbox', 
			required => '1', 
			data => goah::Modules::Productmanagement->ReadProductsByGrouptype(1,$uid) },
	5 => { field => 'day', name => __('Date'), type => 'textfield', required => '1' },
	6 => { field => 'hours', name => __("Working hours"), type => 'textfield', required => '1' },
	7 => { field => 'description', name => __('Description'),  type => 'textarea', required => '1' },
	#8 => { field => 'project', name => __("Project"), type => "textarea", required => '0' },
	#9 => { field => 'personnel', name => __("Related personnel"), type => 'textarea', required => '0' },
	8 => { field => 'project', name => __("Project"), type => "hidden", required => '0' },
	9 => { field => 'personnel', name => __("Related personnel"), type => 'hidden', required => '0' },
	91 => { field => 'no_billing', name => __("No billing"), type => 'checkbox', required => '0' },
);


my %submenu = (
	0 => { title => __("Reporting"), action => 'reporting' }
);


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


	my ($sec,$min,$hour,$mday,$mon,$yearnow,$wday,$yday,$isdst) = localtime(time);
	$yearnow+=1900;
	$mon++;
	$variables{'datenow'} = sprintf("%02d.%02d.%04d",$mday,$mon,$yearnow);
	
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

		} elsif($q->param('action') eq 'reporting') {
			$variables{'function'} = "modules/Tracking/reporting";
			$variables{'dbdata'} = ReadHours('all','all');
			$variables{'dbcompanies'}=goah::Modules::Customermanagement->ReadAllCompanies(1);
			$variables{'dbusers'}=goah::Modules::Systemsettings->ReadOwnerPersonnel();
			$variables{'timetrackstatuses'}=\%timetrackstatuses;

			# Helper variable to generate an selectbox for parameters
			$variables{'yesnoselect'} = { 	0 => { key => 'yesno', value => __("All hours") },
							1 => { key => 'yes', value => __("Only billed hours") },
							2 => { key => 'no', value => __("Only not billed hours") } };

			# Get data for actual search, or if no parameters are given, search for hours
			# at current month
			if($q->param('subaction') && $q->param('subaction') eq 'search' && !($q->param('submit-reset'))) {
				my $company;
				my $uid;
				my $startdate;
				my $enddate;
				my $searchdatestart;
				my $searchdateend;
				my $yesnoselect;

				$company = $q->param('customer') if($q->param('customer') && !($q->param('customer')=~/\*/) );
				$uid = $q->param('user') if($q->param('user'));
				$startdate = $q->param('fromdate') if($q->param('fromdate'));
				$enddate = $q->param('todate') if($q->param('todate'));
				$yesnoselect = $q->param('yesnoselect') if($q->param('yesnoselect'));
				
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

				$variables{'dbdata'}=ReadHours($uid,$company,$searchdatestart,$searchdateend,$yesnoselect);
				$variables{'search_customer'}=$company;
				$variables{'search_owners'}=$uid;
				$variables{'search_startdate'}=$startdate;
				$variables{'search_enddate'}=$enddate;
				$variables{'search_yesnoselect'}=$yesnoselect;

			} else {
				$variables{'dbdata'}=ReadHours('','',sprintf("%04d-%02d-%02d",$yearnow,$mon,'01'));
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
	}

        my %fieldinfo;
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
				$dbdata{$tmpcol}=(decode('utf-8',$q->param($fieldinfo{'field'})));
				if($fieldinfo{'field'} eq 'hours') {
					my $hours = $q->param($fieldinfo{'field'});
					$hours=~s/,/\./g;
					unless($hours=~/\d+\.?\d*/) {
						goah::Modules->AddMessage('warn',__("Hours column not numeric! Setting hours -value to 0!"));
						$dbdata{$tmpcol}="0";
					}
					if($q->param('minutes')>0) {
						$dbdata{$tmpcol}+=$q->param('minutes')/60;
					}
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
						$dbdata{$tmpcol}=1;
					} else {
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
		if($field eq 'day') {
			$data{$field} = goah::GoaH::FormatDate($datap->$field);
		} elsif ($field eq 'hours') {
			$data{$field}=$datap->$field;
			$data{$field}=~s/\.\d*$//;
			$data{'minutes'}=$datap->$field;
			$data{'minutes'}=~s/^\d*/0/;
			$data{'minutes'}=sprintf("%.0f",60*$data{'minutes'});
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
#   4 - which hours to read, all (yesno), billed(yes), unbilled(no), optional
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

	# Limit search by billed/unbilled
	if($_[4]) {
		if($_[4]=~/^yes$/i) {
			$dbsearch{'no_billing'} = "0";
		}

		if($_[4]=~/^no$/i) {
			$dbsearch{'no_billing'} = "1";
		}
	}

	my $datap; 
	
	if($_[2]<0) {
		$datap = goah::Db::Timetracking::Manager->get_timetracking(\%dbsearch, sort_by => 'day DESC', limit => -1*$_[2]);
	} else {
		$datap = goah::Db::Timetracking::Manager->get_timetracking(\%dbsearch, sort_by => 'day DESC');
	}
	
	return 0 unless $datap;

	my @data=@$datap;
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
			if($field eq 'day') {
				$tdata{$i}{$field} = goah::GoaH::FormatDate($row->$field);
			}
			if ($field eq 'hours') {
				$tdata{$i}{$field}=$row->$field;
				$tdata{$i}{$field}=~s/\.\d*$//;
				$tdata{$i}{'minutes'}=$row->$field;
				$tdata{$i}{'minutes'}=~s/^\d*/0/;
				if($tdata{$i}{'minutes'} > 0) {
					$tdata{$i}{'minutes'}=sprintf("%.0f",60*$tdata{$i}{'minutes'});
				} else {
					$tdata{$i}{'minutes'}=0;
				}
				$totalhours{$row->type}+=$row->$field;
			}
		}
	}	

	foreach my $t (keys(%totalhours)) {
		goah::Modules->AddMessage('debug',"Total hour count for key $t ".$totalhours{$t},__FILE__,__LINE__);
		$tdata{-1}{$t}{'hours'}=$totalhours{$t};
		$tdata{-1}{-1}{'hours'}+=$totalhours{$t};
		$tdata{-1}{$t}{'hours'}=~s/\.\d*$//;
		$tdata{-1}{$t}{'minutes'}=$totalhours{$t};
		$tdata{-1}{$t}{'minutes'}=~s/^\d*/0/;
		if($tdata{-1}{$t}{'minutes'} > 0) {
			$tdata{-1}{$t}{'minutes'}=sprintf("%.0f",60*$tdata{-1}{$t}{'minutes'});
		} else {
			$tdata{-1}{$t}{'minutes'}=0;
		}
	}
	$tdata{-1}{-1}{'minutes'}=$tdata{-1}{-1}{'hours'};
	$tdata{-1}{-1}{'hours'}=~s/\.\d*$//;
	$tdata{-1}{-1}{'minutes'}=~s/^\d*/0/;
	if($tdata{-1}{-1}{'minutes'}>0) {
		$tdata{-1}{-1}{'minutes'}=sprintf("%.0f",60*$tdata{-1}{-1}{'minutes'});
	} else {
		$tdata{-1}{-1}{'minutes'}=0;
	}

	return \%tdata;
}

1;
