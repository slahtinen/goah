#!/usr/bin/perl -w -CSDA

=begin nd

Package: goah::Modules::Systemsettings

  Module to take care of system wide settings about GoaH. Settings
  contain actual user management, default variables etc.

About: License

  This software is copyritght (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Modules::Systemsettings;

use Cwd;
use Locale::TextDomain ('Systemsettings', getcwd()."/locale");

use strict;
use warnings;
use utf8;
use Encode;

use goah::Modules::Customermanagement;

#
# String: module
#
#   Defines module internal name to be used in control flow
my $module='Systemsettings';

#
# Hash: submenu
#
#   Defines sumenu items for the module
#
my %submenu = ( 0 => { title => __('Company info & users'), action => 'companyinfo'},
		1 => { title => __('GoaH settings'), action => 'goahsettings'},
		);

#
# Hash: companydbfieldnames
#
#    Defines fields and their names for database. These can be used to loop
#    trough fields so our functions and templates can be built more generic way
#
my %companydbfieldnames = (
                        0 => { field => 'id', name => 'id', type => 'hidden' },
			1 => { field => 'isowner', name => 'isowner', type => 'hidden' },
                        2 => { field => 'vat_id', name => __('VAT -id'), type => 'textfield', required => '1' },
                        3 => { field => 'name', name => __('Name'), type => 'textfield', required => '1' },
                        5 => { field => 'www', name => __('Homepage address'), type => 'textfield', required => '0' },
                );

#
# Hash: locationdbfieldnames
#
#   Defines fields and their names for database. These can be used to loop
#   trough fields so our functions and templates can be built more generic way
#
my %locationdbfieldnames = (
                        0 => { field => 'id', name => 'id', type => 'hidden', required => '0' },
                        1 => { field => 'companyid', name => 'companyid', type => 'hidden', required => '0' },
			2 => { field => 'defshipping', name => __("Default shipping address"), type => 'checkbox', required => '0' },
			3 => { field => 'defbilling', name => __("Default billing address"), type => 'checkbox', required => '0' },
                        4 => { field => 'addr1', name => __('Address, line 1'), type => 'textfield', required => '0' },
                        5 => { field => 'addr2', name => __('Address, line 2'), type => 'textfield', required => '0' },
                        6 => { field => 'postalcode', name => __('Postal code'), type => 'textfield', required => '0' },
                        7 => { field => 'postaloffice', name => __('Post office'), type => 'textfield', required => '0' },
                        8 => { field => 'country', name => __('Country'), type => 'textfield', required => '0' },
			9 => { field => 'phone', name => __("Phone"), type => 'textfield', required => '0' },
			90 => { field => 'fax', name => __("Fax"), type => 'textfield', required => '0' },
			91 => { field => 'email', name => __("Email"), type => 'textfield', required => '0' },
			92 => { field => 'info', name => __("Other information"), type => 'textarea', required => '0' },
			93 => { field => 'hidden', name => 'hidden', type => 'hidden', required => '0' }
                );

#
# Hash: persondbfieldnames
#
#   Defines fields and their names for database containing user information. 
#   This hash contains actually fields for two tables since we do user and
#   account information with same functions.
#
my %persondbfieldnames = (
                        0 => { field => 'id', name => 'id', type => 'hidden', required => '0' },
                        1 => { field => 'companyid', name => 'companyid', type => 'hidden', required => '0' },
                        2 => { field => 'firstname', name => __('First name'), type => 'textfield', required => '1' },
                        3 => { field => 'lastname', name => __('Last name'), type => 'textfield', required => '1' },
                        4 => { field => 'title', name => __('Title'), type => 'textfield', required => '0' },
                        5 => { field => 'phone', name => __('Phone'), type => 'textfield', required => '0' },
                        6 => { field => 'mobile', name => __('Mobile'), type => 'textfield', required => '0' },
                        7 => { field => 'fax', name => __('Fax'), type =>  'textfield', required => '0' },
                        8 => { field => 'email', name => __('E-mail'), type => 'textfield', required => '1' },
                        9 => { field => 'locationid', name => __('Location'), type => 'textfield', required => '0' },
			91 => { field => 'desirablehours', name => __('Desirable billed hours per day'), type => 'textfield', required => '0' },
			93 => { field => 'login', name => __("Login name"), type=> 'textfield', required => '0' },
			94 => { field => 'pass', name => __("Password"), type => 'textfield', required => '0' },
			95 => { field => 'disabled', name => __("Disabled"), type => 'checkbox', required => '0' },
                );


#
# Hash: bankaccountsdbfieldnames
#
#   Defines fields and their names for database containing bank accounts.
#
my %bankaccountsdbfieldnames = (
			0 => { field => 'id', name => 'id', type => 'hidden', 'required' => '0' },
			1 => { field => 'companyid', name => 'companyid', type => 'hidden', required => '0' },
			2 => { field => 'bankname', name=>__("Bank name"), type => 'textfield', required => '0' },
			3 => { field => 'domestic', name => __("Domestic"), type => 'textfield', required => '1' },
			4 => { field => 'iban', name => __("IBAN"), type => 'textfield', required => '1' },
			5 => { field => 'bic', name => __("BIC"), type => 'textfield', required => '1' },
			6 => { field => 'comment', name => __("Comment"), type => 'textfield', required => '0' }
		);


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
#   Reference to hash array which contains variables for Template::Toolkit
#   process for the module.
#
sub Start {

	my %variables;

	$variables{'function'} = 'modules/Systemsettings/systemsettings';
	$variables{'module'} = $module;
	$variables{'gettext'} = sub { return __($_[0]); };
	$variables{'submenu'} = \%submenu;
	$variables{'submenuselect'}=-1;
	$variables{'companydbfields'} = \%companydbfieldnames;
	$variables{'locationdbfields'} = \%locationdbfieldnames;
	$variables{'persondbfields'} = \%persondbfieldnames;
	$variables{'bankaccountsdbfields'} = \%bankaccountsdbfieldnames;
	$variables{'locationinfo'} = sub { goah::Modules::Customermanagement::ReadLocationdata($_[0]) };

	use CGI;
	my $q = new CGI;
	
	# Load companyinfo as default submodule. This should be added to module settings when it's implemented.
	unless ($q->param('action')) {
		$q->param( action => 'companyinfo');
	}
	
	if($q->param('action')) {

		$variables{'submenuselect'}="companyinfo";
		if($q->param('action') eq 'companyinfo') {

			$variables{'companydata'} = ReadOwnerInfo();
			$variables{'function'} = 'modules/Systemsettings/companyinfo';
			$variables{'locations'} = ReadOwnerLocations();
			$variables{'companypersonnel'} = ReadOwnerPersonnel();
			$variables{'bankaccounts'} = ReadBankAccounts();

		} elsif($q->param('action') eq 'newbankaccount') {

			if(WriteNewBankAccount()) {
				goah::Modules->AddMessage('info',__("New bank account created"));
			} else {
				goah::Modules->AddMessage('error',__("Can't create new bank account!"));
			}

			$variables{'companydata'} = ReadOwnerInfo();
			$variables{'function'} = 'modules/Systemsettings/companyinfo';
			$variables{'locations'} = ReadOwnerLocations();
			$variables{'companypersonnel'} = ReadOwnerPersonnel();
			$variables{'bankaccounts'} = ReadBankAccounts();

		} elsif($q->param('action') eq 'editbankaccount') {
		
			if(EditBankAccount()) {
				if($q->param('delete')) {
					goah::Modules->AddMessage('info',__("Bank account removed successfully"));
				} else {
					goah::Modules->AddMessage('info',__("Bank account information updated"));
				}
			} else {
				goah::Modules->AddMessage('error',__("Can't modify bank account information"));
			}
			$variables{'companydata'} = ReadOwnerInfo();
			$variables{'function'} = 'modules/Systemsettings/companyinfo';
			$variables{'locations'} = ReadOwnerLocations();
			$variables{'companypersonnel'} = ReadOwnerPersonnel();
			$variables{'bankaccounts'} = ReadBankAccounts();

		} elsif($q->param('action') eq 'writecompanydata') {

			if(WriteOwnerInfo($q->param('companyid'))) {
				goah::Modules->AddMessage('info',__('Owner information updated'));
			} else {
				goah::Modules->AddMessage('error',__("Can't update owner information"));
			}
			$variables{'companydata'} = ReadOwnerInfo();
			$variables{'function'} = 'modules/Systemsettings/companyinfo';
			$variables{'locations'} = ReadOwnerLocations();
			$variables{'companypersonnel'} = ReadOwnerPersonnel();

		} elsif($q->param('action') eq 'newlocation') {

			$variables{'companydata'} = ReadOwnerInfo();
			$variables{'function'} = 'modules/Systemsettings/newlocation';

		} elsif($q->param('action') eq 'newperson') {

			$variables{'companydata'} = ReadOwnerInfo();
			$variables{'function'} = 'modules/Systemsettings/newperson';
		
		} elsif($q->param('action') eq 'writenewlocation') {

			if(goah::Modules::Customermanagement::WriteNewLocation()) {
				goah::Modules->AddMessage('info',__("New location added"));
			} else {
				goah::Modules->AddMessage('error',__("Can't write new location data!"));
			}
			$variables{'companydata'} = ReadOwnerInfo();
			$variables{'function'} = 'modules/Systemsettings/companyinfo';
			$variables{'locations'} = ReadOwnerLocations();
			$variables{'companypersonnel'} = ReadOwnerPersonnel();
			$variables{'bankaccounts'} = ReadBankAccounts();

		} elsif($q->param('action') eq 'writenewperson') {

			if(WritePersonData()) {
				goah::Modules->AddMessage('info',__("New person added"));
			} else {
				goah::Modules->AddMessage('error',__("Can't add new person to database!"));
			}

			$variables{'companydata'} = ReadOwnerInfo();
			$variables{'function'} = 'modules/Systemsettings/companyinfo';
			$variables{'locations'} = ReadOwnerLocations();
			$variables{'companypersonnel'} = ReadOwnerPersonnel();
			$variables{'bankaccounts'} = ReadBankAccounts();
		
		} elsif($q->param('action') eq 'editlocation') {

			$variables{'function'}  = 'modules/Systemsettings/editlocation';
			$variables{'locationdata'} = goah::Modules::Customermanagement::ReadLocationdata($q->param('target'));


		} elsif($q->param('action') eq 'editperson') {

			$variables{'function'}  = 'modules/Systemsettings/editperson';
			$variables{'persondata'} = ReadOwnerPersonnel($q->param('target'));

		} elsif($q->param('action') eq 'writepersondata') {

			if(WritePersonData($q->param('id')) == 0) {
				goah::Modules->AddMessage('info',__("Person information updated to database."));
			} else {
				goah::Modules->AddMessage('error',__("Can't update person information!"));
			}
			$variables{'companydata'} = ReadOwnerInfo();
			$variables{'function'} = 'modules/Systemsettings/companyinfo';
			$variables{'locations'} = ReadOwnerLocations();
			$variables{'companypersonnel'} = ReadOwnerPersonnel();
			$variables{'bankaccounts'} = ReadBankAccounts();

		} elsif($q->param('action') eq 'writelocationdata') {

			if(goah::Modules::Customermanagement::WriteLocationdata($q->param('id'))) {
				goah::Modules->AddMessage('info',__("Location data updated."));
			} else {
				goah::Modules->AddMessage('error',__("Can't update location data!"));
			}
			$variables{'companydata'} = ReadOwnerInfo();
			$variables{'function'} = 'modules/Systemsettings/companyinfo';
			$variables{'locations'} = ReadOwnerLocations();
			$variables{'companypersonnel'} = ReadOwnerPersonnel();
			$variables{'bankaccounts'} = ReadBankAccounts();

		} elsif($q->param('action') eq 'deletelocation') {

			if(goah::Modules::Customermanagement::DeleteLocation($q->param('target'))) {
				goah::Modules->AddMessage('info',__("Location data removed!"));
			} else {
				goah::Modules->AddMessage('error',__("Can't remove location data!"));
			}
			$variables{'companydata'} = ReadOwnerInfo();
			$variables{'function'} = 'modules/Systemsettings/companyinfo';
			$variables{'locations'} = ReadOwnerLocations();
			$variables{'companypersonnel'} = ReadOwnerPersonnel();


		} elsif($q->param('action') eq 'usermanagement') {

			goah::Modules->AddMessage('info',"Feature under construction");

		} elsif($q->param('action') eq 'goahsettings') {
			
			$variables{'function'} = 'modules/Systemsettings/goahsettings';
			$variables{'submenuselect'}="goahsettings";

		} elsif($q->param('action') eq 'newsetting' || $q->param('action') eq 'updatesetting') {
			
			if(WriteSetup() == 1) {
				goah::Modules->AddMessage('info',__("Setting stored to database."));
			} else {
				goah::Modules->AddMessage('error',__("Can't write setting to database."));
			}
			$variables{'function'} = 'modules/Systemsettings/goahsettings';
			$variables{'submenuselect'}="goahsettings";

		} elsif($q->param('action') eq 'deletesetting') {

			if(DeleteSetup() == 1) {
				goah::Modules->AddMessage('info',__("Setting removed from database."));
			} else {
				goah::Modules->AddMessage('error',__("Can't remove setting from database."));
			}
			$variables{'function'} = 'modules/Systemsettings/goahsettings';
			$variables{'submenuselect'}="goahsettings";

		} else {

			goah::Modules->AddMessage('error',__("Module doesn't have function '").$q->param('action')."'.");
			$variables{'function'} = 'modules/blank';
		}


		# Read setup variables to template variables
		my $act=$q->param('action');
		if($act eq 'deletesetting' || $act eq 'newsetting' || $act eq 'updatesetting' || $act eq 'goahsettings') {
			$variables{'systemlocale'} = ReadSetup('locale',1);
			$variables{'vatclasses'} = ReadSetup('vat');
			$variables{'paymentconditions'} = ReadSetup('paymentcondition');
			$variables{'reclamationtimes'} = ReadSetup('reclamationtime');
			$variables{'delayinterests'} = ReadSetup('delayinterests');
			$variables{'smtpserver_name'} = ReadSetup('smtpserver_name',1);
			$variables{'smtpserver_port'} = ReadSetup('smtpserver_port',1);
			$variables{'smtpserver_ssl'} = ReadSetup('smtpserver_ssl',1);
			$variables{'smtpserver_username'} = ReadSetup('smtpserver_username',1);
			$variables{'smtpserver_password'} = ReadSetup('smtpserver_password',1);
			$variables{'languages'} = goah::GoaH->ReadLanguages();
		}


	} 

	return \%variables;
}


#
# Function: DeleteSetup
#
#   Delete setup variable from database
#
# Parameters:
#
#   None, reads data via HTTP variables
#
# Returns:
#
#   Fail - 0 
#   Success - 1
#
sub DeleteSetup {

	my $q =  new CGI;
	unless($q->param('id')) {
		goah::Modules->AddMessage('error',__("Can't remove setting from database. ID is missing."));
		return 0;
	}

	use goah::Database::Setup;
	my $data = goah::Database::Setup->retrieve($q->param('id'));
	$data->delete();
	
	return 1;
}

#
# Function: ReadSetup
#
#   Read setup variables for single category
#
# Parameters:
#
#   category - Category name to be retrieved. If numeric read only the setup entry
#   	       with given id number. Useful for retrieving ie. an VAT class for
#   	       products. Numeric category implies single -value
#   single - If set to 1 return values in hash without sorting key, useful
#   	     when retrieving only single value
#
# Returns:
#
#   Fail - 0
#   Success - Hash reference
#
sub ReadSetup {

	shift if($_[0]=~/goah::Modules::Systemsettings/);

	unless($_[0]) {
		goah::Modules->AddMessage('error',__("Missing category to search settings"),__FILE__,__LINE__,caller());
		return 0;
	}

	my %sdata;
	my $sortidx=10000000;
	my @fields=qw(id category item value sort def);

	unless($_[0]=~/\d+/) {
		use goah::Db::Setup::Manager;
		my $datap = goah::Db::Setup::Manager->get_setup( [ category => $_[0] ] , sort_by => 'sort');

		unless($datap) {
			goah::Modules->AddMessage('error',__("Couldn't find any settings by category")." '".$_[0]."'",__FILE__,__LINE__,caller());
			return 0;
		}

		my @data=@$datap;
		if(scalar(@data)==0) {
			goah::Modules->AddMessage('debug',"Empty result set for settings with category ".$_[0],__FILE__,__LINE__,caller());
			return 0;
		}

		foreach (@data) {
			
			foreach my $k (@fields) {
		
				unless($_[1]) {	
					$sdata{$sortidx}{$k}=$_->$k;
				} else {
					$sdata{$k}=$_->$k;
				}
			}
			$sortidx++;
		}
	} else {

		use goah::Db::Setup;
		my $datap=goah::Db::Setup->new(id => $_[0]);

		unless($datap->load(speculative => 1)) {
			goah::Modules->AddMessage('error',__("Couldn't retrieve setup item with id")." ".$_[0],__FILE__,__LINE__,caller());
			return 0;
		}

		foreach my $k (@fields) {
			$sdata{$k}=$datap->$k;
		}

		# Nasty hack to fix row floats on vat classes where number and % sign are on another lines
		if($sdata{'category'}=~/vat/i) {
			$sdata{'item'}=~s/\ /\&nbsp;/;
		}
	}


	return \%sdata;

}

#
# Function: WriteSetup
#
#    Write setup variable to database
#
# Parameters: 
#
#    None, uses HTTP variables
#
# Returns:
#
#    Success - 1
#    Fail - 0
#
sub WriteSetup {

	use goah::Database::Setup;

	my $q = new CGI;

	my $update=0;
	my $data;

	if($q->param('action') eq 'updatesetting') {

		$update=1;
		$data = goah::Database::Setup->retrieve($q->param('id'));
		unless($data && ($data->id eq $q->param('id'))) {
			$update=0;
		} 
	}

	if($update) {

		$data->item($q->param('item'));
		if($q->param('category') eq 'vat') {
			$data->value(sprintf("%.02f",$q->param('value')));
		} else {
			$data->value($q->param('value'));
		}
		$data->sort($q->param('sort'));

		# Check if we need to change default value
		if($q->param('def') && $q->param('def') eq 'on') {
			
			# First, reset default value from everything in this category
			use goah::Db::Setup::Manager;
			my $datap = goah::Db::Setup::Manager->get_setup( [ category => $q->param('category') ] );

			unless($datap) {
				goah::Modules->AddMessage('error',__("Could't reset default options for category!"),__FILE__,__LINE__);
			} else {

				my @catdata=@$datap;
				foreach my $item (@catdata) {
					$item->def(0);
					$item->update;
				}
			}

			$data->def(1);
		}

		$data->update();
		$data->commit();
		return 1;
	} else {

		my %data= ( 	category => 'vat',
				item => 'unidentified',
				value => '0',
				sort => '0' );
		
		$data{'category'} = $q->param('category');
		$data{'item'} = $q->param('item');
		if($q->param('category') eq 'vat') {
			$data{'value'}=sprintf("%.02f",$q->param('value'));
		} else {
			$data{'value'} = $q->param('value');
		}
		$data{'sort'} = $q->param('sort');

		goah::Database::Setup->insert(\%data);

		return 1;
	}
}

#
# Function: WriteSetupInt
#
#   Internal function for setup changes (at this moment, only cron). This one
#   is needed, since we're updating settings also via other functions, so 
#   there isn't HTTP-variables for use.
#
# Parameters:
#   
#   item - Item to update
#   value - Value for item
#
# Returns:
#
#   1 - Success
#   0 - Fail
#
sub WriteSetupInt {

	if($_[0]=~/goah::Modules::Systemsettings/) {
		shift;
	}

	unless($_[0] && $_[1]) {
		goah::Modules->AddMessage('error',__("Can't update system settings. Either item or value is missing!"),__FILE__,__LINE__);
		return 0;
	}

	use goah::Database::Setup;
	my @setup = goah::Database::Setup->search({ category => $_[0] });

	unless(@setup) {
		# We didn't find the setting we were after, so we'll create one instead
		goah::Database::Setup->insert({ category => $_[0], value => $_[1] });
		goah::Database::Setup->commit;
	} else {
		my $s = $setup[0];
		$s->value($_[1]);
		$s->update;
	}

	return 1;
}

#
# Function: ReadOwnerInfo
#
#    Read information for owner company from the database.
#
# Parameters:
#
#   None
#
# Returns:
#
#   Success - Pointer to Class::DBI result
#   Fail - 0
#
sub ReadOwnerInfo {

	use goah::Database::Companies;
	my @data = goah::Database::Companies->search_where('isowner' => '1');

	if(scalar(@data)>0) {
		return $data[0];
	} 
	return 0;
}

#
# Function: WriteOwnerInfo
#
#   Write owner company information to database. Function does both
#   writing new information and updating older one with the very same
#   data and parameters.
#
# Parameters:
#   
#   copmanyid - Owner company id from the database (*Note:* update only)
#   HTTP - Reads various data via HTTP -variables
#
# Returns:
#
#   Success - 1
#   Fail - 0
#
sub WriteOwnerInfo {

	use goah::Database::Companies;
	use CGI;
	my $q = new CGI;
	my %fieldinfo;
	
	if($_[0] || $_[0]=~/[0-9]+/) {
		my $data = goah::Database::Companies->retrieve($_[0]);
		if($data->id != $_[0]) {
			goah::Modules->AddMessage('error',__("Can't update owner information. Id for company isn't correct."));
			return 0;
		}

		while(my($key,$value) = each(%companydbfieldnames)) {
			%fieldinfo = %$value;
			if($fieldinfo{'required'} == '1' && !($q->param($fieldinfo{'field'})) ) {
				# Using variable just to make source look nicer
				my $errstr = __('Required field').' <b>'.$fieldinfo{'name'}.'</b> '.__('empty!')." ";
				$errstr.= __("Leaving value unaltered.");
				goah::Modules->AddMessage('warn',$errstr);
			} else {
				if($q->param($fieldinfo{'field'})) {
					$data->set($fieldinfo{'field'} => decode('utf-8',$q->param($fieldinfo{'field'})));
				}
			}
		}
		$data->update;
		return 1;
	} else {
		# Owner data not found, creating a new company
		my %data;
		
		while(my($key,$value) = each (%companydbfieldnames)) {
			%fieldinfo = %$value;
			if($fieldinfo{'required'} == '1' && !($q->param($fieldinfo{'field'})) ) {
				goah::Modules->AddMessage('warn',__('Required field').' <b>'.$fieldinfo{'name'}.'</b> '.__('empty!'));
				return 0;
			} 

			if($q->param($fieldinfo{'field'})) {
				$data{$fieldinfo{'field'}} = $q->param(decode('utf-8',$fieldinfo{'field'}));
			}
		}

		goah::Database::Companies->insert(\%data);
		return 1;
	}

	return 0;
}

# 
# Function: ReadOwnerLocations
#
#   Read locations for owner company from the database
#
# Parameters: 
#    
#   None
#
# Returns:
#
#   Pointer to Class::DBI results
#
sub ReadOwnerLocations {

	use goah::Database::Companies;
	my @data = goah::Database::Companies->search_where( isowner => '1' );
	my $tmp = goah::Modules::Customermanagement::ReadCompanylocations($data[0]);

	return $tmp;
}


#
# Function: ReadBankAccounts
#
#   Read owner bank accounts from the database. 
#
# Parameters: 
#
#   None
#
# Returns:
#
#   Pointer to Class::DBI resource, or if result is empty 0
#
sub ReadBankAccounts {

	if($_[0] && $_[0]=~/Systemsettings/) {
		shift;
	}

	use goah::Database::Companies;
	use goah::Database::Bankaccounts;
	my @owner = goah::Database::Companies->search_where( isowner => '1' );
	my $tmp = $owner[0];
	$tmp=$tmp->id;
	my @bankaccounts = goah::Database::Bankaccounts->search_where(companyid => $tmp);

	if(scalar(@bankaccounts)==0) {
		return 0;
	} else {
		return \@bankaccounts;
	}

}


#
# Function: WriteNewBankAccount
#
#   Function to store new bank account information into database
#
# Parameters:
#   
#   None, uses HTTP-parameters
#
# Returns:
#  
#   1 - Success
#   0 - Fail
#
sub WriteNewBankAccount {

	use goah::Database::Bankaccounts;
	use CGI;

	my $q = new CGI;
	unless($q->param('domestic')) {
		goah::Modules->AddMessage('error',__("Domestic format for bank account missing!"));
		return 0;
	}

	unless($q->param('iban')) {
		goah::Modules->AddMessage('error',__("IBAN format for bank account missing!"));
		return 0;
	}

	unless($q->param('companyid')) {
		goah::Modules->AddMessage('error',__("Company id is missing! Can't add bank account!"));
		return 0;
	}

	unless($q->param('bic')) {
		goah::Modules->AddMessage('error',__("BIC for bank account missing!"));
		return 0;
	}

	goah::Database::Bankaccounts->insert({  companyid => $q->param('companyid'),
						domestic => $q->param('domestic'),
						iban => $q->param('iban'),
						bic => $q->param('bic'),
						comment => $q->param('comment'),
						bankname => $q->param('bankname') });
	goah::Database::Bankaccounts->commit();
	return 1;
}


#
# Function: EditBankAccount
#
#   Function to either edit or delete bank account information.
#
# Parameters:
#
#   None, uses HTTP-variables
#
# Returns:
#
#   1 - Success
#   0 - Fail
#
sub EditBankAccount {

	use CGI;
	my $q = new CGI;

	unless($q->param('target')) {
		goah::Modules->AddMessage('error',__("Target id missing! Can't edit account information!"));
		return 0;
	}

	use goah::Database::Bankaccounts;
	my $account = goah::Database::Bankaccounts->retrieve($q->param('target'));

	unless($account->id == $q->param('target')) {
		goah::Modules->AddMessage('error',__("Coudln't read account information from the database!"));
		return 0;
	}

	if($q->param('delete') && $q->param('delete') eq 'on') {
		$account->delete;
		goah::Database::Bankaccounts->commit();
		goah::Modules->AddMessage('info',__("Bank account information removed"));
		return 1;
	}

	unless($q->param('domestic')) {
		goah::Modules->AddMessage('error',__("Domestic format for bank account missing!"));
	} else {
		$account->domestic($q->param('domestic'));
	}

	unless($q->param('iban')) {
		goah::Modules->AddMessage('error',__("IBAN format for bank account missing!"));
	} else {
		$account->iban($q->param('iban'));
	}

	unless($q->param('bic')) {
		goah::Modules->AddMessage('error',__("BIC for bank account missing!"));
	} else {
		$account->bic($q->param('bic'));
	}

	if($q->param('comment')) {
		$account->comment($q->param('comment'));
	} else {
		$account->comment("");
	}

	if($q->param('bankname')) {
		$account->bankname($q->param('bankname'));
	} else {
		$account->bankname("");
	}

	$account->update;
	$account->commit;

	return 1;

}


#
# Function: ReadOwnerPersonnel
#
#   Read owner personnel from the database. Read includes actual
#   account data so we need an separate function for this
#
# Parameters:
#
#   ID - User id to search for
#
# Returns:
#
#   Success - Hash reference to results
#   Fail - 0
#
sub ReadOwnerPersonnel {

	shift if ($_[0] && $_[0]=~/goah::Modules::Systemsettings/);

	use goah::Database::Companies;
	use goah::Database::users;
	my @data = goah::Database::Companies->search_where( isowner => '1' );
	my $personspointer = goah::Modules::Customermanagement::ReadCompanypersonnel($data[0]->id,$_[0]);
	my @persons = @$personspointer;

	my %pdata;
	my $field;
	my @logindata;
	my $login;
	my $i=100000;
	foreach my $per (@persons) {

		##goah::Modules->AddMessage('debug',"Reading personnel info for ".$per->lastname." ".$per->firstname,__FILE__,__LINE__);

		# Quick and dirty fix for basket search
		if(scalar(keys(%persondbfieldnames))>0) {
			foreach my $key (keys %persondbfieldnames) {
				$field = $persondbfieldnames{$key}{'field'};
				unless($field eq 'login' || $field eq 'pass' || $field eq 'disabled') {

						if($_[0]) {
							$pdata{$field} = $per->get($field);
						} else {
							$pdata{$i}{$field} = $per->get($field);
						}
				}
			}

			@logindata = goah::Database::users->search_where({ accountid => $per->id });
			unless(scalar(@logindata) == 0) {

				$login = $logindata[0];
				if($_[0]) {
					$pdata{'login'} = $login->login;
					$pdata{'pass'} = $login->pass;
					$pdata{'disabled'} = $login->disabled;
				} else {
					$pdata{$i}{'login'} = $login->login;
					$pdata{$i}{'pass'} = $login->pass;
					$pdata{$i}{'disabled'} = $login->disabled;
				}

			}
		} else {
			goah::Modules->AddMessage('debug',"Didn't have hash persondbfieldnames!",__FILE__,__LINE__);
			if($_[0]) {
				$pdata{'firstname'}=$per->firstname;
				$pdata{'lastname'}=$per->lastname;
			} else {
				$pdata{$i}{'firstname'}=$per->firstname;
				$pdata{$i}{'lastname'}=$per->lastname;
			}
		}
		$i++;

	}

	return \%pdata;
}

# 
# Function: ReadDefaultOwnerLocation
#
#   Read only default location for owner company from the database
#   to be printed on invoice etc
#
# Parameters: 
#
#   none
#
# Returns:
#
#   fail - 0
#   success - Pointer to database result
#
# See Also:
#
#   <ReadOwnerLocations>
#
sub ReadDefaultOwnerLocation {
	
	my $locations = ReadOwnerLocations();
	my @loc = @$locations;

	foreach (@loc) {
		if($_->defbilling && $_->defbilling eq 'on') {
			return $_;
		}
	}

	return 0;
}


#
# Function: WritePersonData
#
#   Write new person to owner company. We're using a mix with
#   <goah::Modules::Customermanagement::WriteNewPerson> and 
#   own set of functions so that we can assign login information
#   to these as well.
#
# Parameters:
#  
#   id - User id to update, if omitted then create new user  
#
# Return: 
#
#   Success - 1
#   Fail - 0 
#
sub WritePersonData {

	use goah::Database::users;

	my $q = new CGI;
	my $tmp;

	unless($_[0]) {
		$tmp = goah::Modules::Customermanagement::WriteNewPerson();
		if($tmp == 0) {
			goah::Modules->AddMessage('error',__("Can't write new person to database!"));
			return 0;
		}

		# Person data stored. Let's add login information as well.
		my %data;

		if($q->param('login') && $q->param('pass')) {
			$data{'login'} = $q->param('login');
			$data{'pass'} = $q->param('pass');
			$data{'accountid'} = $tmp;
			goah::Database::users->insert(\%data);
		} else {
			goah::Modules->AddMessage('error',__("Login information missing. Newly created person can't log in!"));
		}
	} else {

		$tmp = goah::Modules::Customermanagement::WritePersondata();

		# Update login information as well if there's something to update
		my @logindata = goah::Database::users->search_where({ accountid => $q->param('id')});
		if(scalar(@logindata)==0) {
			# No login data available, let's create new one
			if($q->param('login') && $q->param('pass')) {
				goah::Database::users->insert({ login => $q->param('login'),
								pass => $q->param('pass'),
								accountid => $q->param('id') });
			} else {
				goah::Modules->AddMessage('warn',__("Login information missing. Can't update or create credientials."));
			}
		} else {
			my $login = $logindata[0];

			if($q->param('login')) {
				$login->login($q->param('login'));
			}

			if($q->param('pass')) {
				$login->pass($q->param('pass'));
			}

			if($q->param('disabled') eq 'on') {
				$login->disabled(1);
			} else {
				$login->disabled(0);
			}
		
			$login->update();
		}

		return $tmp;
	}

	

	return 1;
}

1;
