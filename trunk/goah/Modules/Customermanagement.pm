#!/usr/bin/perl -w -CSDA
##!/usr/bin/perl -w 

=begin nd

Package: goah::Modules::Customermanagement

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.
  See COPYRIGHT and LICENSE files for more information

About: TODO

 This file requires some rewriting. One set of read/write -functions
 would be enough, they just need a minor tweak to handle different database
 names etc.

 If possible it'd be neat to move database field definitions to table
 definition files. Then if database is changed or if it needs to be accessed
 via several modules it'd be easier to maintain changes.
	-Take, 20.02.2008

=cut

package goah::Modules::Customermanagement;

use Cwd;
use Locale::TextDomain ('Customermanagement', getcwd()."/locale");


use strict;
use warnings;
use utf8;
use Encode;

#
# Hash: companydbfieldnames 
#
#   Database structure in a hash. Via this it's possible to
#   print HTML-form *and* create simple function for database
#   queries
#
my %companydbfieldnames = (
			0 => { field => 'id', name => 'id', type => 'hidden', required => '0' },
			1 => { field => 'vat_id', name => __('VAT -id'), type => 'textfield', required => '1' },
			2 => { field => 'name', name => __('Company / Last Name'), type => 'textfield', required => '1' },
			3 => { field => 'firstname', name => __('First name'), type=>'textfield',required => '0'},
			4 => { 
				field => 'payment_condition',
				name => __('Payment condition'),
				type => 'selectbox',
				required => '0',
				data => ReadSetup('paymentcondition')
				},
			5 => {  field => 'delay_interest',
				name => __('Delay interest (%)'), 
				type => 'selectbox', 
				required => '0',
				data => ReadSetup('delayinterests') },
			6 => { 
				field => 'reclamation_time',
				name => __('Reclamation time'),
				type => 'selectbox',
				required => '0',
				data => ReadSetup('reclamationtime')
				},
			7 => { field => 'custtype', name => __("Customer type"), type => 'selectbox', required => '0', data => ReadCustomerIdentifiers('1') },
			8 => { field => 'customerreference', name => __("Customer reference"), type => 'textfield', required => '0' },
			9 => { field => 'www', name => __('Homepage address'), type => 'textfield', required => '0' },
			10 => { field => 'description', name => __('Other information'), type => 'textarea', required => '0' } 
		);

#
# Hash: locationdbfieldnames
#
#   Database field definitiosn for location data
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
#   Database field definitions for person data
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
			9 => { field => 'locationid', name => __('Location'), type => 'textfield', required => '0' }
		);

#
# String: module
#
#   Name of the module, this is used on several locations
#   so it makes sense to create package wide variable
#
my $module = 'Customermanagement';

# 
# Hash: submenu
#
#   Submenu definitions for the package
#
my %submenu = ( 0 => { title => __('Add new customer'), action => 'addnewcompany' },
		1 => { title => __('Customer types'), action => 'customertypes' },
		2 => { title => __('Customer groups'), action => 'customergroups' },
	);

use CGI;


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

	my %variables;

	$variables{'function'} = 'modules/Customermanagement/customers';
	$variables{'module'} = $module;
	$variables{'companydbfields'} = \%companydbfieldnames;
	$variables{'locationdbfields'} = \%locationdbfieldnames;
	$variables{'persondbfields'} = \%persondbfieldnames;
	$variables{'gettext'} = sub { return __($_[0]); };
	$variables{'submenu'} = \%submenu;

	my $q = CGI->new();
	my $companyid='';
	if($q->param('action')) {

		if($q->param('action') eq 'addnewcompany') {

				$variables{'function'} = 'modules/Customermanagement/newcompany';
				$variables{'dbfields'} = \%companydbfieldnames;

		} elsif($q->param('action') eq 'writenewcompany') {

				# Store new company into database
				my $tmp = WriteNewCompany();
				if($tmp) {
					$variables{'function'} = 'modules/Customermanagement/companyinfo';
					$companyid = $tmp;
					goah::Modules->AddMessage('info',__('New company stored into database'));
				} else {
					goah::Modules->AddMessage('error',__("Can't add new company into database!"));
				}

		} elsif($q->param('action') eq 'companyinfo') {

				# Read informationf or individual company
				$variables{'function'} = 'modules/Customermanagement/companyinfo';

                                # Search selected company files
                                use goah::Modules::Files;
                                $variables{'companyfiles'} = goah::Modules::Files->GetFileRows($q->param('companyid'),'');

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

		
		} elsif($q->param('action') eq 'editcompany') {

				# Print HTML form for editing company data
				$variables{'function'}  = 'modules/Customermanagement/editcompany';

		} elsif($q->param('action') eq 'writecompanydata') {

				# Update company information into database
				if(WriteCompanydata($q->param('id'))) { 
					goah::Modules->AddMessage('info',__("Company data updated to database."));
				} else {
					goah::Modules->AddMessage('error',__("Can't update company data to database!"));
				}
				$variables{'function'} = 'modules/Customermanagement/companyinfo';

		} elsif($q->param('action') eq 'deletecompany') {

				# Delete (hide) company from database
				if(DeleteCompany($q->param('id'))) {
					goah::Modules->AddMessage('info',__("Company removed from the database."));
				} else {
					goah::Modules->AddMessage('error',__("Can't delete company"));
				}

				$variables{'function'} = 'modules/Customermanagement/customers';
				$variables{'companies'} = ReadAllCompanies(1);
		
		} elsif($q->param('action') eq 'writelocationdata') {

				# Update location information into database
				if(WriteLocationdata($q->param('id'))) {
					goah::Modules->AddMessage('info',__("Location data updated to database."));
				} else {
					goah::Modules->AddMessage('error',__("Can't update location data to database!"));
				}
				$variables{'function'} = 'modules/Customermanagement/companyinfo';
		
		} elsif($q->param('action') eq 'newlocation') {

				# Print HTML-form to add location for company
				$variables{'function'} = 'modules/Customermanagement/newlocation';
		
		} elsif($q->param('action') eq 'writenewlocation') {

				$variables{'function'} = 'modules/Customermanagement/companyinfo';
				if(WriteNewLocation()) {
					goah::Modules->AddMessage('info',__('New address stored to database'));
					$variables{'locationfields'} = \%locationdbfieldnames;
				} else {
					goah::Modules->AddMessage('info',__("Can't add new company into database!"));
				}
		
		} elsif($q->param('action') eq 'deletelocation') {

				$variables{'function'} = 'modules/Customermanagement/companyinfo';
				$variables{'companydata'} = ReadCompanydata($q->param('companyid'));
				if(DeleteLocation($q->param('target'))) {
					goah::Modules->AddMessage('info',__("Location removed"));
				} else {
					goah::Modules->AddMessage('warn',__("Can't remove location information!"));
				}
				$variables{'companylocations'} = ReadCompanylocations($q->param('companyid'));
		
		} elsif($q->param('action') eq 'editlocation') {

				$variables{'function'}  = 'modules/Customermanagement/editlocation';
				$variables{'locationdata'} = ReadLocationdata($q->param('target'));
		
		} elsif($q->param('action') eq 'newperson') {

				$variables{'function'} = 'modules/Customermanagement/newperson';
				$variables{'companydata'} = ReadCompanydata($q->param('companyid'));
		
		} elsif($q->param('action') eq 'writenewperson') {

				$variables{'function'} = 'modules/Customermanagement/companyinfo';
				$variables{'companydata'} = ReadCompanydata($q->param('companyid'));
				if(WriteNewPerson()) {
					goah::Modules->AddMessage('info',__("New person stored to database"));
				}
				$variables{'companypersonnel'} = ReadCompanypersonnel($q->param('companyid'));

		} elsif($q->param('action') eq 'editperson') {

				$variables{'function'}  = 'modules/Customermanagement/editperson';
				$variables{'persondata'} = ReadPersondata($q->param('target'));
		
		} elsif($q->param('action') eq 'writepersondata') {

				# Update location information into database
				WritePersondata($q->param('id'));
				$variables{'function'} = 'modules/Customermanagement/companyinfo';
				goah::Modules->AddMessage('info',__("Information updated"));
		
		} elsif($q->param('action') eq 'deleteperson') {

				if(DeletePerson($q->param('target'))) {
					goah::Modules->AddMessage('info',__("Person removed."));
				} else {
					goah::Modules->AddMessage('error',__("Couldn't remove person info from database!"));
				}
				$variables{'function'} = 'modules/Customermanagement/companyinfo';
				$variables{'companydata'} = ReadCompanydata($q->param('companyid'));
				$variables{'companypersonnel'} = ReadCompanypersonnel($q->param('companyid'));

		} elsif($q->param('action') eq 'customertypes') {

				$variables{'function'} = 'modules/Customermanagement/customertypes';

		} elsif($q->param('action') eq 'customergroups') {

				$variables{'function'} = 'modules/Customermanagement/customergroups';

		} elsif($q->param('action') eq 'newtype') {

                                # Store new customer type to database
                                unless(NewCustomerIdentifier("1",$q->param('type'))) {
                                        goah::Modules->AddMessage('info',__("New customer type added to database"));
                                }
				$variables{'function'} = 'modules/Customermanagement/customertypes';
				$variables{'submenuselect'}='customertypes';
                
		} elsif($q->param('action') eq 'deleteidentifier') {

                                # Celete customer type from database
                                unless(DeleteCustomerIdentifier($q->param('target'))) {
                                        goah::Modules->AddMessage('info',__("Data removed"));
                                }
				if($q->param('selector') eq 'type') {
					$variables{'function'} = 'modules/Customermanagement/customertypes';
					$variables{'submenuselect'}='customertypes';
				} else {
					$variables{'function'} = 'modules/Customermanagement/customergroups';
					$variables{'submenuselect'}='customergroups';
				}
                
		} elsif($q->param('action') eq 'edittype') {

                                # Update customertype
                                unless(EditCustomerIdentifier($q->param('target'),$q->param('type'))) {
                                        goah::Modules->AddMessage('info',__("Customertype updated"));
                                }
				$variables{'function'} = 'modules/Customermanagement/customertypes';
				$variables{'submenuselect'}='customertypes';
                
		} elsif($q->param('action') eq 'newgroup') {

                                # Store new customer group into database
                                unless(NewCustomerIdentifier("2",$q->param('group'))) {
                                        goah::Modules->AddMessage('info',__("New customer group added to database"));
                                }
				$variables{'function'} = 'modules/Customermanagement/customergroups';
				$variables{'submenuselect'}='customergroups';
                
		} elsif($q->param('action') eq 'editgroup') {

                                # Update customer group information
                                unless(EditCustomerIdentifier($q->param('target'),$q->param('group'))) {
                                        goah::Modules->AddMessage('info', __("Customer group information updated"));
                                }
				$variables{'function'} = 'modules/Customermanagement/customergroups';
				$variables{'submenuselect'}='customergroups';
                
		} else {
				goah::Modules->AddMessage('error',__("Module doesn't have function ")."'".$q->param('action')."'.");
				$variables{'function'} = 'modules/blank';
		}

	} else {
		$variables{'companies'} = ReadAllCompanies(1);
	}

	if($companyid eq '') {
		$companyid = $q->param('companyid');
	}

	$variables{'companylocations'} = ReadCompanylocations($companyid);
	$variables{'companypersonnel'} = ReadCompanypersonnel($companyid);
        $variables{'customertypes'} = ReadCustomerIdentifiers("1");
	$variables{'customergroups'} = ReadCustomerIdentifiers("2");
	$variables{'companylocations'} = ReadCompanylocations($companyid);
	$variables{'companypersonnel'} = ReadCompanypersonnel($companyid);
	$variables{'customeridentifier'} = sub { ReadCustomerIdentifier($_[0]) };

	if($companyid eq '') {
		$companyid = $q->param('companyid');
	}
	$variables{'companydata'} = ReadCompanydata($companyid);
	return \%variables;
}


###################################
#
# Modules internal functions
#


#
# Function: ReadSetup
#
#   Read setup variables for single category. This is an actual
#   copy of the function from the Systemsettings module since I'm
#   too tired to figure out proper namespace tricks so it'd work
#   when called from systemsettings module as well.
#
# Parameters:
#
#   category - Category name to be retrieved
#
# Returns:
#
#   Fail - 0
#   Success - Pointer to Class::DBI resource
#
sub ReadSetup {

        if($_[0]=~/goah::Modules::Systemsettings/) {
                shift;
        }

        unless($_[0]) {
                goah::Modules->AddMessage('error',__("Missing category to search settings"),__FILE__,__LINE__);
                return 0;
        }

        use goah::Database::Setup;
        my @data = goah::Database::Setup->search_where( { category => $_[0] }, { order_by => 'sort' } );

        if(scalar(@data)==0) {
                goah::Modules->AddMessage('debug',"Empty result set for settings with category ".$_[0],__FILE__,__LINE__);
                return 0;
        }

        return \@data;
}


#
# Function: ReadAllCompanies
#
#   Read all companies from database
#
# Parameters:
#
#   hash - If set, return data in processed Rose::DB hash instead of Class::DBI
#
# Returns:
#
#   If hash unset, Reference for Class::DBI result set, otherwise reference to hash array
#   containing all companies.
#
#   0 on error.
# 
sub ReadAllCompanies {

	if($_[0]=~/goah::Modules::Customermanagement/) {
		shift;
	}

	unless($_[0]) {
		goah::Modules->AddMessage('debug',"Old version of goah::Modules::Customermanagement->ReadAllCompanies",__FILE__,__LINE__);
		use goah::Database::Companies;
		my @data = goah::Database::Companies->search_where(
									{ isowner => { '!=', '1' },
									  hidden => { '!=', '1' } }, 
									{ order_by => 'name' }
								);
		return \@data;
	} 

	use goah::Db::Companies::Manager;
	my $datap = goah::Db::Companies::Manager->get_companies( sort_by => 'name' );

	if($datap==0) {
		goah::Modules->AddMessage('error',__("Couldn't find any companies from the database."),__FILE__,__LINE__);
		return 0;
	}
		
	my @data=@$datap;

	my %companydata;
	my $sortcounter=1000000;
	foreach my $d (@data) {
		while (my ($k,$v) = each (%companydbfieldnames)) {
			my %f = %$v;
			my $key=$f{'field'};
			$companydata{$sortcounter}{$key}=$d->$key;
		}
		$sortcounter++;
	}

	return \%companydata;
}

#
# Function: WriteNewCompany
#
#   Write new company information into database. Optionally write contact information
#   to database as well.
#
# Parameters:
#
#  None, uses HTTP variables
#
# Returns:
#
#  Fail - 0
#  Success - Databse id for newly created company
#
sub WriteNewCompany {

	my $q = CGI->new();

	use goah::Database::Companies;
	my %data;
	my %fieldinfo;
	while(my($key,$value) = each (%companydbfieldnames)) {
		%fieldinfo = %$value;
		if($fieldinfo{'field'} eq 'vat_id' && $q->param('individual') && $q->param('individual') eq 'on' ) {
			$data{'vat_id'}='00000000';
			next;
		}

		if($fieldinfo{'required'} == '1' && !($q->param($fieldinfo{'field'})) ) {
			goah::Modules->AddMessage('warn',__('Required field').' <b>'.$fieldinfo{'name'}.'</b> '.__('empty!'));
			return 0;
		}
		
		# Some bubblegum to fix overlapping field names on HTML form
		if($fieldinfo{'field'} eq 'firstname') {
			 $data{$fieldinfo{'field'}} = $q->param('firstname_comp');
		} elsif($q->param($fieldinfo{'field'})) {
			$data{$fieldinfo{'field'}} = $q->param(decode('utf-8',$fieldinfo{'field'}));
		}
	}

	$data{'isowner'} = '0';
	$data{'hidden'} = '0';
	my $tmp = goah::Database::Companies->insert(\%data);


	# Let's write new location information to database as well. Since actual WriteNewLocation -
	# function runs with HTTP -variables we have to do our own processing here at least for now.
	use goah::Database::Locations;
	%data = ();
	while(my($key,$value) = each (%locationdbfieldnames)) {
		%fieldinfo = %$value;
		if($fieldinfo{'required'} == '1' && !($q->param($fieldinfo{'field'})) ) {
			my $str = __('Required field').' <b>'.$fieldinfo{'name'}.'</b> '.__('empty!');
			$str.=' '.__("Won't write new location information");
			goah::Modules->AddMessage('warn',$str);
			return $tmp->id;
		}

		if($q->param($fieldinfo{'field'})) {
			$data{$fieldinfo{'field'}} = decode("utf-8",$q->param($fieldinfo{'field'}));
		}
	}

	# Since we just created new company assign address as default automatically
	$data{'defshipping'} = 'on';
	$data{'defbilling'} = 'on';
	$data{'companyid'} = $tmp->id;
	$data{'hidden'} = 0;
	goah::Database::Locations->insert(\%data);

	return $tmp->id;
}

#
# Function: WriteNewLocation
#
#   Write new location information into database
#
# Parameters:
#
#   None, uses HTTP variables
#
# Returns:
#
#   Fail - 0
#   Success - 1
#
sub WriteNewLocation {

	my $q = CGI->new();

	use goah::Database::Locations;
	my %data;
	my %fieldinfo;
	my @locations = goah::Database::Locations->search_where({ companyid => $q->param('companyid') });
	while(my($key,$value) = each (%locationdbfieldnames)) {
		%fieldinfo = %$value;
		if($fieldinfo{'required'} == '1' && !($q->param($fieldinfo{'field'})) ) {
			goah::Modules->AddMessage('warn',__('Required field').' <b>'.$fieldinfo{'name'}.'</b> '.__('empty!'));
			return 0;
		}

		if($q->param($fieldinfo{'field'})) {
			$data{$fieldinfo{'field'}} = decode("utf-8",$q->param($fieldinfo{'field'}));

			if($fieldinfo{'field'} eq 'defshipping') {
				foreach my $loc (@locations) {
					$loc->set('defshipping'=>'');
					$loc->update();
				}
			}

			if($fieldinfo{'field'} eq 'defbilling') {
				foreach my $loc (@locations) {
					$loc->set('defbilling'=>'');
					$loc->update();
				}
			}
		}
	}

	# If there's no other addresses then make newly created address
	# as default
	if(scalar(@locations) == 0) {
		$data{'defshipping'}='on';
		$data{'defbilling'}='on';
	}

	$data{'hidden'} = '0';

	goah::Database::Locations->insert(\%data);
	return 1;
}

#
# Function: ReadCompanydata
#
#   Read information for individual company from
#   database. 
#
# Parameters:
#
#   id - Parameter can be either VAT-id or database id
#   hash - If set, return data via Rose::DB
#
# Returns:
#
#  Fail - 0 
#  Success - Reference to Class::DBI result set
#  
sub ReadCompanydata {

	if($_[0]=~/goah::Modules::Customermanagement/) {
		shift;
	}

	my $var = $_[0];
	
	unless($_[1]) {
		goah::Modules->AddMessage('debug',"Old version of goah::Modules::Customermanagement->ReadCompanydata called",__FILE__,__LINE__);
		use goah::Database::Companies;
		my @data = goah::Database::Companies->search_where({ id => $var });

		if(scalar(@data) == 0) {
			@data = goah::Database::Companies->search_where({ vat_id => $var });
		}

		if(scalar(@data) == 0) {
			return 0;
		} 
		return $data[0];
	}


	unless($var && $var > 0) {
		goah::Modules->AddMessage('warn',__("No company id given, can't read company data!"),__FILE__,__LINE__);
		return 0;
	}

	use goah::Db::Companies;
	my $data = goah::Db::Companies->new( id => $var );

	unless($data->load(speculative => 1)) {
		$data = goah::Db::Companies->new( vat_id => $var );
		unless($data->load(speculative => 1)) {
			return 0;
		}
	}

	my %cdata;
	while(my($k,$v)=each(%companydbfieldnames)) {
		my %f=%$v;
		my $fn=$f{'field'};
		$cdata{$fn}=$data->$fn;
	}

	return \%cdata;

}

#
# Function: ReadCompanyLocations
#
#   Read company locations from database. 
#
# Parameters:
#
#   id - Company id from database.
#
sub ReadCompanylocations {

	if($_[0] && $_[0]=~/goah::Modules/) {
		shift;
	}

	my $var = $_[0];

	use goah::Database::Locations;
	my @data = goah::Database::Locations->search_where({ companyid => $var, hidden => { '!=', '1' } });

	if(scalar(@data) == 0) {
		return 0;
	}

	return \@data;
}

#
# Function: ReadDefaultLocations
#
#   Read database id's for default locations on given company. Useful on new
#   basket and invoice creation since we can assign default addresses automatically.
#
# Parameters:
#
#   companyid - Id for company
#
# Returns:
#
#   Success - Hash reference with keys shipping and billing and id as an value
#   Fail - 0 
#
sub ReadDefaultLocations {

        if($_[0]=~/goah::Modules::Customermanagement/) {
                shift;
        }

        my %loc;

        use goah::Database::Locations;
        # Read default shipping address
        my @data = goah::Database::Locations->search_where({ companyid => $_[0], defshipping => 'on' });

        # Check that we actually found an id
        if(scalar(@data) == 0) {
                goah::Modules->AddMessage('error',__("Can't read default shipping address for company id ".$_[0]),__FILE__,__LINE__);
                return 0;
        }

        $loc{'shipping'} = $data[0]->id;

        # Read default billing address
        @data = goah::Database::Locations->search_where({ companyid => $_[0], defbilling => 'on'} );

        # Check that we found an id
        if(scalar(@data) == 0) {
                goah::Modules->AddMessage('error',__("Can't read default billing address for company id ".$_[0]),__FILE__,__LINE__);
                return 0;
        }

        $loc{'billing'} = $data[0]->id;

        return \%loc;
}


#
# Function: ReadLocationdata
#
#   Read information for individual location
#
sub ReadLocationdata {

	if($_[0]=~/goah::Modules::Customermanagement/) {
		shift;
	}

	my $var = $_[0];

	unless($var =~ /^[0-9]+$/) {
		goah::Modules->AddMessage('error',__("Can't read location data!")." ".__("Search parameter isn't valid")." ($var).");
		return 0;
	}

	use goah::Database::Locations;
	my $data = goah::Database::Locations->retrieve($var);

	if($data->id != $var) {
		goah::Modules->AddMessage('error',__("Can't read location data!")." ".__("Id isn't valid."));
		return 0;
	} 

	return $data;
}

#
# Function: WriteCompanydata
#
#   Write modified information for company back to database
#
sub WriteCompanydata {

	my $q = CGI->new();
	
	unless($q->param('id')) {
		goah::Modules->AddMessage('error',__('ID -field missing.')." ".__("Can't update information in database!"));
		return 1;
	}

	use goah::Database::Companies;
	my $data = goah::Database::Companies->retrieve($q->param('id'));

	my %fieldinfo;
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
}

#
# Function: WriteLocationdata
#
#   Store modified information for location back to database
#
sub WriteLocationdata {

	my $q = CGI->new();
	unless($q->param('id')) {
		goah::Modules->AddMessage('error',__('ID -field missing.')." ".__("Can't update information in database!"));
		return 1;
	}

	use goah::Database::Locations;
	my $data = goah::Database::Locations->retrieve($q->param('id'));

	my %fieldinfo;
	while(my($key,$value) = each(%locationdbfieldnames)) {
		%fieldinfo = %$value;
		if($fieldinfo{'required'} == '1' && !($q->param($fieldinfo{'field'})) ) {
			# Using variable just to make source look nicer
			my $errstr = __('Required field').' <b>'.$fieldinfo{'name'}.'</b> '.__('empty!')." ";
			$errstr.= __("Leaving value unaltered.");
			goah::Modules->AddMessage('warn',$errstr);
		} else {
			if($q->param($fieldinfo{'field'})) {
				# If we're going to set default loation then clean up all other default
				# markings from the database. Since we're using checkbox the value isn't
				# populated if box is uncheked so this should be safe.
				my @locations = goah::Database::Locations->search_where({ companyid => $data->companyid, id => { '!=', $data->id } });

				if($fieldinfo{'field'} eq 'defshipping') {
					foreach my $loc (@locations) {
						$loc->set('defshipping'=>'');
						$loc->update();
					}
				}

				if($fieldinfo{'field'} eq 'defbilling') {
					foreach my $loc (@locations) {
						$loc->set('defbilling'=>'');
						$loc->update();
					}
				}
				$data->set($fieldinfo{'field'} => decode('utf-8',$q->param($fieldinfo{'field'})));
			} else {
				unless($fieldinfo{'field'} eq 'hidden') {
					$data->set($fieldinfo{'field'} => '');
				}
			}
		}
	}

	$data->update();

	return 1;
}

#
# Function: DeleteLocation
#
#   Delete location for company from database. 
#
# Parameters:
#  
#   id - database id
#
sub DeleteLocation {
	
	if($_[0]=~/goah::Modules::Customermanagement/) {
		shift;
	}

	my $var = $_[0];
	
	use goah::Database::Locations;
	my $data = goah::Database::Locations->retrieve($var);

	unless($data || $data->id == $var) {
		goah::Modules->AddMessage('debug',__("Id isn't valid.")." ".__("Can't remove location!"));
		return 0;
	}

	# Check if we're deleting default location. If so then just pick first
	# result from database and assign it as a default. This is likely not 
	# optimal, but I can't imagine anything more relevant which would be achieved
	# without massive amount of code.
	if($data->defshipping eq 'on') {
		my @locations = goah::Database::Locations->search_where({ companyid => $data->companyid, id => { '!=', $data->id } });
		unless(scalar (@locations) == 0) {
			my $tmp = $locations[0];
			$tmp->defshipping('on');
			$tmp->update();
			$tmp->commit();
			goah::Modules->AddMessage('debug',"New default shipping address: ".$tmp->addr1." to ".$tmp->companyid);
			goah::Modules->AddMessage('info',__("Default shipping address removed! Assigned new default address automatically."));
		}
	}
	if($data->defbilling eq 'on') {
		my @locations = goah::Database::Locations->search_where({ companyid => $data->companyid, id => { '!=', $data->id } });
		unless(scalar (@locations) == 0) {
			my $tmp = $locations[0];
			$tmp->defbilling('on');
			$tmp->update();
			$tmp->commit();
			goah::Modules->AddMessage('debug',"New default billing address: ".$tmp->addr1." to ".$tmp->companyid);
			goah::Modules->AddMessage('info',__("Default billing address removed! Assigned new default address automatically."));
		}
	}

	$data->hidden(1);
	$data->update();
	return 1;
}


#
# Function: DeleteCopmany
# 
#   Delete (hide) company from the database.
#
# Parameters:
#
#   id - ID from the database for company to be removed
#
# Returns:
#
#   Success - 1
#   Fail - 0 
#
sub DeleteCompany {

	unless($_[0] && $_[0]=~/^[0-9]+$/) {
		goah::Modules->AddMessage('error',__("Can't delete company information.").' '.__("Valid id is missing"));
		return 0;
	}

	use goah::Database::Companies;
	my $data = goah::Database::Companies->retrieve($_[0]);

	$data->hidden(1);
	$data->update();

	return 1;
}

# 
# Function: ReadCopmanypersonnel
#
#   Read personnel for company. 
#
# Parameters:
#
#  id - company id
#  uid - User id to search for
#
sub ReadCompanypersonnel {

	shift if ($_[0]=~/goah::Modules::Customermanagement/);

	my $id = $_[0];
	my $uid = $_[1];

	unless($id) {
		goah::Modules->AddMessage('error',__("Can't read company personnel! Company id is missing!"));
		return 0;
	}

	my %search;

	$search{'companyid'}=$id;
	$search{'id'}=$uid if($uid);

	use goah::Database::Persons;

	my @data = goah::Database::Persons->search_where(\%search);

	if(scalar(@data) == 0) {
		return 0;
	}

	return \@data;
}

#
# Function: WriteNewPerson
#
#   Store information about new person into database
#
# Parameters: 
# 
#   None, uses HTTP variables
#
# Returns:
#
#   Success - Id for newly created data
#   Fail - 0
#
sub WriteNewPerson {

	my $q = CGI->new();

	use goah::Database::Persons;
	my %data;
	my %fieldinfo;
	while(my($key,$value) = each (%persondbfieldnames)) {
	%fieldinfo = %$value;
		if($fieldinfo{'required'} == '1' && !($q->param($fieldinfo{'field'})) ) {
			goah::Modules->AddMessage('warn',__('Required field').' <b>'.$fieldinfo{'name'}.'</b> '.__('empty!'));
			return 0;
		}

		if($q->param($fieldinfo{'field'})) {
			$data{$fieldinfo{'field'}} = decode("utf-8",$q->param($fieldinfo{'field'}));
		}
	}

	my $tmp = goah::Database::Persons->insert(\%data);
	return $tmp->id;
}

#
# Function: ReadPersondata
#
#   Read information for individual person
#
# Parameters:
#
#   uid - User ID
#
# Returns: 
#
#   Success - Reference to Class::DBI result
#   Fail - 0
#
sub ReadPersondata {

	if($_[0]=~/goah::Modules::Customermanagement/) {
		shift;
	}

	my $var = $_[0];

	unless($var =~ /^[0-9]+$/) {
		goah::Modules->AddMessage('error',__("Can't read person data!")." ".__("Search parameter isn't valid")." ($var).");
		return 0;
	}

	use goah::Database::Persons;
	my $data = goah::Database::Persons->retrieve($var);

	if($data->id != $var) {
		goah::Modules->AddMessage('error',__("Can't read person data!")." ".__("Id isn't valid."));
		return 0;
	} 

	return $data;
}

#
# Function: WritePersondata
#
#   Store modified information for person back to database
# 
# Parameters:
#
#   None, uses HTTP variables
#
# Returns:
#
#   Fail - 1
#   Success - 0
#
sub WritePersondata {

	my $q = CGI->new();
	unless($q->param('id')) {
		goah::Modules->AddMessage('error',__('ID -field missing.')." ".__("Can't update information in database!"));
		return 1;
	}

	use goah::Database::Persons;
	my $data = goah::Database::Persons->retrieve($q->param('id'));

	my %fieldinfo;
	while(my($key,$value) = each(%persondbfieldnames)) {
		%fieldinfo = %$value;
		if($fieldinfo{'required'} == '1' && !($q->param($fieldinfo{'field'})) ) {
			# Using variable just to make source look nicer
			my $errstr = __('Required field').' <b>'.$fieldinfo{'name'}.'</b> '.__('empty!')." ";
			$errstr.= __("Leaving value unaltered.");
			goah::Modules->AddMessage('warn',$errstr);
		} else {
			if($q->param($fieldinfo{'field'})) {
				$data->set($fieldinfo{'field'} => decode('utf-8',$q->param($fieldinfo{'field'})));
			} else {
				$data->set($fieldinfo{'field'} => '');
			}
		}
	}

	$data->update();

	return 0;
}

# 
# Function: DeletePerson
#  
#   Function to retrieve and delete person information from the database
#
# Parameters:
#
#   id - User id from database to remove
#
# Returns:
#
#   0 - Fail
#   1 - Success
#
sub DeletePerson {

	shift if($_[0]=~/goah::Modules::Customermanagement/);

	unless($_[0]) {
		goah::Modules->AddMessage('error',__("Person ID missing! Can't remove person from database!"),__FILE__,__LINE__);
		return 0;
	}

	use goah::Database::Persons;
	my $data = goah::Database::Persons->retrieve($_[0]);

	goah::Modules->AddMessage('debug',"Got id ".$data->id.", retrieved id ".$_[0],__FILE__,__LINE__);

	unless($data->id == $_[0]) {
		goah::Modules->AddMessage('error',__("Couldn't retrieve user information from the database!"),__FILE__,__LINE__);
		return 0;
	}

	$data->delete;
	goah::Database::Persons->commit;

	return 1;
}

# 
# Function: ReadCustomerIdentifiers
#
#    Read customer parameters from database
#
# Parameters:
#
#   Parameter defines if return is customer groups or -types
#   If parameter is undefined or not allowed default is to read
#   customer types
#
#   type - 1=type, 2=group
# 
# Returns:
#   
#   Pointer to class::dbi result array
#
sub ReadCustomerIdentifiers {
	if($_[0] eq '' || !($_[0] =~/^[12]$/) ) {
		$_[0] = '1';
	}
	use goah::Database::customergroupsandtypes;
	my @data = goah::Database::customergroupsandtypes->search_where({ type => $_[0] },
									{ order_by => 'name' });
	return \@data;
}

#
# Function: ReadCustomerIdentifier
#
#    Read info for individual customer group / type. 
#
# Parameters:
#
#    id - Database id for identifier
#
# Returns:
#
#    Failure - 0
#    Success - Pointer to Class:DBI result
#
sub ReadCustomerIdentifier {
	
	if($_[0]=~/goah::Modules::Customermanagement/) {
		shift;
	}

	unless($_[0]) {
		goah::Modules->AddMessage('error',__("Can't read customer identifier!")." ".__("ID is missing!"));
		return 0;
	}
	
	use goah::Database::customergroupsandtypes;
	my $data = goah::Database::customergroupsandtypes->retrieve($_[0]);
	
	return $data;
}
#
# Function: NewCustomerIdentifier
#
#   Write new customer parameter into database
#
# Parameters:
#
#   type - 1 or 2 (type or group)
#   name - name for type or group
#
#   If type -parameter is omitted or not valid print an
#   error message and end execution. Same happens if
#   name -parameter is empty.
#
sub NewCustomerIdentifier {
	unless($_[0] =~/^[12]$/) {
		goah::Modules->AddMessage('error',__("Invalid selector for customer group/type!"));
		return 1;
	}

	if($_[1] eq '') {
		goah::Modules->AddMessage('error',__("Name for customer group/type is empty.")." ".__("Database query aborted."));
		return 1;
	}

	use goah::Database::customergroupsandtypes;
	
	# Check that we don't have duplicate entry for type
	my @tmp = goah::Database::customergroupsandtypes->search_where({type => $_[0], name => decode('utf-8',$_[1])});
	if(scalar(@tmp)>0) {
		if($_[0] == 1) {
			goah::Modules->AddMessage('error',__("Customer type already exists: ").$_[1],__FILE__,__LINE__);
		} else {
			goah::Modules->AddMessage('error',__("Customer group already exists: ").$_[1],__FILE__,__LINE__);
		}
		return 1;
	}

	goah::Database::customergroupsandtypes->insert({ type => $_[0], name => decode('utf-8',$_[1])});
	return 0;
}

#
# Function: DeleteCustomerIdentifier
#
#   Delete customer group or type from database
#
# Parameters:
#
#   id - Id-number to remove from database 
#
sub DeleteCustomerIdentifier {

	if( $_[0] eq '' || !($_[0]=~/[0-9]/) ) {
		goah::Modules->AddMessage('error',__("Missing or invalid id!")." ".__("Database query aborted."));
		return 1;
	}

	use goah::Database::customergroupsandtypes;

	goah::Modules->AddMessage('debug',__('Removing id ').$_[0]);

	my $data = goah::Database::customergroupsandtypes->retrieve($_[0]);
	if($data && $data->id == $_[0]) {
		$data->delete();
	} else {
		goah::Modules->AddMessage('error',__("Invalid ID!")." ".__("Database query aborted."));
	}

	return 0;
}

#
# Function: EditCustomerIdentifier
#
#   Update customer group or type information
#
# Parameters:
#
#   id - Id-number from database 
#   name - New name for group/type
#
sub EditCustomerIdentifier {

	if($_[0] eq '') {
		goah::Modules->AddMessage('error',__("Missing or invalid id!")." ".__("Can't update database item."));
		return 1;
	}

	if($_[1] eq '') {
		goah::Modules->AddMessage('error',__("Name for customer group/type is empty.")." ".__("Can't update database item."));
		return 1;
	}

	use goah::Database::customergroupsandtypes;

	my $data = goah::Database::customergroupsandtypes->retrieve($_[0]);

	my @tmp = goah::Database::customergroupsandtypes->search_where({type => $data->type, name => decode('utf-8',$_[1])});
	foreach my $test (@tmp) {

		unless($test->id eq $data->id) {
			if($data->type == 1) {
				goah::Modules->AddMessage('error',__("Customer type already exists, won't rename: ").$_[1],__FILE__,__LINE__);
			} else {
				goah::Modules->AddMessage('error',__("Customer group already exists, won't rename: ").$_[1],__FILE__,__LINE__);
			}
			return 1;
		}
	}

	$data->name(decode('utf-8',$_[1]));
	$data->update();

	return 0;
}


1;
