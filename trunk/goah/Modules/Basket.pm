#!/usr/bin/perl -w 

=begin nd

Package: goah::Modules::Basket

  This package is used to manage baskets and their content.  

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.
  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Modules::Basket;

use Cwd;
use Locale::TextDomain ('Basket', getcwd()."/locale");

use strict;
use warnings;
use utf8;
use Encode;

use goah::Modules::Customermanagement;
use goah::Modules::Productmanagement;

my %baskettypes = ( 0 => { id => 0, name => __("Pending"), selected => 1, hidden => 0, validstates => (4) },
		    1 => { id => 1, name => __("Sold"), selected => 0, hidden => 1 },
		    2 => { id => 2, name => __("Recurring"), selected => 0, hidden => 0, validstates => () },
		    3 => { id => 3, name => __("Offer"), selected => 0, hidden => 0, validstates => (4) },
		    4 => { id => 4, name => __("Order"), selected => 0, hidden => 0, validstates => (0,4) }
		    );

#
# Hash: basketdbfields
#
#   Database field definitions for baskets
#
my %basketdbfields = ( 
		0 => { field => 'id', name => 'id', type => 'hidden', required => '0' },
		1 => { field => 'companyid', name => __('Customer'), type => 'selectbox', required => '1', data => goah::Modules::Customermanagement->ReadAllCompanies(1) },
		2 => { field => 'locationid', name => __('Shipping address'), type => 'selectbox', required => '1', data => '0', hidden => 0 },
		3 => { field => 'billingid', name => __('Billing address') , type => 'selectbox', required => '1', data => '0', hidden => 0 },
		4 => { field => 'state', name => __("Basket type"), type => 'selectbox', required => '1', data => \%baskettypes, hidden => 0 },
		5 => { field => 'created', name => 'created', type => 'hidden', required => '0', hidden => 0 },
		6 => { field => 'updated', name => 'updated', type => 'hidden', required => '0', hidden => 0 },
		7 => { field => 'info', name => __('Description'), type => 'textarea', required => '0', hidden => 0 },
		8 => { field => 'ownerid', name => 'ownerid', type => 'hidden', required => '0', hidden => 0 },
		9 => { field => 'longinfo', name => __("Additional information"), type => 'textarea', required => '0', hidden => 1 }
	);

#
# Hash: basketrowdbfields
#
#   Database field definitions for basket rows
#
my %basketrowdbfields = (
		0 => { field => 'id', name => 'id', type => 'hidden', required => '0' },
		1 => { field => 'basketid', name => 'basketid', type => 'hidden', required => '0' },
		2 => { field => 'productid', name => __("Product"), type => 'selectbox', required => '1', data => '0' },
		3 => { field => 'purchase', name => __("Purchase price"), type => 'textbox', required => '0' },
		4 => { field => 'sell', name => __("Sell price"), type => 'textbox', required => '1' },
		5 => { field => 'amount', name => __("Amount"), type => 'textbox', required => '1' },
		6 => { field => 'rowinfo', name => __("Row information"), type => 'textbox', required => '0' },
		7 => { field => 'remoteid', name => 'remoteid', type => 'hidden', required => '0', hidden => 1 }
	);

#
# Hash: submenu
#
#   Submenu definition
#
my %submenu = ( 
		0 => { title => __("Recurring baskets"), action => 'recurring' }
	);


# 
# Hash: basketstates
#
#   Text representations of basket states
#
my %basketstates = ( 0 => __("Pending"),
		     1 => __("Sent/Closed"),
		     2 => __("Recurring"),
		     3 => __("Offer"),
		     4 => __("Order")
	);

#
# String: uid
#
#   User id for global package access
#
my $uid;
my $settref;

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

	$variables{'module'} = 'Basket';
	$variables{'gettext'} = sub { return __($_[0]); };
	$variables{'formatdate'} = sub { goah::GoaH::FormatDate($_[0]); };
	$variables{'basketdbfields'} = \%basketdbfields;
	$variables{'basketrowdbfields'} = \%basketrowdbfields;
	$variables{'basketstates'} = \%basketstates;
	$variables{'baskettypes'} = \%baskettypes;
	$variables{'submenu'} = \%submenu;
	$variables{'function'} = 'modules/Basket/showbaskets';
	$variables{'activebasket'} = 0;
	$variables{'products'} = sub { goah::Modules::Productmanagement::ReadData('products',,$uid,$settref) };

	use goah::Modules::Personalsettings;
	$variables{'usersettings'} = sub { goah::Modules::Personalsettings::ReadSettings($uid) };

	if($q->param('action')) {

		if($q->param('action') eq 'showbaskets') {

				use goah::Modules::Systemsettings;
				my @states;
				if(length($q->param('states'))) {
					@states=$q->param('states');
				} else {
					goah::Modules->AddMessage('debug',"Didn't get states! ".$q->param('states'));
					@states=(0,3,4);
				}
				my @owners;
				if($q->param('owner')) {
					@owners=$q->param('owner');
				} 

				my $customer;
				if(length($q->param('customer'))) {
					$customer=$q->param('customer');
				}

				if($q->param('submit-reset')) {
					@states=(0,3,4);
					$customer='';
					$#owners=-1;
				}

				$variables{'baskets'} = ReadBaskets('',\@owners,\@states,1,$customer);
				$variables{'companypersonnel'} = goah::Modules::Systemsettings->ReadOwnerPersonnel();
				$variables{'function'} = 'modules/Basket/showbaskets';
				$variables{'search_states'}=\@states;
				$variables{'search_owners'}=\@owners;
				$variables{'search_customer'}=$customer;

		} elsif($q->param('action') eq 'selectbasket') {

				my $tmpdata = ReadBaskets($q->param('target'));
				my %tmpd=%$tmpdata;
				use goah::Modules::Tracking;

				$variables{'function'} = 'modules/Basket/activebasket';
				$variables{'activebasket'} = $q->param('target');
				$variables{'basketdata'} = $tmpdata;
				$variables{'basketrows'} = ReadBasketrows($q->param('target'));
				$variables{'trackedhours'} = goah::Modules::Tracking->ReadHours('',$tmpd{'companyid'},'0','0','open');
				$variables{'productinfo'} = sub { goah::Modules::Productmanagement::ReadData('products',$_[0],$uid) };

				# Search selected basket files
				use goah::Modules::Files;
				$variables{'basketfiles'} = goah::Modules::Files->GetFileRows($q->param('target'),'');

				# Get GoaH internal users email-addresses
        			use goah::Modules::Systemsettings;
        			$variables{'goah_users'} = goah::Modules::Systemsettings->ReadOwnerPersonnel;

				# Actions if we are returning from files.cgi
				if ($q->param('files_action')) {

					if ($q->param('status') eq 'success') {

						my $success_message;
						if ($q->param('files_action') eq 'upload') {$success_message = "File uploaded succesfully"}
						if ($q->param('files_action') eq 'delete') {$success_message = "File deleted succesfully"}

						goah::Modules->AddMessage('info',"$success_message");
					}

					if ($q->param('status') eq 'error') {

						# Get and process error
						my $tmp_msg = $q->param('msg');
						my $error_message = ucfirst($tmp_msg);
						$error_message =~ s/_/ /g;
					
						goah::Modules->AddMessage('error',"ERROR! $error_message");
							
					}
				}

		} elsif($q->param('action') eq 'recurring') {

				$variables{'function'} = 'modules/Basket/recurringbaskets';
				$variables{'baskets'} = ReadBaskets('','',[ 2 ]);

		} elsif($q->param('action') eq 'newbasket') {

				my $basket = WriteNewBasket($uid);
				if($basket != 0) {
					goah::Modules->AddMessage('info', __("New basket created"));
				} else {
					goah::Modules->AddMessage('error',__("Can't add new basket to database"));
				}

				my $tmpdata=ReadBaskets($basket);
				my %tmpd=%$tmpdata;

				$variables{'function'} = 'modules/Basket/activebasket';
				$variables{'activebasket'} = $basket;
				$variables{'basketdata'} = $tmpdata;
				$variables{'basketrows'} = ReadBasketrows($basket);
				$variables{'trackedhours'} = goah::Modules::Tracking->ReadHours('',$tmpd{'companyid'},'0','0','open');
				$variables{'productinfo'} = sub { goah::Modules::Productmanagement::ReadData('products',$_[0],$uid) };
				$variables{'trackedhours'} = goah::Modules::Tracking->ReadHours('',$tmpd{'companyid'},'0','0','open');

		} elsif($q->param('action') eq 'showbasket') {

				#$variables{'data'} = ReadBaskets($q->param('target'));
				my $tmpdata = ReadBaskets($q->param('target')); 
				$variables{'data'} = $tmpdata;
				$variables{'function'} = 'modules/Basket/basketinfo';
				$variables{'basketrows'} = ReadBasketrows($q->param('target'));
				$variables{'activebasket'} = '0';

		} elsif($q->param('action') eq 'editcustomerinfo') {

				if(UpdateBasket() == 0) {
					goah::Modules->AddMessage('info', __("Baskets customer info updated"));
				} else {
					goah::Modules->AddMessage('error',__("Can't update basket information"));
				}
				$variables{'basketdata'} = ReadBaskets($q->param('id'));
				$variables{'activebasket'} = $q->param('id');
				$variables{'function'} = 'modules/Basket/activebasket';
				$variables{'basketrows'} = ReadBasketrows($q->param('id'));

		} elsif($q->param('action') eq 'addtobasket') {

				my $returnvalue;

				if($q->param('subaction') eq 'ean') {
					goah::Modules->AddMessage('debug',"Add to basket via EAN",__FILE__,__LINE__);
					$returnvalue = AddToBasket($q->param('barcode'),$q->param('subaction'));
				} elsif($q->param('subaction') eq 'productcode') {
					goah::Modules->AddMessage('debug',"Add to basket via product code",__FILE__,__LINE__);
					$returnvalue = AddToBasket($q->param('code'),$q->param('subaction'));
				} else {
					$returnvalue = AddToBasket();
				}
					
				if($returnvalue == 0) {
					goah::Modules->AddMessage('info', __("Product(s) added to basket"));
				} else {
					goah::Modules->AddMessage('error', __("Can't add product(s) to basket"));
				}

				my $tmpdata=ReadBaskets($q->param('basketid'));
				my %tmpd=%$tmpdata;

				$variables{'basketdata'} = $tmpdata;
				$variables{'basketrows'} = ReadBasketrows($q->param('basketid'));
				$variables{'function'} = 'modules/Basket/activebasket';
				$variables{'activebasket'} = $q->param('basketid');
				$variables{'trackedhours'} = goah::Modules::Tracking->ReadHours('',$tmpd{'companyid'},'0','0','open');
				$variables{'productinfo'} = sub { goah::Modules::Productmanagement::ReadData('products',$_[0],$uid) };

		} elsif($q->param('action') eq 'editrow') {

				if(UpdateBasketRow() == 0) {
					goah::Modules->AddMessage('info',__("Row updated"));
				} else {
					goah::Modules->AddMessage('error',__("Can't update row."));
				}

				my $tmpdata=ReadBaskets($q->param('target'));
				my %tmpd=%$tmpdata;

				$variables{'basketdata'} = $tmpdata;
				#$variables{'basketdata'} = ReadBaskets($q->param('target'));
				
				$variables{'basketrows'} = ReadBasketrows($q->param('target'));
				$variables{'activebasket'} = $q->param('activebasket');

				$variables{'trackedhours'} = goah::Modules::Tracking->ReadHours('',$tmpd{'companyid'},'0','0','open');

				if($q->param('activebasket') == '0') {
					$variables{'function'} = 'modules/Basket/basketinfo';
				} else {
					$variables{'function'} = 'modules/Basket/activebasket';
				}

		} elsif($q->param('action') eq 'deletebasket') {

				if(DeleteBasket($q->param('target')) == 1) {
					goah::Modules->AddMessage('info',__("Basket deleted"));
				} else {
					goah::Modules->AddMessage('error',__("Can't delete basket!"));
				}

				my @states=(0,3,4);
				$variables{'baskets'} = ReadBaskets('','',\@states,1);
				$variables{'function'} = 'modules/Basket/showbaskets';
				$variables{'search_states'}=\@states;

		} elsif($q->param('action') eq 'basket2invoice') {

				if(BasketToInvoice($q->param('target'))) {
					goah::Modules->AddMessage('info',__("Basket converted to invoice"));
				} else {
					goah::Modules->AddMessage('error',__("Can't create invoice"));
				}
				my @states=(0,3,4);
				$variables{'baskets'} = ReadBaskets('','',\@states,1);
				$variables{'search_states'}=\@states;

		} elsif($q->param('action') eq 'showgroup') {

				$variables{'function'} = 'modules/Basket/showgroup';
				my $tmpdata = ReadBaskets($q->param('basketid'));
				$variables{'data'} = $tmpdata;
				$variables{'products'} = goah::Modules::Productmanagement::ReadProductsByGroup($q->param('groupid'),$uid);
				$variables{'productinfo'} = sub { goah::Modules::Productmanagement::ReadData('products',$_[0],$uid) };

		} elsif($q->param('action') eq 'runrecurring') {

				if(WriteRecurringBasket($q->param('target'))) {
					goah::Modules->AddMessage('info',__("New basket created via recurring basket"),__FILE__,__LINE__);
				} else {
					goah::Modules->AddMessage('error',__("Couldn't create new basket via recurring basket!"),__FILE__,__LINE__);
				}

				my @states=(0,3,4);
				$variables{'baskets'} = ReadBaskets('','',\@states,1);
				$variables{'function'} = 'modules/Basket/showbaskets';
				$variables{'search_states'}=\@states;

		} else {
				goah::Modules->AddMessage('error',__("Module doesn't have function ")."'".$q->param('action')."'.");
				$variables{'function'} = 'modules/blank';
		}

	} else {
		use goah::Modules::Systemsettings;
		$variables{'companypersonnel'} = goah::Modules::Systemsettings->ReadOwnerPersonnel();

		my @states=(0,3,4);
		$variables{'baskets'} = ReadBaskets('','',\@states,1);
		$variables{'search_states'}=\@states;

	}
		
	use goah::Modules::Customermanagement;
	$variables{'userinfo'} = sub { return goah::Modules::Customermanagement::ReadPersondata($_[0]) };
	$variables{'companyinfo'} = sub { goah::Modules::Customermanagement::ReadCompanydata($_[0]) };
	$variables{'locationinfo'} = sub { goah::Modules::Customermanagement::ReadLocationdata($_[0]) };
	$variables{'locations'} = sub { goah::Modules::Customermanagement::ReadCompanylocations($_[0]) };
	$variables{'productgroups'} = sub { goah::Modules::Productmanagement::ReadData('productgroups') };
	$variables{'productinfo'} = sub { goah::Modules::Productmanagement::ReadData('products',$_[0],$uid) };

	return \%variables;
}


#
# Function: WriteNewBasket
#
#   Write new basket to database
#
# Parameters:
#
#   None, uses HTTP variables
#
# Returns:
#
#   Fail - 0 
#   Success - ID for created basket
#
sub WriteNewBasket {

	if($_[0]=~/goah::Modules::Basket/) {
		return 0;
	}

	my $q = CGI->new();
	use goah::Database::Baskets;
	my $db = new goah::Database::Baskets;

	my %data;
	my %fieldinfo;
	# Loop trough HTTP variables based on basketdbfields -hash definition
	while(my($key,$value) = each (%basketdbfields)) {
		%fieldinfo = %$value;

		if($fieldinfo{'field'} eq 'billingid' || $fieldinfo{'field'} eq 'locationid') {
			next;
		}
		if($fieldinfo{'required'} == '1' && !(length($q->param($fieldinfo{'field'}))) ) {
			goah::Modules->AddMessage('warn',__('Required field').' <b>'.$fieldinfo{'name'}.'</b> '.__('empty!'));
			return 0;
		}

		if($q->param($fieldinfo{'field'})) {
			$data{$fieldinfo{'field'}} = decode("utf-8",$q->param($fieldinfo{'field'}));
		}
	}

	# Assign default location id's for shipping and billing
	my $locref = goah::Modules::Customermanagement->ReadDefaultLocations($q->param('companyid'));
	unless($locref == 0) {
		my %loc = %$locref;
		$data{'locationid'} = $loc{'shipping'};
		$data{'billingid'} = $loc{'billing'};
		goah::Modules->AddMessage('debug',"Assigned default shipping id ".$loc{'shipping'}." and billing id ".$loc{'billing'},__FILE__,__LINE__); 
	}

	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$data{'created'} = sprintf("%04d-%02d-%02d %02d:%02d:%02d",$year+1900,$mon+1,$mday,$hour,$min,$sec);
	$data{'updated'} = sprintf("%04d-%02d-%02d %02d:%02d:%02d",$year+1900,$mon+1,$mday,$hour,$min,$sec);

	if($q->param('state')) {
		$data{'state'}=$q->param('state');
	} else {
		$data{'state'} = '0';
	}
	$data{'ordernum'} = '0';
	$data{'ownerid'} = $_[0];

	my $basket = $db->insert(\%data);
	return $basket->id;
}

#
# Function: RunCron
#
#   This function is used to search trough and run recurring baskets according
#   to their dates
#
# Parameters:
#   
#   None
#
# Returns:
#
#   1 - Success
#   0 - Fail
#
sub RunCron {

	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	my $now = sprintf("%04d-%02d-%02d",$year+1900,$mon+1,$mday);
	use goah::Database::Baskets;
	my @baskets = goah::Database::Baskets->search_where({ state => '2', nexttrigger => { '<=', $now } });

	my $fail=0;
	unless(@baskets) {
		goah::Modules->AddMessage('debug',__("No baskets found for cron run."),__FILE__,__LINE__);
	} else {
		foreach(@baskets) {
			goah::Modules->AddMessage('debug',"Running recurring basket id ".$_->id." which is due at ".$_->nexttrigger,__FILE__,__LINE__);
			if(WriteRecurringBasket($_->id)) {
				goah::Modules->AddMessage('info',__("Recurring basket ran succesfully. Id: ").$_->id,__FILE__,__LINE__);
			} else {
				goah::Modules->AddMessage('error',__("Coudln't run recurring basket with id ").$_->id,__FILE__,__LINE__);
				$fail=1;
			}
		}
	}

	if($fail) {
		return 0;
	} 

	return 1;	
}

#
# Function: WriteRecurringBasket
#   
#   This function is used to convert recurring basket into an actual basket.
#
# Parameters:
#  
#   id - Recurring basket id which to convert into actual basket
#
# Returns:
#
#   1 - Success
#   0 - Fail
#
sub WriteRecurringBasket {

	if($_[0]=~/goah::Modules::Basket/) {
		shift;
	}

	unless($_[0]) {
		goah::Modules->AddMessage('error',__("Can't run recurring basket! Basket id is missing!"),__FILE__,__LINE__);
		return 0;
	}

	use goah::Database::Baskets;
	my $rbasket = goah::Database::Baskets->retrieve($_[0]);
        my $db = new goah::Database::Baskets;

	# Update last triggered timestamp. The last trigger option will be set to current date,
	# but since we need the actual time span we'll use dayinmonth -variable to store the 
	# date which will end up on basket information and invoices.
	my $repeat = $rbasket->repeat;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$rbasket->lasttrigger(sprintf("%04d-%02d-%02d",$year+1900,$mon+1,$mday));
	my @lasttrigger=split("-",sprintf("%04d-%02d-%02d",$year+1900,$mon+1,$rbasket->dayinmonth));

	# Calculate next date when to run
	$mon++;
	$year+=1900;

	$mon+=$repeat;
	if($mon>12) {
		$year++;
		$mon-=12;
	}

	$rbasket->nexttrigger(sprintf("%04d-%02d-%02d",$year,$mon,$rbasket->dayinmonth));

	my @nexttrigger=split("-",$rbasket->nexttrigger);

	my %data;
	my %fieldinfo;
	# Loop trough variables based on basketdbfields -hash definition
	while(my($key,$value)=each(%basketdbfields)) {

		%fieldinfo = %$value;
		if($fieldinfo{'field'} eq 'id') { next; }

		if($fieldinfo{'field'}=~/info/) {
			$data{$fieldinfo{'field'}}.="\n".__("Automatically created from recurring basket.");
			$data{$fieldinfo{'field'}}.=" ".$lasttrigger[2].".".$lasttrigger[1].".".$lasttrigger[0];
			$data{$fieldinfo{'field'}}.=" - ".$nexttrigger[2].".".$nexttrigger[1].".".$nexttrigger[0];
		} else {
			$data{$fieldinfo{'field'}} = $rbasket->get($fieldinfo{'field'});
		}

	}

	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$data{'created'} = sprintf("%04d-%02d-%02d %02d:%02d:%02d",$year+1900,$mon+1,$mday,$hour,$min,$sec);
	$data{'updated'} = sprintf("%04d-%02d-%02d %02d:%02d:%02d",$year+1900,$mon+1,$mday,$hour,$min,$sec);
	$data{'state'} = '0';

	my $basket = $db->insert(\%data);

	my $rbasketrowsp=ReadBasketrows($rbasket->id,-1,1);

	if($rbasketrowsp==0) {
		goah::Modules->AddMessage("error",__("Couldn't read rows for recurring basket! Can't create basket!"),__FILE__,__LINE__);
		return 0;
	}

	use goah::Database::Basketrows;
	my $rdb = goah::Database::Basketrows->new;
	my %rbasketrows=%$rbasketrowsp;
	foreach my $key (keys %rbasketrows) {

		my $rowp = $rbasketrows{$key};
		my %row = %$rowp;
		my %rowdata;

		# Basket rows total is at index 'baskettotal', so we'll need to skip that one
		if($row{'baskettotal'}) { next; }

		foreach my $fkey (keys %basketrowdbfields) {
			my $field = $basketrowdbfields{$fkey}{'field'};

			if($field eq 'id') {
				# Do nothing, since we're using auto increment primary keys
			} elsif($field=~/rowinfo/) {
				$rowdata{$field}=$row{$field}." \n".$lasttrigger[2].".".$lasttrigger[1].".".$lasttrigger[0];
				$rowdata{$field}.=" - ".$nexttrigger[2].".".$nexttrigger[1].".".$nexttrigger[0];
			} elsif($field=~/basketid/) {
				$rowdata{$field}=$basket->id;
			} else {
				$rowdata{$field}=$row{$field};
			}
		}


		my $debug="Rowdata keys: ".join(";",keys(%rowdata));
		$debug.="<br>Rowdata values: ".join(";",values(%rowdata));

		$debug.="<br><br>Row keys: ".join(";",keys(%row));
		$debug.="<br>Row values: ".join(";",values(%row));
		goah::Modules->AddMessage('debug',$debug,__FILE__,__LINE__);
		$rdb->insert(\%rowdata);
	}
	$rbasket->update;
	return 1;
}

#
# Function: ReadBaskets
#
#   Read active baskets from the database.
#
# Parameters:
#
#   id - Id to retrieve from database. If omitted every basket is returned
#   ownerid - UID to search baskets
#   state - Which basket states to include (open, recurring ...), optionally separated with commas
#   separate - If set separate basket states into different hashes
#   customer - Customer id to fetch
#
# Returns:
#
#   Success - Pointer to Class::DBI results
#   Fail - 0 
#
sub ReadBaskets {

	if($_[0] && $_[0]=~/goah::Modules::Basket/) {
		shift;
	}

	my $db;
	my $sort;
	if($_[2] && !length($_[3])) {
		$sort='nexttrigger';
	} else {
		$sort = 'updated';
	}

	my %search;
	my @data;
	use goah::Db::Baskets::Manager;

	if(!($_[0]) || $_[0] eq '') {
		my $state=0;
		my @states;
		my @owners;

		if($_[2]) {
			my $tmp=$_[2];
			@states=@$tmp;
			goah::Modules->AddMessage('debug',"Searching states ".join(";",@states));
			$search{'state'} = \@states;
		}

		if($_[1]) {
			my $tmp=$_[1];
			my @owners=@$tmp;
			if(scalar(@owners)>=1) {
				$search{'ownerid'}=\@owners;
			}
		}

		if($_[4] && $_[4]=~/^[0-9]+$/) {
			$search{'companyid'} = $_[4];	
		}
	} else {
		$search{'id'}=$_[0];
	}

	my $datap=goah::Db::Baskets::Manager->get_baskets(\%search,sort_by => $sort);

	#@data = $db->search_where(\%search, { order_by => $sort });

	unless($datap) {
		goah::Modules->AddMessage('warn',__("No baskets found!"));
		return 0;
	}

	@data=@$datap;

	my %baskets;
	my $i=10000; # sort counter
	my $f; # Field, helper variable
	my $br; # Basket row, helper variable
	my %basketrows;
	my @rows;
	my $total=0;
	my $totalvat=0;
	my $groupstates=$_[3];
	my %sorthash; # Helper for sorting baskets by customer name
	use goah::Modules::Customermanagement;
	foreach my $b (@data) {

		my $cust;
		$cust=goah::Modules::Customermanagement->ReadCompanydata($b->companyid,1) if($b->companyid>0);
		my %customer;
		
		if($cust) {
			%customer=%$cust;
		} else {
			$customer{'name'}=__("Error!");
		}
		my $cname=lc($customer{'name'});
		$cname=~s/ä/zz/g;
		$cname=~s/ö/zzz/g;
		$cname=~s/å/o/g;
		$cname=~s/Ä/zz/g;
		$cname=~s/Ö/zzz/g;
		$cname=~s/Å/o/g;
		$cname=~s/\ /_/g;


		foreach my $k (keys(%basketdbfields)) {
			if($groupstates) {
				my $state=$b->state;
				my $statename=$basketstates{$state};
				$f=$basketdbfields{$k}{'field'};		
				$baskets{$state}{$i}{$f}=$b->$f;
				$baskets{$state}{'name'}=$statename;

				$sorthash{$state}{$cname.".".$i}=$i unless ($b->state eq 2);
			} else {
				$f=$basketdbfields{$k}{'field'};		
				if($_[0] || length($_[0])) {
					if($f=~/state/i) {
						goah::Modules->AddMessage('debug',"Got state: ".$b->$f,__FILE__,__LINE__);
						$baskets{'statename'}=$basketstates{$b->$f};
						goah::Modules->AddMessage('debug',"Set state name: ".$baskets{'statename'},__FILE__,__LINE__);
					}
					$baskets{$f}=$b->$f;
				} else {
					$baskets{$i}{$f}=$b->$f;
					$sorthash{$cname.".".$i}=$i unless ($b->state eq 2);
				}
			}
		}

		$br=ReadBasketrows($b->id);
		unless($br) {
			goah::Modules->AddMessage('error',__("Couldn't read basket's rows with basket id ").$b->id."!",__FILE__,__LINE__);
			return 0;
		}
		%basketrows=%$br;
		$total+=$basketrows{-1}{'baskettotal'};
		$totalvat+=$basketrows{-1}{'baskettotal_vat'};
		@rows=sort keys(%basketrows);
		my $state=$b->state;

		if($groupstates) {
			$baskets{$state}{$i}{'total'}=$basketrows{-1}{'baskettotal'};
			$baskets{$state}{$i}{'total_vat'}=$basketrows{-1}{'baskettotal_vat'};
			$baskets{$state}{$i}{'rows'}=scalar(@rows);
			$baskets{$state}{$i}{'rows'}--; # This since @rows has index -1 which contains sums from rows

			if($state eq "2") {
				$baskets{$state}{$i}{'lasttrigger'}=$b->lasttrigger;
				$baskets{$state}{$i}{'nexttrigger'}=$b->nexttrigger;
			}
		} else {
			# Check if we're reading individual basket or do we need additional 
			# counter included
			if($_[0] || length($_[0])) {
				$baskets{'total'}=$basketrows{-1}{'baskettotal'};
				$baskets{'total_vat'}=$basketrows{-1}{'baskettotal_vat'};
				$baskets{'rows'}=scalar(@rows);
				$baskets{'rows'}--;
			} else {
				$baskets{$i}{'total'}=$basketrows{-1}{'baskettotal'};
				$baskets{$i}{'total_vat'}=$basketrows{-1}{'baskettotal_vat'};
				$baskets{$i}{'rows'}=scalar(@rows);
				$baskets{$i}{'rows'}--;
			}

			if($state eq "2") {
				my $nexttrigger = goah::GoaH::FormatDate($b->nexttrigger);
				$nexttrigger=~s/^..\.//;
				my @nexttrigger_arr=split(/\./,$nexttrigger);

				my $headingtotal=$baskets{'headingtotal'}{$nexttrigger}+$basketrows{-1}{'baskettotal'};
				my $headingtotalvat=$baskets{'headingtotal_vat'}{$nexttrigger}+$basketrows{-1}{'baskettotal_vat'};
				$baskets{$i}{'triggerheading'}=$nexttrigger;
				$baskets{$i}{'lasttrigger'}=$b->lasttrigger;
				$baskets{$i}{'nexttrigger'}=$b->nexttrigger;

				$headingtotal=0 unless($headingtotal);
				$headingtotalvat=0 unless($headingtotalvat);

				$baskets{'headingtotal'}{$nexttrigger}=goah::GoaH->FormatCurrencyNopref($headingtotal,0,0,'out',0);
				$baskets{'headingtotal_vat'}{$nexttrigger}=goah::GoaH->FormatCurrencyNopref($headingtotalvat,0,0,'out',0);
				$baskets{$i}{'repeat'}=$b->repeat;
				$baskets{$i}{'dayinmonth'}=$b->dayinmonth;
				
				$sorthash{$nexttrigger_arr[1].'.'.$nexttrigger_arr[0].'.'.$cname.'.'.$i}=$i;
			}
		}

		$i++;
	} 

	$total=0 unless($total);
	$totalvat=0 unless($totalvat);

	$baskets{-1}{'total'}=goah::GoaH->FormatCurrencyNopref($total,0,0,'out',0);
	$baskets{-1}{'totalvat'}=goah::GoaH->FormatCurrencyNopref($totalvat,0,0,'out',0);
	$baskets{-1}{'vat'}=goah::GoaH->FormatCurrencyNopref( ($totalvat-$total) ,0,0,'out',0);

	unless($_[0] || !$_[0] eq '') {
		# Sort baskets hash by customer names, unless we're reading recurring baskets
		$i=1000000;
		my %sortedbaskets;
		if($groupstates) {
			foreach my $s (keys(%baskets)) {
				
				next if($s<0);

				my $grouppointer=$baskets{$s};
				my %group=%$grouppointer;

				my $sortpointer=$sorthash{$s};
				my %sortgroup=%$sortpointer;
				foreach my $sort (sort keys(%sortgroup)) {
					my $sort_i = $sortgroup{$sort};
					$sortedbaskets{$s}{$i}=$group{$sort_i};
					$i++;
				}
			}
		} else {
			foreach my $sort (sort keys(%sorthash)) {
				my $sort_i = $sorthash{$sort};
				$sortedbaskets{$i}=$baskets{$sort_i};
				$i++;
			}
		}	

		$sortedbaskets{-1}=$baskets{-1};
		$sortedbaskets{'headingtotal'}=$baskets{'headingtotal'};
		$sortedbaskets{'headingtotal_vat'}=$baskets{'headingtotal_vat'};

		return \%sortedbaskets;
	} 
	
	return \%baskets;
		
}

#
# Function: UpdateBasket
#
#   Update actual basket information. This doesn't include any
#   row data, just the basic basket information.
#
# Parameters:
#
#   None, uses HTTP variables.
#
# Returns:
#
#   Fail - 1
#   Success - 0
#
sub UpdateBasket {

	my $q = CGI->new();
	unless($q->param('id')) {
		goah::Modules->AddMessage('error',__('ID -field missing.')." ".__("Can't update information in database!"));
		return 1;
	}

	use goah::Database::Baskets;
	my $data = goah::Database::Baskets->retrieve($q->param('id'));

	# Loop trough fields for the database
	my %fieldinfo;
	while(my($key,$value) = each (%basketdbfields)) {
		%fieldinfo = %$value;
		 if($fieldinfo{'required'} == '1' && !(length($q->param($fieldinfo{'field'}))) ) {
		 	# Using variable just to make source look nicer
			my $errstr = __('Required field').' <b>'.$fieldinfo{'name'}.'</b> '.__('empty!')." ";
			$errstr.= __("Leaving value unaltered.");
			goah::Modules->AddMessage('warn',$errstr);
		} else {
			if(length($q->param($fieldinfo{'field'}))) {
				$data->set($fieldinfo{'field'} => decode('utf-8',$q->param($fieldinfo{'field'})));
			} else {
				 $data->set($fieldinfo{'field'} => '');
			}
		}
	}

	# Add fields for recurring baskets, if necessary
	if($data->state eq "2") {

		my $recalc=0;
		if($q->param('repeat')) {
			unless($q->param('repeat') eq $data->repeat) {
				$recalc=1;
			}
			if($q->param('repeat')=~/[0-9]{1,2}/) {
				$data->repeat($q->param('repeat'));
			} else { 
				goah::Modules->AddMessage('warn',__("Value for repeat every n month isn't valid. Setting value to 1."));
				$data->repeat(1);
			}
		}

		if($q->param('dayinmonth')) {
			unless($q->param('dayinmonth') eq $data->dayinmonth) {
				$recalc=1;
			}
			if($q->param('dayinmonth')=~/[0-9]{1,2}/) {
				if($q->param('dayinmonth') > 0 && $q->param('dayinmonth') <= 28) {
					$data->dayinmonth($q->param('dayinmonth'));
				} else {
					goah::Modules->AddMessage('warn',__("Value for day of month isn't in range. Setting value to 1."));
					$data->dayinmonth(1);
				}
			} else {
				goah::Modules->AddMessage('warn',__("Value for day of month isn't valid. Setting value to 1."));
				$data->dayinmonth(1);
			}
		}

		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
		my $nextyear=0;
		my $nextmonth=0;
		if($q->param('nexttrigger_year')) {
			if($q->param('nexttrigger_year')=~/^[0-9]{4}$/) {
				if($year+1900 > $q->param('nexttrigger_year')) {
					goah::Modules->AddMessage('error',__("Can't change next trigger time to past!"),__FILE__,__LINE__);
				} else {
					$nextyear=$q->param('nexttrigger_year');
					$recalc=1;
				}
			} else {
				goah::Modules->AddMessage('error',__("Next year to trigger isn't valid. Won't change the value."),__FILE__,__LINE__);
			}
		}

		if($q->param('nexttrigger_month')) {
			if($q->param('nexttrigger_month')=~/^[0-9]{1,2}$/) {
				if($q->param('nexttrigger_month') >= 1 && $q->param('nexttrigger_month') <=12) {

					if( ($q->param('nexttrigger_month') > $mon+1) || $nextyear>0) {
						$nextmonth=$q->param('nexttrigger_month');
						$recalc=1;
					}

				} else {
					goah::Modules->AddMessage('error',__("Next month to trigger isn't valid. Won't change the value."),__FILE__,__LINE__);
				}
			} else {
				goah::Modules->AddMessage('error',__("Next month to trigger isn't valid. Won't change the value."),__FILE__,__LINE__);
			}
		}
	
		if($recalc==1) {

			$mon++;
			$year+=1900;
		
			if($mday >= $data->dayinmonth) {
				$mon++;
			} 

			$mday=$data->dayinmonth;

			if($mon>12) {
				$year++;
				$mon-=12;
			}

			if($nextyear!=0) {
				$year=$nextyear;
			}

			if($nextmonth!=0) {
				$mon=$nextmonth;
			}

			$data->lasttrigger(0);
			$data->nexttrigger(sprintf("%04d-%02d-%02d",$year,$mon,$mday));
		}
	}

	# Finally update basket modified -timestamp
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$data->set('updated' =>sprintf("%04d-%02d-%02d %02d:%02d:%02d",$year+1900,$mon+1,$mday,$hour,$min,$sec));
	$data->update();
	return 0;
}

#
# Function: UpdateBasketRow
#
#   Update values for individual basket row. Update obviously
#   doesn't touch into referencing id values, so rows can't
#   be moved or copied to different baskets. However deleting
#   an row is included into functionality.
#
# Parameters:
#
#  None, uses HTTP variables 
#
# Returns:
#
#   Fail - 0
#   Success - 1
#
sub UpdateBasketRow {

	my $q = CGI->new();
	unless($q->param('rowid')) {
		goah::Modules->AddMessage('error',__('ID -field missing.')." ".__("Can't update row information in database!"));
		return 1;
	}

	use goah::Database::Basketrows;
	my $rowinfo = goah::Database::Basketrows->retrieve($q->param('rowid')-0);

	unless($rowinfo && ($rowinfo->id eq $q->param('rowid'))) {
		goah::Modules->AddMessage('error',__("Can't read row information from database.")." ".__("Can't update row information in database!"));
		return 0;
	}

	if($q->param('delete') eq 'on') {
		unless($rowinfo->remoteid eq '') {
			# If we've got an remote id remove the assignment as well. Currently
			# this applies only to tracked hours, but this isn't too big of a deal
			# to expand for other uses as well
			my $remoteid=$rowinfo->remoteid;
			$remoteid=~s/^.*://;
			use goah::Modules::Tracking;
			unless(goah::Modules::Tracking->RemoveHoursFromBasket($remoteid)) {
				goah::Modules->AddMessage('error',__("Couldn't remove hour assignment from the basket! Won't delete row!"),__FILE__,__LINE__);
				return 1;
			}
		}
		goah::Modules->AddMessage('info',__("Row deleted from basket"));
		$rowinfo->delete;
		return 0;
	}

	my $prodinfo = goah::Modules::Productmanagement->ReadData('products',$rowinfo->productid,$uid);
	my %prod = %$prodinfo;

	my %fieldinfo;
	while(my($key,$value)= each (%basketrowdbfields)) {
		%fieldinfo = %$value;
		if($fieldinfo{'field'} eq 'productid' || $fieldinfo{'field'} eq 'basketid' || $fieldinfo{'id'} eq 'id') {
			next;
		}

		if($q->param($fieldinfo{'field'}) || length($q->param($fieldinfo{'field'}))>0) {

			if($fieldinfo{'field'} eq 'purchase') {
			
				my $purchase='na';
				if($q->param('purchase_orig') ne $q->param('purchase')) {
					$purchase=goah::GoaH->FormatCurrencyNopref($q->param('purchase'),0,0,'in',0);
				} elsif($q->param('purchase_vat_orig') ne $q->param('purchase_vat')) {
					my $prodpoint = goah::Modules::Productmanagement::ReadData(	'products',
													$q->param('productid'),
													$uid,$settref,1);
					if($prodpoint==0) {
						goah::Modules->AddMessage('error',
									__("Can't read VAT class for product id ").$q->param('productid'),
									__FILE__,__LINE__,caller());

					} else {
						my %prod = %$prodpoint;
						my $vatp=goah::Modules::Systemsettings->ReadSetup($prod{'vat'});
						my %vat;
						unless($vatp) {
							goah::Modules->AddMessage('error',__("Couldn't get VAT class from setup! VAT calculations are incorrect!"),__FILE__,__LINE__);
						} else {
							%vat=%$vatp;
						}
						$purchase=goah::GoaH->FormatCurrencyNopref($q->param('purchase_vat'),$vat{'value'},0,'in',0);
					}
				}
	
				unless($purchase eq 'na') {
					$rowinfo->set('purchase' => $purchase);
				}

			} elsif($fieldinfo{'field'} eq 'sell') {

				my $sell='na';
				if($q->param('sell_orig') ne $q->param('sell')) {
					$sell=goah::GoaH->FormatCurrencyNopref($q->param('sell'),0,0,'in',0);
				} elsif($q->param('sell_vat_orig') ne $q->param('sell_vat')) {
					my $prodpoint = goah::Modules::Productmanagement::ReadData('products',$q->param('productid'),$uid,$settref,1);
					if($prodpoint==0) {
						goah::Modules->AddMessage('error',__("Can't read VAT class for product id ").$q->param('productid'),__FILE__,__LINE__);
					} else {
						my %prod = %$prodpoint;
						my $vatp=goah::Modules::Systemsettings->ReadSetup($prod{'vat'});
						my %vat;
						unless($vatp) {
							goah::Modules->AddMessage('error',__("Couldn't get VAT class from setup! VAT calculations are incorrect!"),__FILE__,__LINE__);
						} else {
							%vat=%$vatp;
						}
						$sell=goah::GoaH->FormatCurrencyNopref($q->param('sell_vat'),$vat{'value'},0,'in',0);
					}
				}

				unless($sell eq 'na') {
					$rowinfo->set('sell' => $sell);
				}

			} elsif($fieldinfo{'field'} eq 'amount') {
				# Feed validation
				my $amount=$q->param($fieldinfo{'field'});
				$amount=~s/,/./g;
				$amount=~s/\ //;
				unless($amount=~/^-?([0-9]+\.?[0-9]*)$/) {
					goah::Modules->AddMessage('warn',__("Amount field is not numeric. Setting amount to 0"));
					$amount=0.00;
				}
				$rowinfo->set($fieldinfo{'field'} => $amount);

				unless($rowinfo->remoteid eq '') {
					goah::Modules->AddMessage('debug',"Updating remote amount",__FILE__,__LINE__);
					# If we have an remote id update remote values accordingly.
					# Currently this applies only to tracked hours
					my $remoteid=$rowinfo->remoteid;
					$remoteid=~s/^.*://;
					use goah::Modules::Tracking;
					unless(goah::Modules::Tracking->UpdateHoursFromBasket($remoteid,$amount)) {
						goah::Modules->AddMessage('error',__("Couldn't update tracked hours according to new amount!"),__FILE__,__LINE__);
					}
				}

			} else {
				my $tmprowinfo=decode("utf-8",$q->param($fieldinfo{'field'}));
				$tmprowinfo=~s/€/&euro;/g;
				$rowinfo->set($fieldinfo{'field'} => $tmprowinfo);
			}
			
		} else {
			#goah::Modules->AddMessage('debug',"Empty value via form for ".$fieldinfo{'field'});
			if($fieldinfo{'field'} eq 'purchase') {
				#goah::Modules->AddMessage('debug',"Default purchase price applied");
				$rowinfo->set('purchase' => $prodinfo->purchase);
			} elsif($fieldinfo{'field'} eq 'sell') {
				$rowinfo->set('sell' => $prodinfo->sell);
			} elsif($fieldinfo{'field'} eq 'rowinfo') {
				$rowinfo->set('rowinfo' => '');
			}
		}
	}

	$rowinfo->update();

	#
	# Finally, update last modified information 
	# for the basket
	#   TODO: This functionality could be done as an function, i.e. TouchBasket() since it's
	#         used on various locations.
	use goah::Database::Baskets;
	my $data = goah::Database::Baskets->retrieve($q->param('target'));
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$data->set('updated' =>sprintf("%04d-%02d-%02d %02d:%02d:%02d",$year+1900,$mon+1,$mday,$hour,$min,$sec));
	$data->update();

	return 0;
}

# 
# Function: AddToBasket
#
#   Function to handle adding product(s) to basket. Function
#   understands both addproducts[] -array and productid -string
#   via HTTP variables, so the same function can be used on both,
#   adding individual product or several products at once to 
#   basket.
#
# Parameters:
#
#   barcode - EAN code for the product to add into basket. Optional.
#   productcode - Manufacturer product code
#
# Returns:
#
#   Success - 0
#   Fail - 1
#
sub AddToBasket {

	my %data;
	my %fieldinfo;

	my $q = CGI->new();
	use goah::Modules::Productmanagement;

	# Addproducts is an array which we need to loop trough
	my $basketid;
	if($q->param('basketid')) {
		$basketid = $q->param('basketid');
	} else {
		goah::Modules->AddMessage('error',__("Can't add product(s) to basket. Basket id is missing."));
		return 1;
	}
	my $purchase;
	my $sell;
	my $amount;
	my $desc='';
	my $prod;
	my $hourid;

	# Loop trough an array of products
	if($q->param('addproducts')) {

		my @products = $q->param('addproducts');
		foreach my $prodrow (@products) {
			
			$hourid=-1;
			# If we're adding hours we need to pull some additional info from the database
			if($q->param('hours_'.$prodrow)) {
				
				use goah::Modules::Tracking;

				# Read info for tracked hours
				my $hourp=goah::Modules::Tracking->ReadData('hours','id'.$prodrow,1);
				if($hourp==0) {
					goah::Modules->AddMessage('error',__("Couldn't read tracked hours from database!"),__FILE__,__LINE__);
					next;
				}

				my %hours=%$hourp;

				# Read info for the product included
				goah::Modules->AddMessage('debug','Read product info for id '.$hours{'productcode'},__FILE__,__LINE__);
				my $prodp=goah::Modules::Productmanagement->ReadData('products',$hours{'productcode'},$uid,$settref,1);
				if($prodp==0) {
					goah::Modules->AddMessage('error',__("Coudln't read product data for tracked hours!"),__FILE__,__LINE__);
					next;
				}
				my %product=%$prodp;

				$hourid=$hours{'id'};
				$prod=$product{'id'};

				my $vatp=goah::Modules::Systemsettings->ReadSetup($product{'vat'});
				my %vat;
				unless($vatp) {
					goah::Modules->AddMessage('error',__("Couldn't get VAT class from setup! VAT calculations are incorrect!"),__FILE__,__LINE__);
				} else {
					%vat=%$vatp;
				}

				$purchase=goah::GoaH->FormatCurrency($product{'purchase'},$vat{'value'},$uid,'out',$settref);;
				$sell=goah::GoaH->FormatCurrency($product{'sell'},$vat{'value'},$uid,'out',$settref);
				$amount=$hours{'hours'};
				$desc=$hours{'day'}.' '.$hours{'username'}.': '.$hours{'description'};


			} else {
				$prod = $prodrow;
				$purchase = $q->param('purchase_'.$prodrow);
				$sell = $q->param('sell_'.$prodrow);
				$amount = $q->param('amount_'.$prodrow);
			}
				
			# Feed validation
			$amount=~s/,/./;
			$amount=~s/\ //;
			unless($amount=~/^([0-9\.]+)$/) {
				goah::Modules->AddMessage('warn',__("Amount field is not numeric. Setting amount to 0"));
				$amount=0.00;
			}

			# Assign hours to basket
			if($hourid!=-1) {
				unless(goah::Modules::Tracking->AddHoursToBasket($hourid,$basketid)==1) {
					goah::Modules->AddMessage('error',"Can't assign an basket for hours! Can't add product to basket!",__FILE__,__LINE__);
					return 1;
				}
			}

			if(AddProductToBasket($prod,$basketid,$purchase,$sell,$amount,$desc,1,"timetracking:".$hourid)==1) {
				goah::Modules->AddMessage('debug',"Added productid $prod to basket",__FILE__,__LINE__);
			} else {
				goah::Modules->AddMessage('error',"Can't add product id $prod to basket!",__FILE__,__LINE__);
			}
		}

	} elsif ($q->param('productid') || $_[0]) {
		# Add only one product
		my $prod;

		# If we have an EAN-code, or Product code, then read product information via that
		if($_[0]) {
			if($_[1] eq "ean") {
				goah::Modules->AddMessage('debug',"Adding product via barcode ".$_[0],__FILE__,__LINE__);
				$prod = goah::Modules::Productmanagement->ReadProductByEAN($_[0]);

				if($prod==0) {
					goah::Modules->AddMessage('error',__("Product not found"),__FILE__,__LINE__);
					return 1;
				}
				# ReadProductByEAN doesn't respond with proper data, so we need to 
				# read additional details separately
				my $proddataptr = goah::Modules::Productmanagement->ReadData('products',$prod,$uid);
				if($proddataptr == 0) {
					goah::Modules->AddMessage('error',"Something went badly wrong...",__FILE__,__LINE__);
				} 
				my %proddata = %$proddataptr;
				$purchase = $proddata{'purchase'};
				$sell = $proddata{'sell'};
			}
			if($_[1] eq "productcode") {
				goah::Modules->AddMessage('debug',"Adding product via product code ".$_[0],__FILE__,__LINE__);
				my $prodpointer = goah::Modules::Productmanagement->ReadProductByCode($_[0],'',1,$uid,$settref);

				unless($prodpointer) {
					goah::Modules->AddMessage('error',"Product code not found",__FILE__,__LINE__);
					return 1;
				} else {
					
					# Fetch only first product from hash, since we won't add multiple
					# products to basket via only product code
					my %proddata=%$prodpointer;
					$prodpointer=each(%proddata);
					%proddata=%{$proddata{$prodpointer}};
					
					$purchase=$proddata{'purchase'};
					$sell=$proddata{'sell'};
					$prod=$proddata{'id'};
					goah::Modules->AddMessage('debug',"Purchase $purchase, sell $sell, id $prod",__FILE__,__LINE__);
				}
			}
			$amount=1;
		} else {
			$prod = $q->param('productid');
			$purchase = $q->param('purchase');
			$sell = $q->param('sell');
			$amount = $q->param('amount');
		}

		if(AddProductToBasket($prod,$basketid,$purchase,$sell,$amount)==1) {
			goah::Modules->AddMessage('debug',"Added productid $prod to basket");
		} else {
			goah::Modules->AddMessage('error',"Can't add product id $prod to basket!");
		}
	} else {
		goah::Modules->AddMessage('error',__("Can't add product to basket. Nothing to add!"));
		return 1;
	}

	#
	# Last, update last modified information for the basket
	#
        use goah::Database::Baskets;
	my $bdata = goah::Database::Baskets->retrieve($q->param('basketid'));
	unless($bdata) {
		goah::Modules->AddMessage('debug',"Can't update baket, nothing found with ".$q->param('basketid'));
		return 1;
	}
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$bdata->set('updated' =>sprintf("%04d-%02d-%02d %02d:%02d:%02d",$year+1900,$mon+1,$mday,$hour,$min,$sec));
	$bdata->update();
	$bdata->commit;
	return 0;

}


#
# Function: AddProductToBasket
#
#   Basically an helper function to assist adding products to basket.
#   This function should be called only from AddToBasket -function
#   and it's only purpose is to make loops siplier.
#
# Parameters:
#
#   id - Product id to be added
#   basketid - Basket id where product is added
#   purchase - Purchase price
#   sell - Selling price
#   amount - Row amount 
#   rowinfo - Additional information for the row
#   vat0 - Leave vat caclulations out of the process, for example when importing hours to basket
#   remoteid - To maintain tracking of products which are imported from ie. timetracking
#
sub AddProductToBasket {

	unless($_[0]) {
		goah::Modules->AddMessage('error',__("Can't add individual product to basket. Product ID is missing."));
		return 0;
	}

	#goah::Modules->AddMessage('debug',"Fetch product info with uid ".$uid,__FILE__,__LINE__); 
	my $pinfo = goah::Modules::Productmanagement->ReadData('products', $_[0], $uid,$settref);
	if($pinfo == 0) {
		goah::Modules->AddMessage('error', __("Invalid product id. Can't add product to basket.")." (".$_[0].")");
		return 1;
	}
	my %prod = %$pinfo;
	my %data;

	$data{'productid'} = $_[0];
	$data{'basketid'} = $_[1];

	my $vatp=goah::Modules::Systemsettings->ReadSetup($prod{'vat'});
	my %vat;
	unless($vatp) {
		goah::Modules->AddMessage('error',__("Couldn't get VAT class from setup! VAT calculations are incorrect!"),__FILE__,__LINE__);
	} else {
		%vat=%$vatp;
	}

	goah::Modules->AddMessage('debug',"Calculating prices with VAT ".$vat{'value'},__FILE__,__LINE__);
	$data{'purchase'} = goah::GoaH->FormatCurrencyNopref($_[2],$vat{'value'},1,'in',0);
	$data{'sell'} = goah::GoaH->FormatCurrencyNopref($_[3],$vat{'value'},1,'in',0);
	$data{'amount'} = decode("utf-8",$_[4]);
	$data{'rowinfo'} = decode("utf-8",$_[5]);
	$data{'code'} = $prod{'code'};
	$data{'name'} = $prod{'name'};
	$data{'remoteid'}=$_[7];

	use goah::Database::Basketrows;
	goah::Database::Basketrows->insert(\%data);

	return 1;
}



#
# Function: ReadBasketrows
#
#   Read indivirual rows for basket. Prices are formatted (w or w/o VAT) based on
#   user settings.
#
# Parameters:
#
#   basketid - Basket id from the database
#   rowid - If set read individual row from the database. If omitted read whole basket.
#   internal - If set don't do any currency formatting. This is to speed up internal processing of data.
#
# Returns:
#
#   Success - Hash reference to row data.
#   Fail - 0 
#
sub ReadBasketrows {

	if($_[0]=~/goah::Modules::Basket/) {
		shift;
	}

	unless($_[0] || $_[1]) {
		goah::Modules->AddMessage('error',__("Can't read rows for basket! Basket id is missing!"));
		return 0;
	}

	use goah::Db::Basketrows::Manager;
	use goah::Database::Products;
	my %rowdata;
	my $field;
	my $baskettotal=0;
	my $baskettotal_vat=0;

	if( !($_[1]) || $_[1]==-1) {
		# We don't have id for individual row, read all rows for
		# the basket
		my $datap = goah::Db::Basketrows::Manager->get_basketrows({basketid => $_[0]},  sort_by => 'id' );
		my @data;
		
		unless($datap) {
			goah::Modules->AddMessage('debug',"No rows for basket id $_[0]",__FILE__,__LINE__);
			return 0;
		}

		@data=@$datap;


		my $i=10000;
		foreach my $row (@data) {
			
			$i++;

			my $prodpoint = goah::Modules::Productmanagement::ReadData('products',$row->productid,$uid,$settref,$_[2]); 
			unless($prodpoint) {
				goah::Modules->AddMessage('error',__("Couldn't read product data for id ").$row->productid."!",__FILE__,__LINE__);
				return 0;
			}
			my %prod = %$prodpoint;
			foreach my $key (keys %basketrowdbfields) {
				$field = $basketrowdbfields{$key}{'field'};

				my %vat;
				my $vatp=goah::Modules::Systemsettings->ReadSetup($prod{'vat'});
				unless($vatp) {
					goah::Modules->AddMessage('error',__("Couldn't get VAT class from setup! VAT calculations are incorrect!"),__FILE__,__LINE__);
				} else {
					%vat=%$vatp;
				}

				if($field eq 'purchase' || $field eq 'sell') {
					unless($_[2]) {
						if($_[1] && $_[1]==-1) {
							$rowdata{$i}{$field} = goah::GoaH->FormatCurrencyNopref($row->$field,0,0,'in',0);
							$rowdata{$i}{'vatvalue'} = $vat{'value'};
						} else {

							# Calculate rows sums for display
							if($field eq 'purchase') {
								my $tmppurchase=0;
								$tmppurchase=$row->purchase if ($row->purchase);
								$rowdata{$i}{'purchase'}=goah::GoaH->FormatCurrencyNopref($tmppurchase,$vat{'value'},0,'out',0);
								$rowdata{$i}{'purchase_vat'}=goah::GoaH->FormatCurrencyNopref($tmppurchase,$vat{'value'},0,'out',1);
							} elsif ( $field eq 'sell' ) {
								my $tmpsell=0;
								$tmpsell=$row->sell if ($row->sell);
								$rowdata{$i}{'sell'}=goah::GoaH->FormatCurrencyNopref($tmpsell,$vat{'value'},0,'out',0);
								$rowdata{$i}{'sell_vat'}=goah::GoaH->FormatCurrencyNopref($tmpsell,$vat{'value'},0,'out',1);
							} else {
								my $tmpfield=0;
								$tmpfield=$row->$field if ($row->$field);
								$rowdata{$i}{$field} = goah::GoaH->FormatCurrency($tmpfield,$vat{'value'},$uid,'out',$settref);
							}
							$rowdata{$i}{'vat'} = $vat{'item'};
							$rowdata{$i}{'vatvalue'} = $vat{'value'};
							
						}
					} else {
						$rowdata{$i}{$field}=$row->$field;
					}
				} else {
					$rowdata{$i}{$field} = $row->$field;
				}
			}
			unless($rowdata{$i}{'amount'}) {
				$rowdata{$i}{'amount'}=0;
			}
			unless($_[2]) {
				my $tmpsell=0;
				$tmpsell=$rowdata{$i}{'sell'} if ($rowdata{$i}{'sell'});
				$rowdata{$i}{'total'} = goah::GoaH->FormatCurrencyNopref( ($tmpsell*$rowdata{$i}{'amount'}),0,'out',0);

				$tmpsell=0;
				$tmpsell=$rowdata{$i}{'sell_vat'} if ($rowdata{$i}{'sell_vat'});
				$rowdata{$i}{'total_vat'} = goah::GoaH->FormatCurrencyNopref( ($tmpsell*$rowdata{$i}{'amount'}),0,'out',0);
			} else {
				$rowdata{$i}{'total'} = $rowdata{$i}{'sell'}*$rowdata{$i}{'amount'};
				$rowdata{$i}{'total_vat'} = $rowdata{$i}{'sell_vat'}*$rowdata{$i}{'amount'};
			}
			$baskettotal+=($rowdata{$i}{'sell'}*$rowdata{$i}{'amount'});
			$baskettotal_vat+=($rowdata{$i}{'sell_vat'}*$rowdata{$i}{'amount'});
			$rowdata{$i}{'code'} = $prod{'code'};
			$rowdata{$i}{'name'} = $prod{'name'};
			$rowdata{$i}{'in_store'}=$prod{'in_store'};
		}
		unless($_[2]) {
			$rowdata{-1}{'baskettotal'} = goah::GoaH->FormatCurrencyNopref($baskettotal,0,'out',0);
			$rowdata{-1}{'baskettotal_vat'} = goah::GoaH->FormatCurrencyNopref($baskettotal_vat,0,'out',0);
		}
		return \%rowdata;
	} else {
		# Row id is set, read only single row from the database
		my $data = goah::Db::Basketrows->new(id =>$_[1]);

		unless($data->load(speculative => 1)) {
			goah::Modules->AddMessage('error',__("Couldn't retrieve basket row from the database!")." ".__("Id not found: ").$_[1],__FILE__,__LINE__);
			return 0;
		}

		foreach my $key (keys %basketrowdbfields) {
			$field = $basketrowdbfields{$key}{'field'};
			if($field eq 'purchase' || $field eq 'sell') {
				my $prodpoint = goah::Modules::Productmanagement::ReadData('products',$data->productid,$uid,$settref,$_[2]); 
				unless($prodpoint) {
					goah::Modules->AddMessage('error',__("Couldn't read product data for id")." ".$data->productid,__FILE__,__LINE__);
					return 0;
				}
				my %prod = %$prodpoint;
				unless($_[2]) {
					$rowdata{$field} = goah::GoaH->FormatCurrency($data->$field,$prod{'vat'},$uid,'out',$settref);
				} else {
					$rowdata{$field} = $data->$field;
				}
			} else {
				if($data->$field) {
					$rowdata{$field} = $data->$field;
				} else {
					$rowdata{$field} = "Empty value from db?!?";
				}
			}
		}
		$rowdata{'code'} = $data->code;
		$rowdata{'name'} = $data->name;
		unless($_[2]) {
			$rowdata{'total'} = goah::GoaH->FormatCurrency( ($rowdata{'sell'}*$rowdata{'amount'}),0,$uid,'out',$settref);
		} else {
			$rowdata{'total'} = $rowdata{'sell'}*$rowdata{'amount'};
		}

		my $proddata=goah::Database::Products->retrieve($data->productid);
		$rowdata{'in_store'}=$proddata->in_store;

		return \%rowdata;
	}

	return 0;

}

#
# Function: DeleteBasket
#
#   Delete basket from database. Delete includes both basket rows and the basket data
#   itself. This function actually deletes data from the database instead of hiding
#   it like customer and product management does.
#
# Parameters:
#
#   id - Database id to be deleted
#
# Returns:
#
#   Fail - 0
#   Success - 1
#
sub DeleteBasket {
	
	if($_[0]=~/goah::Modules::Basket/) {
		goah::Modules->AddMessage('error',__("DeleteBasket called outside package goah::Modules::Basket!"),__FILE__,__LINE__);
		return 0;
	}

	# Delete basket files
	my $frows = goah::Modules::Files->GetFileRows($_[0]);
	my %filerows = %$frows;

	my ($key,$val);
	while (($key,$val) = each %filerows) {
		my %h = %$val;
		goah::Modules::Files->DeleteFileRows('',$h{'int_filename'});
	}
	
	unless($_[0]) {
		goah::Modules->AddMessage('error',__("Can't delete basket! Basket id is missing!"),__FILE__,__LINE__);
		return 0;
	}

	# First try to delete hours associated to basket
	use goah::Modules::Tracking;
	my $hoursremoved=goah::Modules::Tracking->DeleteBasket($_[0]);

	if($hoursremoved==0) {
		goah::Modules->AddMessage('error',__("Couldn't delete hours associated to an basket. Can't delete basket!"),__FILE__,__LINE__);
		return 0;
	}

	use goah::Database::Basketrows;
	my @basketrows = goah::Database::Basketrows->search_where({ basketid => $_[0]});

	foreach(@basketrows) {
		$_->delete;
	}

	my $basket = goah::Database::Baskets->retrieve($_[0]);
	$basket->delete;

	return 1;
}


#
# Function: BasketToOrder
#
#   Create order from basket. Basically this function only updates Basket state and
#   information is stored in the very same database tables.
#
# Parameters:
#
#   basketid - ID for basket to convert into order
#
# Returns:
#
#   Fail - 0 
#   Success - Newly created order number
#
sub BasketToOrder {
	unless($_[0]) {
		goah::Modules->AddMessage('error',__("Can't convert basket! Basket id is missing!"));
		return 0;
	}

	if($_[0]=~/goah::Modules::Basket/) {
		goah::Modules->AddMessage('error',__("CloseBasket called outside package goah::Modules::Basket!"));
		return 0;
	}

	use goah::Database::Baskets;
	my $data = goah::Database::Baskets->retrieve($_[0]);

	# Read all orders from the database and calculate new order number
	my @tmp = goah::Database::Baskets->retrieve_all_sorted_by('ordernum');
	my $ordernum = pop(@tmp);
	$ordernum = ($ordernum->ordernum)+1;

	$data->ordernum($ordernum);
	$data->state('1');
	$data->update;

	return $ordernum;
}

# 
# Function: OrderToBasket
#
#  Create basket from order. Basically this function only updates basket state
#
# Parameters:
#
#   id - ID for order to convert back to basket
#
# Returns:
#
#   0 - Success
#   1 - Fail
#
sub OrderToBasket {

	if($_[0]=~/goah::Modules::Basket/) {
		shift;
	}

	unless($_[0]) {
		goah::Modules->AddMessage('error',__("Can't convert order back to basket. Order ID is missing!"),__FILE__,__LINE__);
		return 1;
	}

	use goah::Database::Baskets;
	my $data = goah::Database::Baskets->retrieve($_[0]);

	unless($data) {
		goah::Modules->AddMessage('error',__("Can't convert order back to basket. Couldn't read order info!"),__FILE__,__LINE__);
		return 1;
	}

	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$data->ordernum("0");
	$data->state('0');
	$data->info(__("Returned from order"));
	$data->updated(sprintf("%04d-%02d-%02d %02d:%02d:%02d",$year+1900,$mon+1,$mday,$hour,$min,$sec));
	$data->update;

	return 0;
}


#
# Function: BasketToInvoice
#
#   Create an invoice from the basket. This function basically just
#   picks an created order, "fills" in referrals and creates invoice.
#   The same functionality can be achieved by going trough these steps
#   by hand.
#
# Parameters:
#
#   basketid - Id for the order basket which needs to be sent and invoiced
#
# Returns:
#
#   Fail - 0
#   Success - 1
#
sub BasketToInvoice {

	unless($_[0]) {
		goah::Modules->AddMessage('error',__("Can't convert basket! Basket id is missing!"),__FILE__,__LINE__);
		return 0;
	}

	# Verify that we actually have an basket which can be transferred to invoice
	my $basket_p=ReadBaskets($_[0],$uid);

	unless($basket_p) {
		goah::Modules->AddMessage('error',__("Can't convert basket! Can't read basket data with id!"),__FILE__,__LINE__);
		return 0;
	}

	my %basket=%$basket_p;

	unless($basket{'state'}==0 || $basket{'state'}==4) {
		goah::Modules->AddMessage('error',__("Can't convert basket! Basket state isn't pending or order!"),__FILE__,__LINE__);
		return 0;
	}

	# Order ready, create referral
	use goah::Modules::Referrals;
	my $refid = goah::Modules::Referrals->NewReferral($_[0]);
	if($refid > 0) {
		goah::Modules->AddMessage('debug',__("Referral created."));
	} else {
		goah::Modules->AddMessage('error',__("Can't create referral!"));
		return 0;
	}

	if(goah::Modules::Referrals->FillReferral($refid)) {
		goah::Modules->AddMessage('debug',__("Filled referral amounts."));
	} else {
		goah::Modules->AddMessage('error',__("Can't update referral amounts to match ordered amount"));
	}

	use goah::Modules::Invoice;
	if(goah::Modules::Invoice->NewInvoice($refid)) {
		goah::Modules->AddMessage('info',__("Invoice created."));
	} else {
		goah::Modules->AddMessage("error",__("Can't create invoice!"));
		return 0;
	}

	
	my $ordernum = BasketToOrder($_[0]);
	if($ordernum == 0) {
		goah::Modules->AddMessage('error',__("Can't convert basket to order!"));
		return 0;
	} else {
		goah::Modules->AddMessage('debug',__("Basket converted to order. Order number ").$ordernum,__FILE__,__LINE__);
	}

	return 1;

}

1;
