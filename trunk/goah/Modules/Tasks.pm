#!/usr/bin/perl -w 

=begin nd

Package: goah::Modules::Tasks

  This package is used to manage tasks for personnel

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.
  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Modules::Tasks;

use Cwd;
use Locale::TextDomain ('Tasks', getcwd()."/locale");

use strict;
use warnings;
use utf8;
use Encode;
use CGI;

use goah::Modules::Customermanagement;
use goah::Modules::Systemsettings;

my $uid;
my $settref;

my %tasksdb = (
	0 => { field => 'id', name => 'id', type => 'hidden', required => '0', hidden => 1 },
	1 => { 	field => 'companyid', 
		name => __("Customer"), 
		type => 'selectbox', 
		required => '1', 
		data => goah::Modules::Customermanagement->ReadAllCompanies(1), 
		hidden => 0 },
	2 => { field => 'userid', name => 'userid', type => 'hidden', required => '1', hidden => 1 },
	3 => { 	field => 'assigneeid', 
		name => __("Assigned to"), 
		type => 'selectbox', 
		required => '0', 
		data => goah::Modules::Systemsettings->ReadOwnerPersonnel(), 
		hidden => 0 },
	4 => { field => 'priority', name => __("Priority"), type => 'textfield', required => '0', hiden => 0, title => "Integer, 1=highest" },
	6 => { field => 'day', name => __('Date'), type => 'textfield', required => '0', hidden => 1 },
	7 => { field => 'hours', name => __("Working hrs"), type => 'textfield', required => '1', hidden => 0, title => "1:30 or 1,5" },
	8 => { field => 'inthours', name => __("Intern. hrs"), type => 'textfield', required => '0', hidden => 0, title => "1:30 or 1,5" },
	9 => { field => 'description', name => __('Description'),  type => 'textarea', required => '1', hidden => 0 },
	91 => { field => 'no_billing', name => __("Internal"), type => 'checkbox', required => '0', hidden => 0 },
	93 => { field => 'longdescription', name => __("Long description, only for internal use"), type => "textarea", required => 0, hidden => 1 },
	94 => { field => 'completed', name => __("Completed task"), type => 'checkbox', required => 0, hidden => 0 },
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

        $variables{'function'} = 'modules/Tasks/tasks';
        $variables{'module'} = 'Tasks';
        $variables{'gettext'} = sub { return __($_[0]); };
        $variables{'submenu'} = \%submenu;
	$variables{'tasksdb'} = \%tasksdb;


	my ($sec,$min,$hour,$mday,$mon,$yearnow,$wday,$yday,$isdst) = localtime(time);
	$yearnow+=1900;
	$mon++;
	$variables{'datenow'} = sprintf("%02d.%02d.%04d",$mday,$mon,$yearnow);
	
	if($q->param('action')) {
		
		if($q->param('action') eq 'writenewtask') {
			if(WriteTasks($uid)) {
				goah::Modules->AddMessage('info',__("Hours tracked"),__FILE__,__LINE__);
			} else {
				goah::Modules->AddMessage('error',__("Couldn't write task to database!"),__FILE__,__LINE__);
			}
		} elsif($q->param('action') eq 'writeeditedtask') {
			if(WriteTasks($uid)) {
				if($q->param('delete')) {
					goah::Modules->AddMessage('info',__("Task removed from the database."),__FILE__,__LINE__);
				} else {
					goah::Modules->AddMessage('info',__("Task info updated."),__FILE__,__LINE__);
				}
			} else {
				goah::Modules->AddMessage('error',__("Couldn't update information into database!"),__FILE__,__LINE__);
			}

		} elsif($q->param('action') eq 'edittask') {
			$variables{'function'} = "modules/Tasks/edittask";
			$variables{'dbdata'} = ReadData('tasks',"id".$q->param('target'));

		} elsif($q->param('action') eq 'reporting') {
			$variables{'function'} = "modules/Tasks/reporting";
			$variables{'dbdata'} = ReadTasks('all','all');
			$variables{'dbcompanies'}=goah::Modules::Customermanagement->ReadAllCompanies(1);
			$variables{'dbusers'}=goah::Modules::Systemsettings->ReadOwnerPersonnel();

			$variables{'stateselect'} = {   0 => { key => 'open', value => __("Open tasks") },
							1 => { key => 'closed', value => __("Closed tasks") },
							2 => { key => 'all', value => __("All tasks") } };

			# Get data for actual search, or if no parameters are given, search for everything open
			if($q->param('subaction') && $q->param('subaction') eq 'search' && !($q->param('submit-reset'))) {
				my $company;
				my $uid;
				my $stateselect;

				$company = $q->param('customer') if($q->param('customer') && !($q->param('customer')=~/\*/) );
				$uid = $q->param('user') if($q->param('user'));
				$stateselect = $q->param('stateselect') if ($q->param('stateselect'));
				
				$variables{'dbdata'}=ReadTasks($uid,$company,'','',$stateselect);
				$variables{'search_customer'}=$company;
				$variables{'search_owners'}=$uid;
				$variables{'search_stateselect'}=$stateselect;
				$variables{'search_longdesc'}='checked' if($q->param('search_longdesc'));

			} else {
				$variables{'dbdata'}=ReadTasks('','','','','open');
			}

                } else {
                        goah::Modules->AddMessage('error',__("Module doesn't have function ")."'".$q->param('action')."'.");
                        $variables{'function'} = 'modules/blank';
                }

	}

	if($variables{'function'}=~/modules\/Tasks\/tasks/) {
		$variables{'opentasks'}=ReadTasks($uid,'','-50','');
	}
		

	return \%variables;
}


#
# Function: WriteTasks 
#
#   Write new/changed task to database.
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
sub WriteTasks {

	shift if ($_[0]=~/goah::Modules::Tasks/);

	use goah::Db::Tasks;
	my $q = new CGI;

	my %dbdata;

	my $taskitem;
	my $update=0;

	# Check if we're updating an existing item or creating a new one
	if($q->param('target')) {
		$taskitem = goah::Db::Tasks->new(id => $q->param('target'));
		unless($taskitem->load(speculative => 1, for_update => 1)) {
			goah::Modules->AddMessage('error',__("Couldn't load data from the database for modifications!"),__LINE__,__FILE__);
			return 0;
		}
		goah::Modules->AddMessage('debug',"Got data with id ".$taskitem->id." and desc ".$taskitem->description,__FILE__,__LINE__);
		$update=1;
		if($q->param('delete')) {
			return 1 if $taskitem->delete;
			goah::Modules->AddMessage('error',__("Couldn't delete item from the database."),__FILE__,__LINE__);
			return 0;
		}
	}

	# Update values to an array from http variables
        my %fieldinfo;
        while(my($key,$value) = each (%tasksdb)) {
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
			if(length($q->param($fieldinfo{'field'})) || $fieldinfo{'field'} eq 'hours' || $fieldinfo{'type'} eq 'checkbox' || $fieldinfo{'field'} eq 'day' ) {
				my $tmpcol=$fieldinfo{'field'};
				$dbdata{$tmpcol}=(decode('utf-8',$q->param($fieldinfo{'field'})));
				
				if($fieldinfo{'field'} eq 'hours') {

					my $hours = $q->param($fieldinfo{'field'});
					$hours=~s/,/\./g;
					if($hours=~/:/) {
						my @hoursarr=split(/:/,$hours);
						my $tmphours=$hoursarr[1]/60;
						$tmphours+=$hoursarr[0];
						$hours=$tmphours;
					} elsif(!$hours=~/\d+\.?\d*/) {
						goah::Modules->AddMessage('warn',__("Hours column not numeric! Setting hours -value to 0!"));
						$hours=0;
					}
					if($q->param('minutes')) {
						$hours+=$q->param('minutes')/60;
					}
					$dbdata{$tmpcol}=$hours;
				}	
				if($fieldinfo{'field'} eq 'inthours') {
					my $inthours=$q->param($fieldinfo{'field'});
					$inthours=~s/,/./g;
					if($inthours=~/:/) {
						my @inthoursarr=split(/:/,$inthours);
						my $tmpinthours=$inthoursarr[1]/60;
						$tmpinthours+=$inthoursarr[0];
						$inthours=$tmpinthours;
					} elsif (!$inthours=~/\d+\.?\d*/) {
						goah::Modules->AddMessage('warn',__("Internal hours column not numeric! Setting value to 0!"));
						$inthours=0;
					}
					if($q->param('intminutes')) {
						$inthours+=$q->param('intminutes')/60;
					}
					$dbdata{$tmpcol}=$inthours;
				}		
				if($fieldinfo{'field'} eq 'day') {
					my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
					$year+=1900;    
					$mon++; 
					unless($dbdata{$tmpcol}) {
						$dbdata{$tmpcol}=sprintf("%04d-%02d-%02d",$year,$mon,$mday);
						goah::Modules->AddMessage("debug","Set date to ".$dbdata{$tmpcol},__FILE__,__LINE__);
					} else {
						if($q->param('day')=~/[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{4}/) {
							$dbdata{$tmpcol}=goah::GoaH::FormatDate($q->param('day')." 00:00:01");
						} elsif($q->param('day')=~/[0-9]{1,2}\.[0-9]{1,2}/) {
							$dbdata{$tmpcol}=goah::GoaH::FormatDate($q->param('day').".".$year." 00:00:01");
						} else {
						goah::Modules->AddMessage('warn',__("Incorrectly formatted date!  Using current date."),__LINE__,__FILE__);
						$dbdata{$tmpcol}=sprintf("%04d-%02d-%02d",$year,$mon,$mday);
						}
					}

				}
				if($fieldinfo{'type'} eq 'checkbox') {
					if($q->param($tmpcol) eq 'on') {
						$dbdata{$tmpcol}=1;
					} else {
						$dbdata{$tmpcol}=0;
					}
				}

				# Update existing tracking item
				$taskitem->$tmpcol($dbdata{$tmpcol}) if $update;
			}
                }
        }

	# Create new task
	$taskitem = goah::Db::Tasks->new(%dbdata) unless $update;
	return 1 if ($taskitem->save);
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
#   type - Which kind of data we're reading, currently only valid format is 'tasks'
#   search - Search parameters, currently only accepted format is 'id00', where 00 is an valid database id
#   formattime - If we should recalculate hours field to separate hours/minutes -field. 1=disable formatting, defaults to 0
#
# Returns:
#   
#   Fail - 0
#   Success - An hash reference with search data
#
sub ReadData {

	shift if ($_[0]=~/goah::Modules::Tasks/);

	unless($_[0]=~/tasks/) {
		goah::Modules->AddMessage('debug',"ReadData function called with invalid search parameters",__FILE__,__LINE__);
		return 0;
	}

	unless($_[1]=~/^id/) {
		goah::Modules->AddMessage('debug',"ReadData function called with invalid search parameters",__FILE__,__LINE__);
		return 0;
	}

	my $id=$_[1];
	$id=~s/^id//i;

	use goah::Db::Tasks;
	my $datap = goah::Db::Tasks->new(id => $id);
	
	unless($datap->load(speculative => 1)) {
		goah::Modules->AddMessage('error',__("Couldn't read any data from the database with id ").$id,__FILE__,__LINE__);
		return 0;
	}

	my %data;
	my $field;
	foreach my $key (keys %tasksdb) {
		$field = $tasksdb{$key}{'field'};
		if($field eq 'day') {
			$data{$field} = goah::GoaH::FormatDate($datap->$field);
		} elsif ($field eq 'hours' || $field eq 'inthours') {
			$data{$field}=$datap->$field;
			if(!($_[2]) || $_[2] eq '0') {
				$data{$field}=~s/\.\d*$//;
				if($field eq 'hours') {
					$data{'minutes'}=$datap->$field;
					$data{'minutes'}=~s/^\d*/0/;
					$data{'minutes'}=sprintf("%.0f",60*$data{'minutes'});
				} 
				if($field eq 'inthours') {
					$data{'intminutes'}=$datap->$field;
					$data{'intminutes'}=~s/^\d*/0/;
					$data{'intminutes'}=sprintf("%.0f",60*$data{'intminutes'});
				}
			}
		} else {
			$data{$field} = $datap->$field;	
		}
	}

	return \%data;
}


# 
# Function: ReadTasks
#
#   Function to maintain searches for hour tracking
#
# Parameters:
#
#   0 - user id's, either single value or array reference
#   1 - customer id's, either single value or array reference
#   2 - starting day, in YYYY-MM-DD, or negative value to read -1*n last entries
#   3 - ending day, in YYYY-MM-DD
#   4 - which tasks to read, open, closed or all
#
# Returns:
#
#   Success - Hash reference to retrieved data
#   Fail - 0
#
sub ReadTasks {

	shift if ($_[0]=~/goah::Modules::Tasks/);
	
	use goah::Db::Tasks::Manager;

	my %dbsearch;

	if($_[0]) {
		$dbsearch{'assigneeid'}=$_[0];
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

	# Search by state
	if($_[4]) {
		if($_[4]=~/open/) {
			$dbsearch{'completed'} = "0";
		}
		elsif($_[4]=~/closed/) {
			goah::Modules->AddMessage('debug',"Searching for completed tasks",__FILE__,__LINE__);
			$dbsearch{'completed'} = "1";
		}
	}
		
	my $datap; 
	
	if($_[2]<0) {
		goah::Modules->AddMessage('debug',"Limiting search by result count",__FILE__,__LINE__);
		$datap = goah::Db::Tasks::Manager->get_tasks(\%dbsearch, sort_by => 'priority DESC, day DESC', limit => -1*$_[2]);
	} else {
		$datap = goah::Db::Tasks::Manager->get_tasks(\%dbsearch, sort_by => 'priority DESC, day DESC');
	}
	
	return 0 unless $datap;

	my @data=@$datap;
	return 0 unless scalar(@data);

	# Pack found data into hash and return data
	my %tdata;
	my $i=10000000;
	my %totalhours;
	foreach my $row (@data) {
		$i++;
		my $field;
		foreach my $key (keys %tasksdb) {
			$field = $tasksdb{$key}{'field'};
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
			if($field eq 'day') {
				$tdata{$i}{$field} = goah::GoaH::FormatDate($row->$field);
			}
			if ($field eq 'hours' || $field eq 'inthours') {
				my $minfield='minutes';
				$minfield='intminutes' if($field eq 'inthours');

				$tdata{$i}{$field}=$row->$field;
				$tdata{$i}{$field}=~s/\.\d*$//;
				$tdata{$i}{$minfield}=$row->$field;
				$tdata{$i}{$minfield}=~s/^\d*/0/;
				if($tdata{$i}{$minfield} > 0) {
					$tdata{$i}{$minfield}=sprintf("%.0f",60*$tdata{$i}{$minfield});
				} else {
					$tdata{$i}{$minfield}=0;
				}

				if($field eq 'inthours') {
					$totalhours{'internal'}+=$row->$field;
				} else {
					$totalhours{'normal'}+=$row->$field;
					goah::Modules->AddMessage('debug',"Normal hours now ".$totalhours{'normal'}." after +".$row->$field);
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
	foreach my $t (keys(%totalhours)) {
		
		$tdata{-1}{'normal'}=$totalhours{'normal'};
		$tdata{-1}{'internal'}=$totalhours{'internal'};

		$tdata{-1}{'normal'}=~s/\.\d*$//;
		$tdata{-1}{'internal'}=~s/\.\d*$//;

		$tdata{-1}{'normal'}=0 unless($tdata{-1}{'normal'});
		$tdata{-1}{'internal'}=0 unless($tdata{-1}{'internal'});
		
		# Reset variables
		$tdata{-1}{'minutes'}=0;
		$tdata{-1}{'intminutes'}=0;

		$tdata{-1}{'minutes'}=$totalhours{'normal'};
		$tdata{-1}{'intminutes'}=$totalhours{'internal'};

		$tdata{-1}{'minutes'}=~s/^\d*/0/;
		$tdata{-1}{'intminutes'}=~s/^\d*/0/;

		# Calculate minutes correctly from decimals
		$tdata{-1}{'minutes'}=sprintf("%.0f",60*$tdata{-1}{'minutes'}) if ($tdata{-1}{'minutes'} > 0);
		$tdata{-1}{'intminutes'}=sprintf("%.0f",60*$tdata{-1}{'intminutes'}) if ($tdata{-1}{'intminutes'} > 0);
	}

	return \%tdata;
}

1;
