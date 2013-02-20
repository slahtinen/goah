#!/usr/bin/perl -w -CSDA 

=begin nd

Package: goah::Modules::Productmanagement

  This package has functions to handle products and their
  related information.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.
  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Modules::Productmanagement;

use Cwd;
use Locale::TextDomain ('Productmanagement', getcwd()."/locale");

use strict;
use warnings;
use utf8;
use Encode;
use CGI;
use goah::GoaH;

#
# String: uid
#
#   User id for package wide use
#
my $uid='';
my $settref='';
my %submenu;
my %manufdbfields;
my %groupdbfields;
my %productsdbfields;

#
# String: initvars
#
#   Helper variable to detect if package wide variables
#   have default values set
#
my $initvars=0;

#
# Function: InitVars
#
#   Function to initialize package wide variables. We need an separate
#   function so that we can properly call package functions directly from
#   other modules outside the normal run flow.
#
# Parameters:
#
#   None
#
# Returns:
#
#   0
#
sub InitVars {

	$initvars=1;

	%submenu = (		
			0 => {title => __("Products")},		
			1 => {title => __("Manufacturers"),action => 'manufacturers'},		
			2 => {title => __("Groups"), action => 'productgroups'},
			3 => {title => __("Add new product"), action => 'addnew&type=products'},
			4 => {title => __("Add new manufacturer"), action => 'addnew&type=manuf'},
			5 => {title => __("Add new group"), action => 'addnew&type=productgroups'}
		);

	#
	# It would make sense to move database definitions into separate file
	# or even better, into database definition files. There just seems to
	# be some issue with namespaces, so I decided to skeip that for now.
	%manufdbfields = (
			0 => { field => 'id', name => 'id', type => 'hidden', required => '0' },
			1 => { field => 'name', name => __("Name"), type => 'textfield', required => '1' },
			2 => { field => 'www', name => __("Website address"), type => 'textfield', required => '0' },
			3 => { field => 'info', name => __("Other information"), type => 'textarea', required => '0' },
			4 => { field => 'ean_gtin', name => __("EAN GTIN id"), type => 'textfield', required => '0' },
		);


	my %grouptypes = ( 	0 => { id => 0, name => __("Normal"), selected => 1},
				1 => { id => 1, name => __("Work") } );

	%groupdbfields = (
			0 => { field => 'id', name => 'id', type => 'hidden', required => '0' },
			1 => { field => 'grouptype', name => __('Type'), type => 'selectbox', required => '0', data => \%grouptypes },
			2 => { field => 'name', name => __("Name"), type => 'textfield', required => '1' },
			3 => { field => 'parent', name => 'parent', type => 'hidden', required => '0' },
			4 => { field => 'info', name => __("Description"), type => 'textarea', required => '0'} 
		);

	use goah::Modules::Systemsettings;
	use goah::Modules::Storagemanagement;
	%productsdbfields = (
			0 => { field => 'id', name => 'id', type => 'hidden', required => '0' },
			1 => { field => 'code', name => __("Product code"), type => 'textfield', required => '1' },
			2 => { field => 'name', name => __("Product name"), type => 'textfield', required => '1' },
			99 => { field => 'barcode', name => __("Barcode"), type => 'textfield', required => '0' },
			4 => { 	field => 'manufacturer', 
				name => __("Manufacturer"), 
				type => 'selectbox', 
				required => '0', 
				data => ReadData('manuf') },
			5 => { 	field => 'groupid', 
				name => __("Product group"), 
				type => 'selectbox', 
				required => '0', 
				data => ReadData('productgroups') },
			6 => { 	field => 'storage', 
				name => __("Storage"), 
				type => 'selectbox', 
				required => '0', 
				data => goah::Modules::Storagemanagement::ReadData('storages') },
			7 => { 	field => 'supplier', 
				name => __("Supplier"), 
				type => 'selectbox', 
				required => '0', 
				data => goah::Modules::Storagemanagement::ReadData('suppliers') },
			8 => { field => 'purchase', name => __("Purchase price"), type => 'textfield', required => '1' },
			9 => { field => 'sell', name => __("Selling price"), type => 'textfield', required => '0' },
			10 => { field => 'vat', 
				name => __("Vat class"), 
				type => 'selectbox', 
				required => '1', 
				data=>goah::Modules::Systemsettings->ReadSetup('vat') },
			91 => { field => 'unit', name => __("Unit"), type => 'textfield', required => '1' },
			92 => { field => 'info', name => __("Other information"), type => 'textarea', required => '0' },
			93 => { field => 'hidden', name => 'hidden', type => 'hidden', required => '0' },
			94 => { field => 'in_store', name => __('Amount in storage'), type => 'hidden', required => '0' },
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
#   uid - User ID
#   settings ref - Reference to user settings hash
#
# Returns:
#
#   Reference to hash array which contains variables for Template::Toolkit
#   process for the module.
#
sub Start {

	$uid = $_[1];
	$settref=$_[2];
	InitVars();
	
	my %variables;

	$variables{'function'} = 'modules/Productmanagement/productmanagement';
	$variables{'module'} = 'Productmanagement';
	$variables{'gettext'} = sub { return __($_[0]); };
	$variables{'submenu'} = \%submenu;
	$variables{'submenuselect'} = '-1';
	$variables{'manufdbfields'} = \%manufdbfields;
	$variables{'groupdbfields'} = \%groupdbfields;
	$variables{'productsdbfields'} = \%productsdbfields;
	$variables{'productgroups'} = ReadData('productgroups');

	my $q = CGI->new();
	
	my $action;
	if($q->param('action')) {
		my $function = 'modules/Productmanagement/';
		$action = $q->param('action');

		if($q->param('type')) {
			if($q->param('type') eq 'manuf') {
				$function.='manufacturers';
			} elsif($q->param('type') eq 'productgroups') {
				$function.='productgroups';
			} elsif($q->param('type') eq 'products') {
				$function.='products';
			} else {
				goah::Modules->AddMessage('error',__("Unknown parameter for function: ")."'".$q->param('type')."'");
				$action = '-1';
			}
		}

		if($action eq 'manufacturers') {
			$variables{'function'} = $function.'manufacturers';
		} elsif($action eq 'productgroups') {
			$variables{'function'} = $function.'productgroups';
		} elsif($action eq 'addnew') {

			$variables{'function'} = $function.'.new';
			if($q->param('subaction') && $q->param('subaction') eq 'ean') {
				$variables{'prefill'}=ReadProductPrefill($q->param('barcode'),$uid);
			}
			$variables{'storages'} = goah::Modules::Storagemanagement->ReadData('storages');

			goah::Modules->AddMessage('debug',"type: ".$q->param('type'));
			if($q->param('type') eq 'products') {
				$variables{'submenuselect'} = 'addnew&type=products';
			} elsif($q->param('type') eq 'manuf') {
				$variables{'submenuselect'}='addnew&type=manuf'
			} elsif($q->param('type') eq 'productgroups') {
				$variables{'submenuselect'} = 'addnew&type=productgroups'
			}


		} elsif($action eq 'writenew') {

			if(WriteNewItem() == 0) {
				goah::Modules->AddMessage('info',__("New item added to database"));
			} else {
				goah::Modules->AddMessage('error',__("Couldn't add new item into database"))
			}
			if($q->param('submit_addnew')) {
				$variables{'function'} = $function.'.new';
				if($q->param('type') eq 'products') {
					$variables{'submenuselect'} = 'addnew&type=products';
				} elsif($q->param('type') eq 'manuf') {
					$variables{'submenuselect'}='addnew&type=manuf'
				} elsif($q->param('type') eq 'productgroups') {
					$variables{'submenuselect'} = 'addnew&type=productgroups'
				}
			} else {
				$variables{'function'} = $function;
				if($q->param('type') eq 'products') {
					$variables{'submenuselect'} = '';
				} elsif($q->param('type') eq 'manuf') {
					$variables{'submenuselect'}='manufacturers';
				} elsif($q->param('type') eq 'productgroups') {
					$variables{'submenuselect'} = 'productgroups';
				}
			}
			$action='selectgroup';


		} elsif($action eq 'writeedited') {

			if(WriteEditedItem() == 0) {
				goah::Modules->AddMessage('info',__("Information updated"));
			} else {
				goah::Modules->AddMessage('error',__("Can't update database item"));
			}
			$variables{'function'} = $function;
			$variables{'storages'} = goah::Modules::Storagemanagement->ReadData('storages');
			$action='selectgroup';
			if($q->param('type') eq 'products') {
				$variables{'submenuselect'} = '';
			} elsif($q->param('type') eq 'manuf') {
				$variables{'submenuselect'}='manufacturers';
			} elsif($q->param('type') eq 'productgroups') {
				$variables{'submenuselect'} = 'productgroups';
			}

		} elsif($action eq 'edit') {

			$variables{'data'} = ReadData($q->param('type'),$q->param('id'));
			$variables{'function'} = $function.'.edit';
			goah::Modules->AddMessage('debug',"type: ".$q->param('type'));
			if($q->param('type') eq 'products') {
				$variables{'manufacturers'} = ReadData('manuf');
				$variables{'productgroups'} = ReadData('productgroups');
				goah::Modules->AddMessage('debug','Changed submenuselect');
				$variables{'submenuselect'} = '';
			} elsif($q->param('type') eq 'manuf') {
				$variables{'submenuselect'}='manufacturers';
			} elsif($q->param('type') eq 'productgroups') {
				$variables{'submenuselect'} = 'productgroups';
			}

		} elsif($action eq 'delete') {
			if(DeleteItem($q->param('type'),$q->param('id')) == 0) {
				goah::Modules->AddMessage('info',__("Information removed from database"));
			} else {
				goah::Modules->AddMessage('error',__("Can't remove database item"));
			}
			$variables{'function'} = $function;
		} elsif($action eq 'selectgroup' || $action eq 'searchbyname' || $action eq 'searchbycode') {
			# Dummy placeholder so that search-functions can be ran

		} else {
			goah::Modules->AddMessage('error',__("Module doesn't have function ")."'".$q->param('action')."'.");
			$variables{'function'} = 'modules/blank';
		}
	}
 
	#else { 
	#	$action='showall';
	#}

	if($action eq 'showall' || $action eq 'selectgroup' || $action eq 'searchbyname' || $action eq 'searchbycode') {
		# List all products on groups if no other action is defined
		my $prodgroupref = ReadData('productgroups');
		unless($prodgroupref) {
			goah::Modules->AddMessage('error',__("Couldn't read product groups from database!"),__FILE__,__LINE__);
			$variables{'produtgroups'}=0;
			$variables{'productspergroup'}=0;
			#$variables{'manufacturers'}=0;
			$variables{'storagetotalvalue'}=0;
		} else {
			my %productgroups=%$prodgroupref;
			my %productspergroup;
			my $storagetotalvalue=0;
			my $storagetotalvalue_vat0=0;
			foreach my $key (keys %productgroups) {
				my $gpoint = $productgroups{$key};
				my %group=%$gpoint;

				# Test if we have group selected on dropdown. This is 
				# somewhat dummy way to handle the situation, but 
				# should work
				if($action eq 'selectgroup') {
					unless($q->param('groupid') eq '-1') {
						unless($q->param('groupid') == $group{'id'}) {
							next;
						}
					}
					$variables{'groupid'}=$q->param('groupid');
				}


				my $prodpointer;
				if($action eq 'searchbyname') {
					$prodpointer=ReadProductsByName($q->param('name'),$group{'id'});
					$variables{'searchname'}=$q->param('name');
				} elsif($action eq 'searchbycode') {
					$prodpointer=ReadProductByCode($q->param('code'),$group{'id'},1);
					$variables{'searchcode'}=$q->param('code');
				} else {
					my $onlyinstorage=0;
					$onlyinstorage=1 if($q->param('onlyinstorage') && $q->param('onlyinstorage') eq 'on');
					my $includeremoved=0;
					$includeremoved=1 if($q->param('includeremoved') && $q->param('includeremoved') eq 'on');
					$prodpointer=ReadProductsByGroup($group{'id'},$uid,0,$onlyinstorage,$includeremoved);

					$variables{'check_onlyinstorage'}=$onlyinstorage;
					$variables{'check_includeremoved'}=$includeremoved;
				}

				unless($prodpointer) {
					unless($action=~/search/ || $action=~/selectgroup/) {
						goah::Modules->AddMessage('warn',__("Empty product group")." ".$group{'name'});
						$productspergroup{$key}{'products'}=0;
						$productspergroup{$key}{'name'}=$group{'name'};
						$productspergroup{$key}{'group_total_value'}=0;
					}
				} else {
					$productspergroup{$key}{'name'}=$group{'name'};
					$productspergroup{$key}{'group_total_value'}=0;
					$productspergroup{$key}{'products'}=$prodpointer;
					my %groupprods = %$prodpointer;
					foreach my $prodkey (keys %groupprods) {
						$storagetotalvalue+=$groupprods{$prodkey}{'row_total_value'};
						$storagetotalvalue_vat0+=$groupprods{$prodkey}{'row_total_value_vat0'};
						$productspergroup{$key}{'group_total_value_vat0'}+=$groupprods{$prodkey}{'row_total_value_vat0'};
						$productspergroup{$key}{'group_total_value'}+=$groupprods{$prodkey}{'row_total_value'};
					}
				}
			}
			$variables{'produtgroups'}=$prodgroupref;
			$variables{'productspergroup'}=\%productspergroup;
			#$variables{'manufacturers'}=ReadData('manuf');
			$variables{'storagetotalvalue_vat0'}=$storagetotalvalue_vat0;
			$variables{'storagetotalvalue'}=$storagetotalvalue;
		}	
	}
	$variables{'suppliers'} = goah::Modules::Storagemanagement->ReadData('suppliers');
	if($q->param('type') && ($q->param('type') eq 'manuf' || $action eq 'manufacturers' || $action eq 'addnew' || $action eq 'writenew')) {
		$variables{'manufacturers'} = ReadData('manuf');
	}

	if($q->param('type') && ($q->param('type') eq 'productgroups' || $action eq 'productgroups' || $action eq 'addnew' || $action eq 'writenew')) {
		$variables{'productgroups'} = ReadData('productgroups');
	}

	if($action eq 'writenew' || $action eq 'writeedited') {
		$variables{'products'} = ReadData('products');
	}
		

	$variables{'usersettings'} = $settref;

	return \%variables;
}


#
# Function: WriteNewItem
#
#    Write new item to database. Item can be manufacturer, productgroup
#    or an actual product.
#
# Parameters: 
#
#    None, flow is controlled via HTTP variables
#
# Returns:
#
#   Fail - 1
#   Success - 0
#
sub WriteNewItem {

	my $q = CGI->new();

	my %dbschema;
	my $db;
	# Select database schema to be used and get database variables
	# to different hash so we can loop trough any database with
	# single piece of code
	if($q->param('type') eq 'manuf') {
		use goah::Database::Manufacturers;
		$db = new goah::Database::Manufacturers;
		%dbschema = %manufdbfields;
	} elsif ($q->param('type') eq 'productgroups') {
		use goah::Database::Productgroups;
		$db = new goah::Database::Productgroups;
		%dbschema = %groupdbfields;
	} elsif ($q->param('type') eq 'products') {
		use goah::Database::Products;
		$db = new goah::Database::Products;
		%dbschema = %productsdbfields;
	} else {
		goah::Modules->AddMessage('error',__("Unknow type for writing new data into database"));
		return 1;
	}


	# Check that user can't insert duplicate products and that we have manufacturer and group
	if($q->param('type') eq 'products') {

		my $code=uc($q->param('code'));
		$code=~s/ä/Ä/g;
		$code=~s/ö/Ö/g;
		$code=~s/å/Å/g;
		my @data = $db->search_where([ code => $code, barcode => $q->param('barcode') ], { logic => 'OR'});
		if(scalar(@data)>0) {
			my $item=$data[0];
			if($item->hidden) {
				$item->hidden(0);
				$item->update();
				my $msg=__("Product already exists in database but it's removed from production! The product has been re-enabled with ORIGINAL information, not the one you provided!");
				$msg.=" <a href='?module=Productmanagement&action=edit&type=products&id=".$item->id."'>";
				$msg.=__("Open product information.")."</a>";
				goah::Modules->AddMessage('warn',$msg,__FILE__,__LINE__);
				return 1;
			} else {
				goah::Modules->AddMessage('error',__("Product already exists in database!"));
				return 1;
			}
		}

		if(($q->param('manufacturer') eq "-1") && !($q->param('manufacturer.new'))) {
			goah::Modules->AddMessage('error',__("Required value manufacturer missing!"));
			return 1;
		}
 
		if(($q->param('groupid') eq "-1") && !($q->param('groupid.new'))) {
			goah::Modules->AddMessage('error',__("Required value Product group missing!"));
			return 1;
		} 
	}

	# Check that user can't insert duplicate manufacturers
	if($q->param('type') eq 'manuf' || $q->param('type') eq 'productgroups') {
		my @data = $db->retrieve_all();
		foreach my $test (@data) {
			if(lc($test->name) eq lc($q->param('name'))) {
				if($q->param('type') eq 'manuf') {
					goah::Modules->AddMessage('error',__("Manufacturer already exists in database!"));
				} else {
					goah::Modules->AddMessage('error',__("Product group already exists in database!"));
				}
				return 1;
			}
		}
	}

	# It's possible to create both new manufacturer and new product group on
	# project creation. Obviously it's essential to check those as well, so
	# we'll do a bit ugly thing and read groups and manufacturers & check them
	# at this point. This however needs to be fixed, atleast now it feels that
	# the most convinient way would be to split up this function into few
	# helper functions.
	my $manufid=-1;
	if($q->param('type') eq 'products' && $q->param('manufacturer.new') && $q->param('manufacturer')==-1) {
		# For the manufacturer part
		my @data = goah::Database::Manufacturers->retrieve_all();
		foreach my $test (@data) {
			if(lc($test->name) eq lc($q->param('manufacturer.new'))) {
				goah::Modules->AddMessage('warn',__("Manufacturer already in database. Using manufacturer ")."<i>".$test->name."</i>",__LINE__,__FILE__);
				$manufid=$test->id;
			}
		}
		if($manufid==-1) {
			goah::Database::Manufacturers->insert( { name => $q->param('manufacturer.new') } );
			goah::Database::Manufacturers->commit;
			my @data = goah::Database::Manufacturers->search( name => $q->param('manufacturer.new') );
			$manufid = $data[0]->id;
		}
	}

	$manufid=$q->param('manufacturer') if($manufid==-1);

	my $prodgroupid=-1;
	if($q->param('type') eq 'products' && $q->param('groupid.new') && $q->param('groupid')==-1) {
		# For the product group part
		my @data = goah::Database::Productgroups->retrieve_all();
		foreach my $test (@data) {
			if(lc($test->name) eq lc($q->param('groupid.new'))) {
				goah::Modules->AddMessage('warn',__("Product group already in database. Using product group ")."<i>".$test->name."</i>",__FILE__,__LINE__);
				$prodgroupid=$test->id;
			}
		}
		if($prodgroupid==-1) {
			goah::Database::Productgroups->insert( { name => $q->param('groupid.new') } );
			goah::Database::Productgroups->commit;
			my @data = goah::Database::Productgroups->search( name => $q->param('groupid.new') );
			$prodgroupid=$data[0]->id;
		}
	}
	$prodgroupid=$q->param('groupid') if($prodgroupid==-1);

	# Loop trough database fields and create an hash to store into database.
	# Loop run has some additional features to format eq. currencies and some
	# other data.
	my %data;
	my %fieldinfo;
	while(my($key,$value) = each (%dbschema)) {
		%fieldinfo = %$value;
		if( $fieldinfo{'required'} == '1' && !($q->param($fieldinfo{'field'})) ) {

			# Check if we've got an VAT0 price, since only required field is incl.vat -field
			unless($q->param($fieldinfo{'field'}."_vat0")) {
				goah::Modules->AddMessage('warn',__('Required field').' <b>'.$fieldinfo{'name'}.'</b> '.__('empty!'));
				return 1;
			} else {
				goah::Modules->AddMessage('debug',"Required field ".$fieldinfo{'field'}." empty but overriding it with vat0-field",__FILE__,__LINE__);
			}
		}

		if( $fieldinfo{'required'} == '1' && $fieldinfo{'type'} eq 'selectbox' && $q->param($fieldinfo{'field'}) eq "-1" ) {
			goah::Modules->AddMessage('warn',__('Required dropdown field').' <b>'.$fieldinfo{'name'}.'</b> '.__("unselected!"));
			return 1;
		}


		if($fieldinfo{'field'} eq 'purchase' || $fieldinfo{'field'} eq 'sell') {

			if($q->param($fieldinfo{'field'}) || $q->param($fieldinfo{'field'}."_vat0") ) {

				# VAT0 price has priority
				if($q->param($fieldinfo{'field'}.'_vat0')) {
					goah::Modules->AddMessage('debug',"Got VAT0 price for field ".$fieldinfo{'field'},__FILE__,__LINE__);
					my $sum = $q->param($fieldinfo{'field'}.'_vat0');
					$data{$fieldinfo{'field'}}=goah::GoaH->FormatCurrencyNopref($sum,0,0,'in',0);
				} else {
					my $sum = $q->param($fieldinfo{'field'});
					my $vatp=goah::Modules::Systemsettings->ReadSetup($q->param('vat'));
					my %vath;
					unless($vatp) {
						my $msg=__("Couldn't get VAT class from setup! VAT calculations are incorrect!");
						goah::Modules->AddMessage('error',$msg,__FILE__,__LINE__);
					} else {
						%vath=%$vatp;
					}
					my $vat=$vath{'value'};
					$data{$fieldinfo{'field'}} = goah::GoaH->FormatCurrencyNopref($sum,$vat,1,'in',0);
				}
			}
	
		} elsif($fieldinfo{'field'} eq 'manufacturer') {
			$data{$fieldinfo{'field'}}=$manufid;
		} elsif($fieldinfo{'field'} eq 'groupid') {
			$data{$fieldinfo{'field'}}=$prodgroupid;
		} else {
			if($q->param($fieldinfo{'field'})) {
				$data{$fieldinfo{'field'}} = decode("utf-8",$q->param($fieldinfo{'field'}));
			}
		}
	}

	if($q->param('type') eq 'products') {
		$data{'hidden'} = 0;
		$data{'code'} = uc($data{'code'});
		$data{'code'} =~s/ä/Ä/g;
		$data{'code'} =~s/ö/Ö/g;
		$data{'code'} =~s/å/Å/g;
	}

	$db->insert(\%data);
	return 0;
}


#
# Function: WriteEditedItem
#  
#   Write updated item back into the database. Item can be
#   productgroup or an actual product.
#
# Parameters:
#
#   None, flow is controlled via HTTP variables
# 
# Returns:
#
#   Success - 0
#   Fail - 1
#
sub WriteEditedItem {

	my $q = CGI->new();

	unless($q->param('id')) {
		goah::Modules->AddMessage('error',__('ID -field missing.')." ".__("Can't update information in database!"));
		return 1;
	}

	my $db;
	my %dbschema;

	# Select database and schema to be used
	if($q->param('type') eq 'manuf') {
		use goah::Database::Manufacturers;
		$db = new goah::Database::Manufacturers;
		%dbschema = %manufdbfields;
	} elsif ($q->param('type') eq 'productgroups') {
		use goah::Database::Productgroups;
		$db = new goah::Database::Productgroups;
		%dbschema = %groupdbfields;
	} elsif ($q->param('type') eq 'products') {
		use goah::Database::Products;
		$db = new goah::Database::Products;
		%dbschema = %productsdbfields;
	} else {
		# Unknown type
		goah::Modules->AddMessage('error',__("Invalid DB identifier.")." ".__("Can't update information in database!"),__FILE__,__LINE__); 
		return 1;
	}

	# Check that user isn't changing product code to overlap another product
	if($q->param('type') eq 'products') {
		my @data = $db->search_where([ code => uc($q->param('code')), barcode => $q->param('barcode') ], { logic => 'OR'});

		foreach my $test (@data) {
			goah::Modules->AddMessage('debug',"Testing duplicates. ".$test->id." == ".$q->param('id')." for ".$test->name);
			unless($test->id == $q->param('id') && $test->hidden == 0) {
				goah::Modules->AddMessage('error',__("Changed product code already exists in database!"));
				return 1;
			}
		}
	}


	# Check that user isn't changing manufacturer to overlap another manufacturer
	if($q->param('type') eq 'manuf' || $q->param('type') eq 'productgroups') {
		my @data = $db->retrieve_all();
		foreach my $test (@data) {
			if(lc($test->name) eq lc($q->param('name'))) {
				unless($test->id == $q->param('id') ) {
					if($q->param('type') eq 'manuf') {
						goah::Modules->AddMessage('error',__("Changed manufacturer name already exists in database!"));
					} else {
						goah::Modules->AddMessage('error',__("Changed product group name already exists in database!"));
					}
					return 1;
				}
			}
		}
	}
	
	my $data = $db->retrieve($q->param('id'));
	my %fieldinfo;
	while(my($key,$value) = each (%dbschema)) {
		%fieldinfo = %$value;
		if($fieldinfo{'required'} == '1' && !($q->param($fieldinfo{'field'})) && !($fieldinfo{'field'} eq 'purchase') && !($fieldinfo{'field'} eq 'sell')) {
			# Using variable just to make source look nicer
			my $errstr = __('Required field').' <b>'.$fieldinfo{'name'}.'</b> '.__('empty!')." ";
			$errstr.= __("Leaving value unaltered.");
			 goah::Modules->AddMessage('warn',$errstr);
		} elsif($fieldinfo{'required'} == '1' && $fieldinfo{'type'} eq 'selectbox' && $q->param($fieldinfo{'field'}) eq "-1") {
			my $errstr = __('Required dropdown field').' <b>'.$fieldinfo{'name'}.'</b> '.__('unselected!').' ';
			$errstr.= __("Leaving value unaltered.");
			goah::Modules->AddMessage('warn',$errstr);
		} else {
			if($fieldinfo{'field'} eq 'purchase' || $fieldinfo{'field'} eq 'sell') {
			
				my $vatp=goah::Modules::Systemsettings->ReadSetup($data->vat);
				my %vat;
				unless($vatp) {
					goah::Modules->AddMessage('error',__("Couldn't get VAT class from setup! VAT calculations are incorrect!"),__FILE__,__LINE__);
				} else {
					%vat=%$vatp;
				}

				if($q->param($fieldinfo{'field'}) || $q->param($fieldinfo{'field'}."_vat0")) {

					# Check if price has been changed, VAT0 prices always have preference
					if($q->param($fieldinfo{'field'}."_vat0") ne $q->param($fieldinfo{'field'}."_vat0_orig")) {
						$data->set($fieldinfo{'field'} => 
							goah::GoaH->FormatCurrencyNopref($q->param($fieldinfo{'field'}."_vat0"),0,0,"in",0)
						);
					} elsif($q->param($fieldinfo{'field'}) ne $q->param($fieldinfo{'field'}."_orig")) {
						$data->set($fieldinfo{'field'} =>
							goah::GoaH->FormatCurrencyNopref($q->param($fieldinfo{'field'}),$vat{'value'},1,'in',0));
					}

					#my $sum = $q->param($fieldinfo{'field'});
					#my $vat = $q->param('vat');
					#$data->set($fieldinfo{'field'} => goah::GoaH->FormatCurrency($sum,$vat{'value'},$uid,'in',$settref));
				} else {
					$data->set($fieldinfo{'field'} => '0.00');
				}

			} else {
				if($q->param($fieldinfo{'field'})) {
					$data->set($fieldinfo{'field'} => decode('utf-8',$q->param($fieldinfo{'field'})));
					goah::Modules->AddMessage('debug',"Set ".$fieldinfo{'field'}." to value ".$data->get($fieldinfo{'field'}),__FILE__,__LINE__,caller());
				}
			}
		}
	}

	if($q->param('type') eq 'products') {
		$data->set('code' => uc($data->get('code')));
	}

	$data->update;
	return 0;
}

#
# Function: ReadData
#
#    Read item information from the database
#
# Parameters:
#
#    item - Item(s) to retrieve. manuf|productgroups|suppliers|products
#    id - Spesific id from the database so we can retrieve individual items
#    uid - Sometimes the module isn't "started" when then function is called, so provide UID via parameter.
#          If uid == -1, ignore all currency formatting
#    settref - Settings reference, for same reason than uid
#    internal - If set to 1 no currency conversions are made. This is used for internal usage, so that
#               whenever it's not necessary to actually (re-)format currencies the procedure can be skipped
#
# Returns:
#
#    Fail - 0
#    Success - Pointer to Class::DBI result set or if retrieving products an hash reference
#
sub ReadData {

	if($_[0]=~/goah::Modules::Productmanagement$/) {
		shift(@_);
	}

	unless($settref) {
		if($_[3]) {
			$settref=$_[3];
		}
	}

	if($uid eq '' && $_[0] eq 'products') {
		unless($_[2]) {
			$uid=0;
		} else {
			$uid = $_[2];
		}
	}

	my $db;
	my $sort = 'name';
	my %dbhash;
	if($_[0] eq 'manuf') {
		#use goah::Database::Manufacturers;
		#$db = new goah::Database::Manufacturers;
		use goah::Db::Manufacturers::Manager;
		%dbhash=%manufdbfields;
	} elsif ($_[0] eq 'productgroups') {
		#use goah::Database::Productgroups;
		#$db = new goah::Database::Productgroups;
		use goah::Db::Productgroups::Manager;
		%dbhash=%groupdbfields;
	} elsif ($_[0] eq 'products') {
		#use goah::Database::Products;
		#$db = new goah::Database::Products;
		use goah::Db::Products::Manager;
		%dbhash=%productsdbfields;
	} else {
		# Unknown type
		goah::Modules->AddMessage('debug', "Invalid DB identifier ".$_[0]."!",__FILE__,__LINE__);
		return 0;
	}

	if($initvars==0 && scalar(keys(%productsdbfields))==0) {
		$initvars=1;
		InitVars();
	}

	my @data;
	my %pdata;
	my $i=0;
	my $field;
	# Id not set, read all the items from the database
	if(!($_[1]) || $_[1] eq '') {
		unless($_[0] eq 'products') {
			if($_[0] eq 'manuf') {
				my $datap=goah::Db::Manufacturers::Manager->get_manufacturers( sort_by => $sort );
				@data = @$datap;
			} elsif($_[0] eq 'productgroups') {
				my $datap=goah::Db::Productgroups::Manager->get_productgroups( sort_by => $sort );
				@data=@$datap;
			} else {
				@data = $db->retrieve_all_sorted_by($sort);
			}
			my %mdata;
			my $sortcounter=10000000;
			foreach my $i (@data) {
				foreach my $k (keys %dbhash) {
					my $f=$dbhash{$k}{'field'};	
					if($_[0] eq 'manuf' || $_[0] eq 'productgroups') {
						$mdata{$sortcounter.".".$i->id}{$f}=$i->$f;
					} else {
						$mdata{$sortcounter.".".$i->id}{$f}=$i->get($f);
					}
				}
				$sortcounter++;
			}
			return \%mdata;
		} 

		#@data = $db->search_where( { hidden => { '!=', '1' } }, { order_by => $sort });
		#if(scalar(@data) == 0) {
		#	return 0;
		#}

		my $datap = goah::Db::Products::Manager->get_products( query => [ hidden => 0 ], sort_by => $sort );

		unless($datap) {
			return 0;
		}

		my @data=@$datap;

		my $storagetotal=0;
		foreach my $prod (@data) {
			my $vatp=goah::Modules::Systemsettings->ReadSetup($prod->vat);
			my %vat;
			unless($vatp) {
				goah::Modules->AddMessage('error',__("Couldn't get VAT class from setup! VAT calculations are incorrect!"),__FILE__,__LINE__);
			} else {
				%vat=%$vatp;
			}

			$pdata{$i}{'vatclass'}=$vat{'item'};
			$pdata{$i}{'vatvalue'}=$vat{'value'};

			foreach my $key (keys %productsdbfields) {
				$field = $productsdbfields{$key}{'field'};
				if($field eq 'purchase' || $field eq 'sell') {
					unless($_[4]) {
						$pdata{$i}{$field."_vat0"} = goah::GoaH->FormatCurrencyNopref($prod->$field,$vat{'value'},0,'out',0);
						$pdata{$i}{$field} = goah::GoaH->FormatCurrencyNopref($prod->$field,$vat{'value'},0,'out',1);
					} else {
						$pdata{$i}{$field} = $prod->$field;
					}
				} else {
					$pdata{$i}{$field} = $prod->$field;
				}
			}
			$pdata{$i}{'row_total_value'}=$pdata{$i}{'purchase'}*$pdata{$i}{'in_store'};
			$storagetotal+=$pdata{$i}{'row_total_value'};
			$i++;
		}
		$pdata{'storage_total_value'}=$storagetotal;
		return \%pdata;
	
	} else { # Read items by id 
		my $dbdata;
		if($_[0] eq 'manuf') {
			use goah::Db::Manufacturers;
			$dbdata = goah::Db::Manufacturers->new( id => $_[1]);
		} elsif ($_[0] eq 'productgroups') {
			use goah::Db::Productgroups;
			$dbdata = goah::Db::Productgroups->new( id => $_[1]);
		} elsif ($_[0] eq 'products') {
			use goah::Db::Products;
			$dbdata = goah::Db::Products->new(id => $_[1]);
		}

		unless($dbdata->load(speculative => 1)) {
			goah::Modules->AddMessage('error',__("Couldn't retrieve info for ").$_[0]." id ".$_[1],__FILE__,__LINE__);
		}
		unless($_[0] eq 'products') {
			return $dbdata;
		}

		%pdata = ();
		my $vatp=goah::Modules::Systemsettings->ReadSetup($dbdata->vat);
		my %vat;
		unless($vatp) {
			goah::Modules->AddMessage('error',__("Couldn't get VAT class from setup! VAT calculations are incorrect!"),__FILE__,__LINE__);
		} else {
			%vat=%$vatp;
		}

		$pdata{'vatclass'}=$vat{'item'};
		$pdata{'vatvalue'}=$vat{'value'};

		foreach my $key (keys %productsdbfields) {
			$field = $productsdbfields{$key}{'field'};
			if($field eq 'purchase' || $field eq 'sell') {
				unless($_[4] && $_[4] eq "1") {
					#$pdata{$field} = goah::GoaH->FormatCurrency($data[0]->get($field),$data[0]->get('vat'),$uid,'out',$settref);
					unless($dbdata->$field) {
						$pdata{$field."_vat0"} = 0;
						$pdata{$field}=0;
					} else {
						$pdata{$field."_vat0"} = goah::GoaH->FormatCurrencyNopref($dbdata->$field,$vat{'value'},0,'out',0);
						$pdata{$field} = goah::GoaH->FormatCurrencyNopref($dbdata->$field,$vat{'value'},0,'out',1);
					}
				} else {
						$pdata{$field} = $dbdata->$field;
				}
			} elsif($field eq 'name') {
				$pdata{$field}=$dbdata->$field;
				$pdata{$field}=~s/"/&quot;/g;
			#} elsif ($field eq 'vat') {
			#	$pdata{$field} = sprintf("%.2f",$dbdata->$field);
			} else {
				#$pdata{$field} = $data[0]->get($field);
				$pdata{$field} = $dbdata->$field;
			}
		}
		return \%pdata;
	}	

	return 0;
}

#
# Function: ReadProductByEAN
#
#   Additional function to retrieve product data. This is used to
#   retrieve product information via barcode (EAN) identifier.
#
# Parameters
#
#   barcode - Product's EAN
#
# Returns:
#
#   Fail - 0
#   Success - Product id
#
sub ReadProductByEAN {

	if($_[0]=~/Productmanagement/) {
		shift;
	}

	my $ean = '-1';
	if($_[0]) {
		$ean = $_[0];
	} else {
		goah::Modules->AddMessage('error',__("Didn't receive EAN, can't search products!"),__FILE__,__LINE__);
		return 0;
	}

	use goah::Database::Products;
	my @product = goah::Database::Products->search_where(barcode => $ean);
	
	if(scalar(@product)==0) {
		return 0;
	}

	my $prod = $product[0];
	return $prod->id;
}

# Function: ReadProductByName
#
#   Additional function to retrieve product data based on the product
#   name. This is separate function, since ReadProductByCode has alternative
#   uses and there's no way to know if search-by-name functionality causes
#   any issues.
#
# Parameters:
#
#   Name - Product name to search, * allowed as an wildcard
#   Group id - Product group id to search
#
# Returns:
#   
#   Fail - 0
#   Success - Hash -reference to found products
#
sub ReadProductsByName {

	shift if($_[0]=~/goah::Modules::Productmanagement/);

	unless($_[0]) {
		goah::Modules->AddMessage('error',__("No search parameters given! Can't search products by name."));
		return 0;
	}

	my $prodname=uc($_[0]);
	$prodname=~s/\*/%/g;
	my %search;
	$search{'name'} = { like => $prodname };
	if($_[1]) {
		$search{'groupid'}=$_[1];
	} 

	use goah::Db::Products::Manager;
	my $datap=goah::Db::Products::Manager->get_products(\%search, sort_by => 'code' );

	unless($datap) {
		return 0;
	}
	my @data=@$datap;

	unless(scalar(@data)) {
		return 0;
	}

	unless(scalar(keys(%productsdbfields))) {
		InitVars;
	}

	# Pack found data into hash and return data
	my %pdata;
	my $field;
	my $vatp=goah::Modules::Systemsettings->ReadSetup('vat');
	my %vat=%$vatp;
	my $i=100000;
	foreach my $prod (@data) {
		while (my ($key,$value) = each(%vat)) {
			my %tmp=%$value;
			if($tmp{'id'} == $prod->vat) {
				$pdata{$i}{'vatclass'}=$tmp{'item'};
				$pdata{$i}{'vatvalue'}=$tmp{'value'}
			}
		}
		foreach my $key (keys %productsdbfields) {
			$field = $productsdbfields{$key}{'field'};
			if($field eq 'purchase' || $field eq 'sell') {
				$pdata{$i}{$field} = goah::GoaH->FormatCurrencyNopref($prod->$field,$pdata{$i}{'vatvalue'},0,'out',1,2);
				$pdata{$i}{$field."_vat0"} = goah::GoaH->FormatCurrencyNopref($prod->$field,$pdata{$i}{'vatvalue'},0,'out',0,3);
			} else {
				$pdata{$i}{$field} = $prod->$field;
			}
		}
		my $manuf = ReadData('manuf',$prod->manufacturer);
		if($manuf) {
			my %m=%$manuf;
			$pdata{$i}{'manufacturer_name'}=$m{'name'};
		}
		if($prod->in_store>0) {
			$pdata{$i}{'row_total_value_vat0'}=goah::GoaH->FormatCurrencyNopref($prod->purchase*$prod->in_store,0,0,'out',0);
			$pdata{$i}{'row_total_value'}=goah::GoaH->FormatCurrencyNopref( $prod->purchase*$prod->in_store,
											$pdata{$i}{'vatvalue'},0,'out',1);
		} else {
			$pdata{$i}{'row_total_value'}=0.00;
			$pdata{$i}{'row_total_value_vat0'}=0.000;
		}
		$i++;
	}

	return \%pdata;
}

#
# Function: ReadProductByCode
#
#   Additional function to retrieve product data. This is used to
#   retrieve product information via manufacturer product code.
#
# Parameters
#
#   Product code - Manufacturer's code
#   Product group - Group id to search, if omitted deafults to all
#   Format - Return data in old/new format, if omitted defaults to 0 (=old)
#   uid - User ID, used for VAT calculations in case the module isn't "started"
#   settref - Settings reference, used for VAT calculations like uid
#
# Returns:
#
#   Fail - 0
#   Success - Product id
#
sub ReadProductByCode {

	if($_[0]=~/goah::Modules::Productmanagement/) {
		shift;
	}


	unless($uid && $_[3]) {
		$uid=$_[3];
	}

	unless($settref && $_[4]) {
		$settref=$_[4];
	}

	my $prodcode = '-1';
	if($_[0]) {
		$prodcode = uc(decode('utf-8',$_[0]));
		$prodcode=~s/ä/Ä/g;
		$prodcode=~s/ö/Ö/g;
		$prodcode=~s/å/Å/g;
	} else {
		goah::Modules->AddMessage('error',__("Didn't receive product code, can't search products!"),__FILE__,__LINE__);
		return 0;
	}

	unless($_[2]) {
		goah::Modules->AddMessage('debug',"Using old version of ReadProductByCode",__LINE__,__FILE__,caller());
	}

	#goah::Modules->AddMessage('debug',"Retrieving data with code $prodcode",__LINE__,__FILE__);

	# If we're using old format then return single item found
	unless($_[2]) {
		use goah::Database::Products;
		my @product = goah::Database::Products->search_where(code => $prodcode);
	
		if(scalar(@product)==0) {
			return 0;
		}
		
		my $prod = $product[0];
		return $prod->id;
	}

	# Wildcard search
	$prodcode=~s/\*/%/g;

	# Assemble search hash
	my %search;
	$search{'code'}= { like => $prodcode };
	if($_[1]) {
		$search{'groupid'}=$_[1];
	}

	use goah::Db::Products::Manager;
	my $datap=goah::Db::Products::Manager->get_products(\%search, sort_by => 'code' );

	unless($datap) {
		return 0;
	}
	my @data=@$datap;

	# Don't return empty hash, if we don't have products, we don't have products.
	if(scalar(@data)==0) {
		return 0;
	}


	unless(scalar(keys(%productsdbfields))) {
		InitVars;
	}

	# Pack found data into hash and return data in new format
	my %pdata;
	my $field;
	my $vatp=goah::Modules::Systemsettings->ReadSetup('vat');
	my %vat=%$vatp;
	my $i=100000;
	foreach my $prod (@data) {
		while (my ($key,$value) = each(%vat)) {
			my %tmp=%$value;
			if($tmp{'id'} == $prod->vat) {
				$pdata{$i}{'vatclass'}=$tmp{'item'};
				$pdata{$i}{'vatvalue'}=$tmp{'value'};
			}
		}
		foreach my $key (keys %productsdbfields) {
			$field = $productsdbfields{$key}{'field'};
			if($field eq 'purchase' || $field eq 'sell') {
				$pdata{$i}{$field."_vat0"}=goah::GoaH->FormatCurrencyNopref($prod->$field,0,0,'out',0);
				$pdata{$i}{$field}=goah::GoaH->FormatCurrencyNopref($prod->$field,$pdata{$i}{'vatvalue'},0,'out',1);
			} else {
				$pdata{$i}{$field} = $prod->$field;
			}
		}
		my $manuf = ReadData('manuf',$prod->manufacturer);
		if($manuf) {
			my %m=%$manuf;
			$pdata{$i}{'manufacturer_name'}=$m{'name'};
		}
		if($prod->in_store>0) {
			$pdata{$i}{'row_total_value_vat0'}=goah::GoaH->FormatCurrencyNopref($prod->purchase*$prod->in_store,0,0,'out',0);
			$pdata{$i}{'row_total_value'}=goah::GoaH->FormatCurrencyNopref(	$prod->purchase*$prod->in_store,
											$pdata{$i}{'vatvalue'},0,'out',1);

		} else {
			$pdata{$i}{'row_total_value'}=0.00;
			$pdata{$i}{'row_total_value_vat0'}=0.000;
		}

		$i++
	}
	return \%pdata;
}


#
# Function: ReadProductsByGroup
#
#    Read products assigned to single group from the database.
#
# Parameters:
#
#    groupid - ID number for group to read products. If groupid isn't given read all
#    	       products which aren't in any group.
#    uid - OBSOLETE VARIABLE! Should be removed!
#    noprice - If set ignore prices and VAT calculations when searching only for product names and codes
#    onlyinstorage - If set search only for products in storage
#    includeremoved - If set include removed products into search
#
# Returns:
#
#    Fail - 0 
#    Success - Hash reference to products
#
sub ReadProductsByGroup {

	if($_[0]=~/Productmanagement/) {
		shift;
	}

	unless($uid) {
		$uid=$_[1];
	}

	# TODO: This should fall back to default settings instead of failing! It might give unexpected results
	# ie. when user waits for an price including VAT and the returned value is without, so there needs to 
	# be an clear notification to the user when it happens.
	if($uid && $uid eq '') {
		if($_[1]) {
			$uid = $_[1];
		} else {
			goah::Modules->AddMessage('error',__("UID missing, can't read products by group."),__FILE__,__LINE__);
			return 0;
		}
	}
	##goah::Modules->AddMessage('debug',"Got UID $uid at ReadProductsByGroup",__FILE__,__LINE__,caller());

	my $search = '-1';
	if($_[0]) {
		$search = $_[0];
	}


	my %dbsearch;
	$dbsearch{'hidden'}=0 unless($_[4]);
	$dbsearch{'groupid'}=$search;

	# Search only for products in storage
	if($_[3]) {
		$dbsearch{'in_store'}={ gt => 0 };
	}
	
	use goah::Db::Products::Manager;
	#my $dbdata = goah::Db::Products::Manager->get_products( query => [ hidden => 0, groupid => $search ], sort_by => 'code' );
	my $dbdata = goah::Db::Products::Manager->get_products(\%dbsearch, sort_by => 'code' );
	unless($dbdata) {
		return 0;
	}

	my @data=@$dbdata;
	unless(scalar(@data)) {
		return 0;
	}
	
	if(scalar(keys(%productsdbfields))==0) {
		InitVars();
	}
	
	# Pack retrieved data to hash and return it
	my %pdata;
	my $field;
	my $i=100000;
	my $vatp=goah::Modules::Systemsettings->ReadSetup('vat');
	my %vat=%$vatp;
	foreach my $prod (@data) {
		while (my ($key,$value) = each(%vat)) {
			my %tmp=%$value;
			if($tmp{'id'} == $prod->vat) {
				$pdata{$i}{'vatclass'}=$tmp{'item'};
				$pdata{$i}{'vatvalue'}=$tmp{'value'};
			}
		}
		foreach my $key (keys %productsdbfields) {
			$field = $productsdbfields{$key}{'field'};
			if( ($field eq 'purchase' || $field eq 'sell') && $_[2]!=1 ) {
				unless($prod->$field) {
					$pdata{$i}{$field}=0;
				} else {
					$pdata{$i}{$field."_vat0"} = goah::GoaH->FormatCurrencyNopref($prod->$field,0,0,'out',0);
					$pdata{$i}{$field} = goah::GoaH->FormatCurrencyNopref($prod->$field,$pdata{$i}{'vatvalue'},0,'out',1);
				}
			} else {
				$pdata{$i}{$field} = $prod->$field;
			}
		}
		my $manuf = ReadData('manuf',$prod->manufacturer);
		if($manuf) {
			my %m=%$manuf;
			$pdata{$i}{'manufacturer_name'}=$m{'name'};
		}

		if($_[2]!=1) {
			if($prod->in_store) {
				$pdata{$i}{'row_total_value_vat0'} = goah::GoaH->FormatCurrencyNopref($prod->purchase*$prod->in_store,0,0,'out',0);
				$pdata{$i}{'row_total_value'}=goah::GoaH->FormatCurrencyNopref($prod->purchase*$prod->in_store,$pdata{$i}{'vatvalue'},0,'out',1);
			} else {
				$pdata{$i}{'row_total_value_vat0'}=0;
				$pdata{$i}{'row_total_value'}=0;
			}

		} else {
			$pdata{$i}{'row_total_value_vat0'}=0;
			$pdata{$i}{'row_total_value'}=0;
			$pdata{$i}{'row_total_value'}=$prod->purchase*$prod->in_store if($prod->in_store);
			$pdata{$i}{'row_total_value_vat0'}=$pdata{$i}{'row_total_value'} if($prod->in_store);

		}
		$i++;
	}

	return \%pdata;
}


#
# Function: ReadProductsByGrouptype
#
#  Function to read products based on group type
#
# Parameters:
#
#   type - Group type id
#   uid - User ID
#
# Returns:
#
#   Fail - 0
#   Success - Hash reference to products
#
sub ReadProductsByGrouptype {

	shift if($_[0]=~/goah::Modules::Productmanagement/);

	unless($_[0]) {
		goah::Modules->AddMessage('error',__("No group type spesified. Can't search products by product group type!"),__FILE__,__LINE__);
		return 0;
	}

	if($uid && $uid eq '') {
		unless($_[1]) {
			# The message below isn't actually true yet, ReadProductsByGroup fails without UID, it should
			# be changed to this behaviour as well. There's an ticket open.
			goah::Modules->AddMessage('warn',__("No UID given, returning prices without VAT regardless of user setting!"),__FILE__,__LINE__);
		} else {
			$uid=$_[1];
		}
	}
	goah::Modules->AddMessage('debug',"Got uid $uid at ReadProductsByGrouptype",__FILE__,__LINE__,caller());

	use goah::Db::Productgroups::Manager;
	my $groupsref = goah::Db::Productgroups::Manager->get_productgroups( query => [ grouptype => $_[0] ], sort_by => 'name' );

	return 0 unless($groupsref);

	my @groups = @$groupsref;

	# Pack found data into an hash and return it
	my %proddata;
	my $group_prod_ref;
	my %group_prod;
	my $i=100000;
	foreach my $g (@groups) {
		$group_prod_ref = ReadProductsByGroup($g->id,$uid,1);
		unless($group_prod_ref) {
			goah::Modules->AddMessage('warn',__("Empty product group: ").$g->name,__FILE__,__LINE__);
			next;
		}
		%group_prod=%$group_prod_ref;
		foreach my $key (sort keys %group_prod) {
			$i++;
			my $prod_ref = $group_prod{$key};
			my %tmp = %$prod_ref;
			foreach my $field (keys %tmp) {
				$proddata{$i}{$field}=$tmp{$field};
			}
			$proddata{$i}{'groupname'}=$g->name;
		}
	}
		
	return \%proddata;

}

#
# Function: DeleteItem
#
#   Delete (or hide) an item from the database. Hiding equals setting 'hidden' -value on the
#   row to 1, so we don't actually lose valuable information.
#
# Parameters:
#
#   type - Data type to be removed (manuf|productgroups|products)
#   id - Database row id to be removed
#
# Returns:
#
#   Success - 0
#   Fail - 1
#
sub DeleteItem {
	
	unless($_[1]) {
		goah::Modules->AddMessage('error',__("Missing ID, can't remove data from database"));
		return 1;
	}

	unless($_[0]) {
		goah::Modules->AddMessage('error',__("Missing type, can't remove data from database"));
		return 1;
	}

        my $db;
        if($_[0] eq 'manuf') {
                use goah::Database::Manufacturers;
                $db = new goah::Database::Manufacturers;
        } elsif ($_[0] eq 'productgroups') {
		use goah::Database::Productgroups;
		$db = new goah::Database::Productgroups;
	} elsif ($_[0] eq 'products') {
		use goah::Database::Products;
		$db = new goah::Database::Products;
	}

	my $data = $db->retrieve($_[1]);

	# If we're handling products set hidden -value to 1 instead of actually
	# removing an item from the database.
	if($_[0] eq 'products') {
		$data->hidden(1);
		$data->update();
	} else {
		$data->delete;
	}
	
	return 0;
}

#
# Function: ReadProductPrefill
#
#   Function to read prefilled data for new product. Prefill data can be read from CSV-file from
#   the supplier. This will reduce manual work quite a bit. Currently this is only supported for
#   single format. CSV-files need to be placed into csv/ -directory.
#
# Parametes:
#
#   ean - Products EAN code
#
# Returns:
#
#   data - Hash reference for product data
#
sub ReadProductPrefill {

	my %data;
	opendir(CSVS,cwd()."/csv");
	my @files = readdir(CSVS);
	closedir(CSVS);

	use Encode;
	foreach my $file (@files) {

		unless($file=~/\.csv$/) {
			next;
		}

		open(DATA, cwd()."/csv/".$file);
		my @data=<DATA>;
		close(DATA);

		foreach my $row (@data) {

			my @rowdata = split(";",$row);

			if($rowdata[7] == $_[0]) {
				$data{'barcode'} = $_[0];
				$data{'code'} = encode('utf-8',$rowdata[1]);
				$data{'name'} = encode('utf-8',$rowdata[3]);
				$data{'manufacturer'} = encode('utf-8',$rowdata[0]);
				$data{'groupid'} = encode('utf-8',$rowdata[2]);
				$data{'purchase'} = goah::GoaH->FormatCurrency($rowdata[4],"23",$_[1],'out',$settref);
				$data{'unit'} = 'kpl'; # Hardcoded.
				return \%data;
			}

		}
	}

	#my %data = ( code => 'ABC-123', name => "Prefilled product", manufacturer => 'OnSe', purchase => '100.23', unit => 'kpl', barcode => $_[0] );

	return;

}

1;
