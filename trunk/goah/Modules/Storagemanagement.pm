#!/usr/bin/perl -w -CSDA

=begin nd

Package: goah::Modules::Storagemanagement

  This package has functions to manage storage "contents" and
  actual storage places.

About: License

  This software is copyritght (c) 2009 by Tietovirta Oy and associates.
  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Modules::Storagemanagement;

use Cwd;
use Locale::TextDomain ('Storagemanagement', getcwd()."/locale");

use strict;
use warnings;
use utf8;
use Encode;
use CGI;
use goah::GoaH;


#
# Hash: submenu
#
#   Defines an submenu for the module. 
#
my %submenu = (	
		1 => {title => __("Storages"), action => 'storages'},
		2 => {title => __("Suppliers"), action => 'suppliers'},
		3 => {title => __("Incoming orders"),action => 'shipments'},
		4 => {title => __("Inventory"), action => 'inventory'},
		);

#
# Hash: storagedbfields
#
#   Database fields and descriptions for storage management. With these
#   it's possible to simply create forms and update database content.
#
my %storagedbfields = (
	0 => { field => 'id', name => 'id', type => 'hidden', required => '0' },
	1 => { field => 'name', name => __("Name"), type => 'textfield', required => '1' },
	2 => { field => 'location', name => __("Location"), type => 'textarea', required => '1' },
	4 => { field => 'info', name => __("Other information"), type => 'textarea', required => '0' },
	5 => { field => 'remote', name => __("Remote storage (ie. suppliers storage)"), type => 'checkbox', required => '0' },
	6 => { field => 'def', name => __("Default storage"), type => 'checkbox', required => '0' },
);

#
# Hash: supplierdbfields
#
#   Database fields and descriptions for suppliers
#
my %supplierdbfields = (
	0 => { field => 'id', name => 'id', type => 'hidden', required => '0' },
	1 => { field => 'name', name => __("Name"), type => 'textfield', required => '1' },
	2 => { field => 'www', name => __("Website address"), type => 'textfield', required => '0' },
	3 => { field => 'contact', name => __("Contact information"), type => 'textarea', required => '0' },
	4 => { field => 'info', name => __("Other information"), type => 'textarea', required => '0' }
);


#
# Hash: shipmentdbfields
#
#   Database fields and descriptions for shipments general data
#
my %shipmentdbfields = (
	0 => { field => 'id', name => 'id', type => 'hidden', required => '0' },
	1 => { field => 'supplierid', name => __('Supplier'), type => 'selectbox', required => '1', data => ReadData('suppliers') },
	2 => { field => 'destination', name => __("Destination storage"), type => 'selectbox', required => '1', data => ReadData('storages') },
	3 => { field => 'created', name => __("Created"), type => 'textfield', required => '0' },
	4 => { field => 'due', name => __("Due"), type => 'textfield', required => '0' },
	5 => { field => 'updated', name => __("Last updated"), type => 'textfield', required => '0' },
	6 => { field => 'shipmentnum', name => __("Shipment number"), type => 'textfield', required => '0' },
	7 => { field => 'received', name => __("Shipment received"), type => 'checkbox', required => '0' },
	8 => { field => 'info', name => __("Additional information"), type => 'textarea', required => '0' }
);


#
# Hash: shipmentrowdbfields
#
#   Database fields and descriptions for incoming shipment rows
#
my %shipmentrowdbfields = (
	0 => { field => 'id', name => 'id', type => 'hidden', required => '0' },
	1 => { field => 'shipmentid', name => 'shipmentid', type => 'hidden', required => '9' },
	2 => { field => 'productid', name => __("Product"), type => 'selectbox', data => '0' },
	3 => { field => 'purchase', name => __("Purchase price'"), type => 'textbox', required => '0' },
	4 => { field => 'amount', name => __("Amount"), type => 'textbox', required => '9' },
	5 => { field => 'rowinfo', name => __("Additional information"), type => 'textbox', required => '9' }
);


# 
# Hash: inventorydbfields
#
#   Database fields and descriptions for inventories
#
my %inventorydbfields = (
	0 => { field => 'id', name => 'id', type => 'hidden', required => '0' },
	1 => { field => 'created', name => __("Created"), type => 'textfield', required => '0' },
	2 => { field => 'info', name => __("Additional information"), type => 'textarea', required => '0' },
	3 => { field => 'done', name => __("Completed"), type=>'textfield', required=>'0' },
);

#
# Hash: inventoryrowdbfields
#
#    Database fields and descriptions for inventory rows
#
my %inventoryrowdbfields = (
	0 => { field => 'id', name => 'id', type => 'hidden', required => '0' },
	1 => { field => 'inventoryid', name => 'inventoryid', type => 'hidden', required => '9' },
	2 => { field => 'productid', name => __("Product"), type => 'selectbox', data => '0' },
	3 => { field => 'amount_before', name => __("Amount before"), type => 'textbox', required => '0' },
	4 => { field => 'amount_after', name => __("Amount after"), type => 'textbox', required => '1' },
	5 => { field => 'rowinfo', name=>__("Additional info"), type=>'textbox', required=>'0' },
);


#
# String: uid
#
#   User id
#
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
#   None
#
# Returns:
#
#   Reference to hash array which contains variables for Template::Toolkit
#   process for the module.
#
sub Start {

	$uid = $_[1];
	$settref = $_[2];
	
	my %variables;

	# Database fields
	$variables{'storagedbfields'} = \%storagedbfields;
	$variables{'supplierdbfields'} = \%supplierdbfields;
	$variables{'shipmentdbfields'} = \%shipmentdbfields;
	$variables{'inventorydbfields'} = \%inventorydbfields;

	$variables{'function'} = 'modules/Storagemanagement/storagemanagement';
	$variables{'module'} = 'Storagemanagement';
	$variables{'gettext'} = sub { return __($_[0]); };
	$variables{'submenu'} = \%submenu;

	use goah::Modules::Productmanagement;

        use goah::Modules::Personalsettings;
	$variables{'usersettings'} = sub { goah::Modules::Personalsettings::ReadSettings($uid) };

	my $q = CGI->new();
	
	# Load storages as default submodule. This should be added to module settings when it's implemented.
	unless ($q->param('action')) {
		$q->param( action => 'storages');
	}
	
	if($q->param('action')) {
		my $function = 'modules/Storagemanagement/';
		my $action = $q->param('action');

		if($q->param('type')) {
			if($q->param('type') eq 'storages') {
				$function.='storages';
			} elsif($q->param('type') eq 'suppliers') {
				$function.='suppliers';
			} elsif($q->param('type') eq 'shipments') {
				$function.='shipments';
			} elsif($q->param('type') eq 'inventory') {
				$function.='inventory';
			} else {
				goah::Modules->AddMessage('error',__("Unknown parameter for function: ")."'".$q->param('type')."'",__FILE__,__LINE__);
				$action = '-1';
			}
		}

		if($action eq 'storages') {
			$variables{'function'} = $function.'storages';
		} elsif($action eq 'suppliers') {
			$variables{'function'} = $function.'suppliers';
		} elsif($action eq 'shipments') {
			$variables{'function'} = $function.'shipments';
		} elsif($action eq 'inventory') {
			$variables{'function'} = $function.'inventory';
		} elsif($action eq 'addnew') {
			$variables{'function'} = $function.'.new';
		} elsif($action eq 'writenew') {

			if(WriteNewItem() == 0) {
				goah::Modules->AddMessage('info',__("New item added to database"),__FILE__,__LINE__);
			} else {
				goah::Modules->AddMessage('error',__("Couldn't add new item into database"),__FILE__,__LINE__);
			}
			$variables{'function'} = $function;

		} elsif($action eq 'writeedited') {

			if(WriteEditedItem() == 0) {
				goah::Modules->AddMessage('info',__("Information updated"),__FILE__,__LINE__);
			} else {
				goah::Modules->AddMessage('error',__("Can't update database item"),__FILE__,__LINE__);
			}
			$variables{'function'} = $function;

		} elsif($action eq 'edit') {

			$variables{'data'} = ReadData($q->param('type'),$q->param('id'));
			$variables{'function'} = $function.'.edit';

		} elsif($action eq 'delete') {

			if(DeleteItem($q->param('type'),$q->param('id')) == 0) {
				goah::Modules->AddMessage('info',__("Information removed from database"),__FILE__,__LINE__);
			} else {
				goah::Modules->AddMessage('error',__("Can't remove database item"),__FILE__,__LINE__);
			}
			$variables{'function'} = $function;

		} elsif($action eq 'showshipment') {

			$variables{'function'} = $function.'shipments.show';
			$variables{'shipment'} = ReadShipments($q->param('target'));
			$variables{'productgroups'} = sub { goah::Modules::Productmanagement::ReadData('productgroups') };
			$variables{'shipmentrows'} = ReadShipmentrows($q->param('target'));

		} elsif($action eq 'addtoshipment') {

			my $returnvalue;
			if($q->param('subaction') eq 'ean') {
				goah::Modules->AddMessage('debug',"Add to shipment via EAN",__FILE__,__LINE__);
				$returnvalue = AddToShipment($q->param('barcode'),$q->param('subaction'));
			} elsif($q->param('subaction') eq 'productcode') {
				goah::Modules->AddMessage('debug',"Add to shipment via product code",__FILE__,__LINE__);
				$returnvalue = AddToShipment($q->param('code'),$q->param('subaction'));
			} else {
				$returnvalue = AddToShipment();
			}

			if($returnvalue == 0) {
				goah::Modules->AddMessage('info',__("Product(s) added to shipment"),__FILE__,__LINE__);
			} else {
				goah::Modules->AddMessage('error',__("Cant' add product(s) to shipment!"),__FILE__,__LINE__);
			}
			$variables{'function'} = $function.'shipments.show';
			$variables{'shipment'} = ReadShipments($q->param('shipmentid'));
			$variables{'productgroups'} = sub { goah::Modules::Productmanagement::ReadData('productgroups') };
			$variables{'shipmentrows'} = ReadShipmentrows($q->param('shipmentid'));

		} elsif($action eq 'addtoinventory') {

			my $returnvalue;

			if($q->param('subaction') eq 'ean') {
				$returnvalue = AddToInventory($q->param('barcode'));
			} else {
				$returnvalue = AddToInventory();
			}

			if($returnvalue == 0) {
				goah::Modules->AddMessage('info',__("Product(s) added to inventory"),__FILE__,__LINE__);
			} else {
				goah::Modules->AddMessage('error',__("Cant' add product(s) to inventory!"),__FILE__,__LINE__);
			}
			$variables{'function'} = $function.'inventory.show';
			$variables{'inventory'} = ReadInventories($q->param('inventoryid'));
			#$variables{'productgroups'} = sub { goah::Modules::Productmanagement::ReadData('productgroups') };
			my $productgroups = goah::Modules::Productmanagement::ReadData('productgroups');
			$variables{'productgroups'} = $productgroups;
			$variables{'inventoryrows'} = ReadInventoryrows($q->param('inventoryid'));
	
		} elsif($action eq 'showinventory') {
			
			$variables{'function'} = $function.'inventory.show';
			$variables{'inventory'} = ReadInventories($q->param('target'));
			$variables{'productgroups'} = sub { goah::Modules::Productmanagement::ReadData('productgroups') };
			$variables{'inventoryrows'} = ReadInventoryrows($q->param('target'));

		} elsif($action eq 'editrow') {

			if(UpdateShipmentRow() == 0) {
				goah::Modules->AddMessage('info',__("Shipment row updated"),__FILE__,__LINE__);
			} else {
				goah::Modules->AddMessage('error',__("Can't update shipment row"),__FILE__,__LINE__);
			}
			$variables{'function'} = $function.'shipments.show';
			$variables{'shipment'} = ReadShipments($q->param('target'));
			$variables{'productgroups'} = sub { goah::Modules::Productmanagement::ReadData('productgroups') };
			$variables{'shipmentrows'} = ReadShipmentrows($q->param('target'));

		} elsif($action eq 'editrow.inventory') {

			if(UpdateInventoryRow() == 0) {
				goah::Modules->AddMessage('info',__("Inventory row updated"),__FILE__,__LINE__);
			} else {
				goah::Modules->AddMessage('error',__("Can't update inventory row"),__FILE__,__LINE__);
			}
			$variables{'function'} = $function.'inventory.show';
			$variables{'inventory'} = ReadInventories($q->param('target'));
			$variables{'productgroups'} = sub { goah::Modules::Productmanagement::ReadData('productgroups') };
			$variables{'inventoryrows'} = ReadInventoryrows($q->param('target'));
		
		} elsif($action eq 'showgroup') {

			$variables{'function'} = 'modules/Storagemanagement/showgroup';
			$variables{'products'} = goah::Modules::Productmanagement::ReadProductsByGroup($q->param('groupid'),$uid);
			$variables{'productinfo'} = sub { goah::Modules::Productmanagement::ReadData('products',$_[0],$uid) };
			$variables{'data'} = ReadShipments($q->param('target'));
			$variables{'productgroups'} = sub { goah::Modules::Productmanagement::ReadData('productgroups') };

		} elsif($action eq 'showgroup.inventory') {

			$variables{'function'} = 'modules/Storagemanagement/showgroup.inventory';
			$variables{'products'} = goah::Modules::Productmanagement::ReadProductsByGroup($q->param('groupid'),$uid);
			$variables{'productinfo'} = sub { goah::Modules::Productmanagement::ReadData('products',$_[0],$uid) };
			$variables{'data'} = ReadInventories($q->param('target'));
			$variables{'productgroups'} = sub { goah::Modules::Productmanagement::ReadData('productgroups') };

		} else {
			goah::Modules->AddMessage('error',__("Module doesn't have function ")."'".$q->param('action')."'.",__FILE__,__LINE__);
			$variables{'function'} = 'modules/blank';
		}
	} 

	$variables{'storages'} = ReadData('storages');
	$variables{'suppliers'} = ReadData('suppliers');
	my @show=$q->param('showreceived');
	$variables{'shipments'} = ReadShipments('',$show[0]);
	$variables{'showreceived'} = $show[0];
	$variables{'inventories'} = ReadInventories();
	$variables{'productinfo'} = sub { goah::Modules::Productmanagement::ReadData('products',$_[0],$uid) };

	return \%variables;
}

#
# Function: WriteNewItem
#
#    Write new item to database. Item can be storage or supplier.
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
	if ($q->param('type') eq 'storages') {
		use goah::Database::Storages;
		$db = new goah::Database::Storages;
		%dbschema = %storagedbfields;
	} elsif ($q->param('type') eq 'suppliers') {
		use goah::Database::Suppliers;
		$db = new goah::Database::Suppliers;
		%dbschema = %supplierdbfields;
	} elsif ($q->param('type') eq 'shipments') {
		use goah::Database::Incomingshipments;
		$db = new goah::Database::Incomingshipments;
		%dbschema = %shipmentdbfields;
	} elsif ($q->param('type') eq 'inventory') {
		use goah::Database::Inventories;
		$db = new goah::Database::Inventories;
		%dbschema = %inventorydbfields;
	} else {
		goah::Modules->AddMessage('error',__("Unknow type for writing new data into database"),__FILE__,__LINE__);
		return 1;
	}

	my %data;
	my %fieldinfo;
	while(my($key,$value) = each (%dbschema)) {
		%fieldinfo = %$value;
		if($fieldinfo{'required'} == '1' && (!($q->param($fieldinfo{'field'})) || ($fieldinfo{'type'} eq 'selectbox' && $q->param($fieldinfo{'field'})==-1) ) ) {
			goah::Modules->AddMessage('warn',__('Required field').' <b>'.$fieldinfo{'name'}.'</b> '.__('empty!'));
			return 1;
		}

		if($fieldinfo{'type'} eq 'checkbox') {

			if($q->param($fieldinfo{'field'}) eq 'on') {
				# If we are dealing with default value reset default setting 
				# for everything. This is currently valid only for storages
				if($q->param('type') eq 'storages') {
					# Remote storage can't be default
					unless($q->param('remote') eq 'on') {
						my @items = $db->retrieve_all();
						foreach my $item (@items) {
							$item->def(0);
							$item->update;
							$item->commit;
						}
					}
				}

				unless($q->param('remote') eq 'on' ) {
					$data{$fieldinfo{'field'}}=1;
				} else {
					goah::Modules->AddMessage('warn',__("Remote storage can't be default!"),__FILE__,__LINE__);
					$data{$fieldinfo{'field'}}=0;
				}
			} else {
				$data{$fieldinfo{'field'}}=0;
			}
		} else {
			if($q->param($fieldinfo{'field'})) {
				$data{$fieldinfo{'field'}} = decode("utf-8",$q->param($fieldinfo{'field'}));
			}
		}
	}

	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	my $ts = sprintf("%04d-%02d-%02d %02d:%02d:%02d",$year+1900,$mon+1,$mday,$hour,$min,$sec);
	# Add 'created' and default values for shipment
	if($q->param('type') eq 'shipments') {
		$data{'received'} = 0;
		$data{'created'} = $ts;
		$data{'updated'} = $ts;
	}

	# Add 'created' and default values for inventory
	if($q->param('type') eq 'inventory') {
		$data{'done'}=0;
		$data{'created'}=$ts;
	}


	$db->insert(\%data);
	return 0;

}

#
# Function: WriteEditedItem
#  
#   Write updated item back into the database. Item can be
#   storage or supplier.
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

	if ($q->param('type') eq 'storages') {
		use goah::Database::Storages;
		$db = new goah::Database::Storages;
		%dbschema = %storagedbfields;
	} elsif ($q->param('type') eq 'suppliers') {
		use goah::Database::Suppliers;
		$db = new goah::Database::Suppliers;
		%dbschema = %supplierdbfields;
	} elsif ($q->param('type') eq 'shipments') {
		use goah::Database::Incomingshipments;
		$db = new goah::Database::Incomingshipments;
		%dbschema = %shipmentdbfields;
	} elsif ($q->param('type') eq 'inventory') {
		use goah::Database::Inventories;
		$db = new goah::Database::Inventories;
		%dbschema = %inventorydbfields;
	} else {
		# Unknown type
		return 1;
	}

	my $data = $db->retrieve($q->param('id'));
	my %fieldinfo;
	while(my($key,$value) = each (%dbschema)) {
		%fieldinfo = %$value;
		if($fieldinfo{'required'} == '1' && !($q->param($fieldinfo{'field'})) ) {
			# Using variable just to make source look nicer
			my $errstr = __('Required field').' <b>'.$fieldinfo{'name'}.'</b> '.__('empty!')." ";
			$errstr.= __("Leaving value unaltered.");
			 goah::Modules->AddMessage('warn',$errstr);
		} else {
			if($fieldinfo{'type'} eq 'checkbox') {
				if($q->param($fieldinfo{'field'}) eq 'on') {
					# If we are dealing with default value reset default setting
					# for everything. This is currently valid only for storages
					if($q->param('type') eq 'storages') {
						# Remote storage can't be default
						unless($q->param('remote') eq 'on') {
							my @items = $db->retrieve_all();
							foreach my $item (@items) {
								$item->def(0);
								$item->update;
								$item->commit;
							}
						}
					}

					unless($q->param('remote') eq 'on') {
						$data->set($fieldinfo{'field'} => 1);
					} else {
						goah::Modules->AddMessage('warn',__("Remote storage can't be default!"),__FILE__,__LINE__);
						$data->set($fieldinfo{'field'} => 0);
					}
				} else {
					$data->set($fieldinfo{'field'} => 0);
				}
			} else {
				if($q->param($fieldinfo{'field'})) {
					$data->set($fieldinfo{'field'} => decode('utf-8',$q->param($fieldinfo{'field'})));
				}
			}
		}
	}


	# If we're updating inventory information check if the inventory is done and if we need
	# to update storage amounts
	if($q->param('type') eq 'inventory' && $q->param('done') && $q->param('done') eq 'on') {

		$data->set(done => 1);
		my $rowpointer = ReadInventoryrows($q->param('id'));
		my %rows = %$rowpointer;
		my %row;
		use goah::Database::Products;
		my $product;
		foreach my $key (keys %rows) {

			$product = goah::Database::Products->retrieve($rows{$key}{'productid'});
			$product->set(in_store => $rows{$key}{'amount_after'});

			# Don't let storage value below 0
			if($product->in_store < 0) {
				$product->in_store(0);
			}

			$product->update();
			
			goah::Modules->AddMessage('debug',"Changed amount for product ".$product->name." to ".$product->in_store);
		}

	}

	# If we're updating shipment information change last modified data as well
	if($q->param('type') eq 'shipments') {
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
		$data->set('updated' =>sprintf("%04d-%02d-%02d %02d:%02d:%02d",$year+1900,$mon+1,$mday,$hour,$min,$sec));

		# Check if shipment is tagged as received. If so then we need to update
		# products storage values as well.	
		if($q->param('received') && $q->param('received') eq 'on') {
			
			my $rows = ReadShipmentrows($data->id);
			if($rows == 0) {
				# We didn't get any rows for the shipment. We don't allow
				# empty shipments to be stored, so just notify user and 
				# do nothing.
				goah::Modules->AddMessage('warn',__("Shipment is empty. Empty shipments can not be stored to database"),__FILE__,__LINE__);
				
				# Update changed data and end function
				$data->update;
				return 0;
			}
			
			#
			# FIXME:
			# Here we'll use direct connection to database since there's no 
			# suitable function to manage simple process for in_storage -
			# field update.
			# 	- Take, 210709
			#
			use goah::Database::Products;

			my %prods = %$rows;
			my $prod;
			my %prow;
			my $hashtmp; # This seems to be an required step, even if I don't think so
			foreach my $key (keys %prods) {
				$hashtmp = $prods{$key};
				%prow = %$hashtmp;

				$prod = goah::Database::Products->retrieve($prow{'productid'});
				unless($prod->id == $prow{'productid'}) {
					my $msg = __("Can't find product from the database. Can't close incoming shipment.");
					$msg.= " ".__("Invalid product id: ").$prow{'productid'};
					goah::Modules->AddMessage('error',$msg,__FILE__,__LINE__); 
					$data->update;
					return 1;
				}
				
				goah::Modules->AddMessage('debug',"Updating value for product ".$prod->name.". Current amount is ".$prod->in_store,__FILE__,__LINE__); 

				$prod->in_store($prod->in_store+$prow{'amount'});
				# Don't let storage value below zero
				if($prod->in_store < 0) {
					$prod->in_store(0);
				}
				$prod->update;
				goah::Modules->AddMessage('debug',"Product ".$prod->name." has now ".$prod->in_store." items in storage.",__FILE__,__LINE__); 
			}

			$data->set('received' => '1');
		} 
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
#    item - Item(s) to retrieve. storages|suppliers
#    id - Spesific id from the database so we can retrieve individual items
#    search parameters - Optional search parameters
#
# Returns:
#
#    Fail - 0
#    Success - Pointer to Class::DBI result set
#
sub ReadData {

	if($_[0]=~/goah::Modules::Storagemanagement$/) {
		shift;
	}

	my $db;
	my $sort = 'name';
	if ($_[0] eq 'storages') {
		use goah::Database::Storages;
		$db = new goah::Database::Storages;
	} elsif ($_[0] eq 'suppliers') {
		use goah::Database::Suppliers;
		$db = new goah::Database::Suppliers;
	} elsif ($_[0] eq 'shipments') {
		use goah::Database::Incomingshipments;
		$db = new goah::Database::Incomingshipments;
		$sort = 'updated';
	} elsif ($_[0] eq 'inventories') {
		use goah::Database::Inventories;
		$db = new goah::Database::Inventories;
		$sort='created';
	} else {
		# Unknown type
		goah::Modules->AddMessage('debug', "Invalid DB identifier ".$_[0]."!",__FILE__,__LINE__);
		return 0;
	}

	my @data;
	my %pdata;
	my $i=0;
	my $field;
	if(!($_[1]) || $_[1] eq '') {
		if($_[0] eq 'shipments') {
			unless($_[2]=~/on/i) {
				@data = $db->search_where({ received => "0" },{order_by => $sort });
			} else {
				@data = $db->retrieve_all_sorted_by($sort);
			}
		} else {
			@data = $db->retrieve_all_sorted_by($sort);
		}
		return \@data;
	} else {
		@data = $db->retrieve($_[1]);
		if(scalar(@data) == 0) {
			return 0;
		}

		return $data[0];
	}	

	return 0;
}

#
# Function: ReadShipments
#
#   An wrapper function to read all data for individual shipment
#   and pack it into hash -array.
#
# Parameters: 
#
#   id - Retrieve only single item, if omitted read all shipments
#   search - Optional search parameters
#
# Returns:
#
#   Fail - 0 
#   Success - Hash reference
#
# About: ToDo
#
#   This function is a bit silly and it's repeating itself functionality
#   but since I haven't really had any sleep recently I'll leave it like
#   this and (let someone else ;) fix it later
#
sub ReadShipments {

	use goah::GoaH;
	my %data;
	my $i=0;
	my $tmp;
	my $field;
	my $row;
	my $key;
	
	# Read only single item
	if($_[0]) {

		$row = ReadData('shipments',$_[0]);
		if($row == 0) {
			goah::Modules->AddMessage('error',__("Can't find shipment with id")." ".$_[0],__FILE__,__LINE__);
			return 0;
		}

		foreach $key (keys %shipmentdbfields) {
			$field = $shipmentdbfields{$key}{'field'};

			if($field eq 'supplierid') {

				$tmp = ReadData('suppliers',$row->get($field));
				if($tmp == 0) {
					my $str = __("Can't find supplier information with id")." ".$row->get($field).".";
					$str.=__("Terminating process.");
					goah::Modules->AddMessage('error',$str,__FILE__,__LINE__);
					return 0;
				}
				$data{'supplier'}{'id'} = $tmp->id;
				$data{'supplier'}{'name'} = $tmp->name;

			} elsif ($field eq 'destination') {

				$tmp = ReadData('storages',$row->get($field));
				if($tmp == 0) {
					my $str = __("Can't find storage information with id")." ".$row->get($field).".";
					$str.=__("Terminating process.");
					goah::Modules->AddMessage('error',$str,__FILE__,__LINE__);
					return 0;
				}

				$data{'storage'}{'id'} = $tmp->id;
				$data{'storage'}{'name'} = $tmp->name;
			} elsif ($field eq 'created' || $field eq 'due' || $field eq 'updated') {
				
				unless($row->get($field) eq '') {
					$data{$field} = goah::GoaH->FormatDate($row->get($field));
				}

			} else {

				$data{$field} = $row->get($field);

			}
		 }

	} else { # Read all shipments

		$tmp = ReadData('shipments','',$_[1]);
		unless($tmp) {
			goah::Modules->AddMessage('error',__("Couldn't read shipments from database!"),__FILE__,__LINE__);
			return 0;
		}
		my @shipments = @$tmp;
		my $ii=0;
		foreach $row (@shipments) {
			
			$i=goah::GoaH->FormatDate($row->updated,'unix');
			$i.='.'.$ii;
			$ii++;

			foreach $key (keys %shipmentdbfields) {

				$field = $shipmentdbfields{$key}{'field'};

				# Retrieve information about supplier and storage separately
				# into the hash
				if($field eq 'supplierid') {
					$tmp = ReadData('suppliers',$row->get($field));
					if($tmp == 0) {
						my $str = __("Can't find supplier information with id")." ".$row->get($field).".";
						$str.=__("Terminating process.");
						goah::Modules->AddMessage('error',$str,__FILE__,__LINE__);
						return 0;
					 }
					$data{$i}{'supplier'}{'id'} = $tmp->id;
					$data{$i}{'supplier'}{'name'} = $tmp->name;
				} elsif ($field eq 'destination') {
					
					$tmp = ReadData('storages',$row->get($field));
					if($tmp == 0) {
						my $str = __("Can't find storage information with id")." ".$row->get($field).".";
						$str.=__("Terminating process.");
						goah::Modules->AddMessage('error',$str,__FILE__,__LINE__);
						return 0;
					}

					$data{$i}{'storage'}{'id'} = $tmp->id;
					$data{$i}{'storage'}{'name'} = $tmp->name;
				} elsif ($field eq 'created' || $field eq 'due' || $field eq 'updated') {
					unless($row->get($field) eq '') {
						$data{$i}{$field} = goah::GoaH->FormatDate($row->get($field));
					}
				} else {
					$data{$i}{$field} = $row->get($field);
				}
			}
		}
	}

	return \%data;
}

#
# Function: ReadInventories
#
#   An wrapper function to read all data for individual inventory
#   and pack it into hash -array.
#
# Parameters: 
#
#   id - Retrieve only single item, if omitted read all inventories
#
# Returns:
#
#   Fail - 0 
#   Success - Hash reference
#
# About: ToDo
#
#   This function is a bit silly and it's repeating itself functionality
#   but since I haven't really had any sleep recently I'll leave it like
#   this and (let someone else ;) fix it later
#
sub ReadInventories {

	use goah::GoaH;
	my %data;
	my $i=0;
	my $tmp;
	my $field;
	my $row;
	my $key;
	
	# Read only single item
	if($_[0]) {

		$row = ReadData('inventories',$_[0]);
		if($row == 0) {
			goah::Modules->AddMessage('error',__("Can't find inventory with id")." ".$_[0],__FILE__,__LINE__);
			return 0;
		}

		foreach $key (keys %inventorydbfields) {
			$field = $inventorydbfields{$key}{'field'};

			if ($field eq 'created' ) {
				
				unless($row->get($field) eq '') {
					$data{$field} = goah::GoaH->FormatDate($row->get($field));
				}

			} else {

				$data{$field} = $row->get($field);

			}
		 }

	} else { # Read all inventories

		$tmp = ReadData('inventories');
		if($tmp==0) {
			return 0;
		}
		my @inventories = @$tmp;
		foreach $row (@inventories) {
			
			foreach $key (keys %inventorydbfields) {

				$field = $inventorydbfields{$key}{'field'};

				if ($field eq 'created' || $field eq 'due' || $field eq 'updated') {
					unless($row->get($field) eq '') {
						$data{$i}{$field} = goah::GoaH->FormatDate($row->get($field));
					}
				} else {
					$data{$i}{$field} = $row->get($field);
				}
			}
			$i++;
		}
	}

	return \%data;
}


#
# Function: DeleteItem
#
#   Delete item from database. This is an actual delete, not hide used
#   with product information etc.
#
# Parameters:
#
#   db - Database identifier, may be storages or suppliers
#   id - Actual id from the table to be removed
#
# Returns:
#
#   Fail - 1
#   Success - 0 
#
sub DeleteItem {
	
	unless($_[1]) {
		goah::Modules->AddMessage('error',__("Missing ID, can't remove data from database"),__FILE__,__LINE__);
		return 1;
	}

	unless($_[0]) {
		goah::Modules->AddMessage('error',__("Missing type, can't remove data from database"),__FILE__,__LINE__);
		return 1;
	}

        my $db;
        if ($_[0] eq 'storages') {
		use goah::Database::Storages;
		$db = new goah::Database::Storages;
        } elsif ($_[0] eq 'suppliers') {
		use goah::Database::Suppliers;
		$db = new goah::Database::Suppliers;
	} elsif ($_[0] eq 'shipments') {
		# Prevent removal if there is any rows on the shipment.
		my $srows = ReadShipmentrows($_[1]);
		unless($srows==0) {
			goah::Modules->AddMessage('error',__("Rows left on shipment! Refusing to delete shipment!"),__FILE__,__LINE__);
			return 1;
		}
		use goah::Database::Incomingshipments;
		$db = new goah::Database::Incomingshipments;
	} else {
		# Wrong db identifier
		goah::Modules->AddMessage('error',__("Invalid database identifier"),__FILE__,__LINE__); 
		return 0;
	}

	my $data = $db->retrieve($_[1]);
	$data->delete;
	
	return 0;
}

#
# Function: AddToShipment
#
#   Function to handle adding product(s) to shipment. Function
#   understands both addproducts[] -array and productid -string
#   via HTTP variables, so the same function can be used on both,
#   adding individual product or several products at once to 
#   basket.
#
# Parameters:
#
#   None, uses HTTP variables
#
# Returns:
#
#   Success - 0
#   Fail - 1
#
sub AddToShipment {

	my %data;
	my %fieldinfo;

	my $q = CGI->new();
	use goah::Modules::Productmanagement;

	# Addproducts is an array which we need to loop trough
	my $shipmentid;
	if($q->param('shipmentid')) {
		$shipmentid = $q->param('shipmentid');
	} else {
		goah::Modules->AddMessage('error',__("Can't add product(s) to shipment. Shipment id is missing."));
		return 1;
	}
	my $purchase;
	my $amount;

	# Loop trough an array of products
	if($q->param('addproducts')) {

		my @products = $q->param('addproducts');
		foreach my $prod (@products) {

			$purchase = $q->param('purchase_'.$prod);
			$amount = $q->param('amount_'.$prod);

			if(AddProductToShipment($prod,$shipmentid,$purchase,$amount)==1) {
				goah::Modules->AddMessage('debug',"Added productid $prod to shipment with amount $amount",__FILE__,__LINE__);
			} else {
				goah::Modules->AddMessage('error',"Can't add product id $prod to shipment!",__FILE__,__LINE__);
			}
		}

	} elsif ($q->param('productid') || $_[0]) {
		# Add only one product

		my $prod;
		# If we have an EAN-code, or Product code, then read product information via that
		if($_[0]) {
			if($_[1] eq "ean") {
				goah::Modules->AddMessage('debug',"Adding product to shipmet via barcode".$_[0],__FILE__,__LINE__);
				$prod = goah::Modules::Productmanagement->ReadProductByEAN($_[0]);
			}
			if($_[1] eq "productcode") {
				goah::Modules->AddMessage('debug',"Adding product to shipment via product code ".$_[0],__FILE__,__LINE__);
				$prod = goah::Modules::Productmanagement->ReadProductByCode($_[0]);
			}
			if($prod==0) {
				goah::Modules->AddMessage('error',__("Product not found"),__FILE__,__LINE__);
				return 1;
			}
			$amount=1;
			my $proddataptr = goah::Modules::Productmanagement->ReadData('products',$prod,$uid);
			if($proddataptr == 0) {
				goah::Modules->AddMessage('error',"Something went badly wrong...",__FILE__,__LINE__);
			}
			my %proddata = %$proddataptr;
			$purchase = $proddata{'purchase'};
		} else {
			$prod = $q->param('productid');
			$purchase = $q->param('purchase');
			$amount = $q->param('amount');
		}

		if(AddProductToShipment($prod,$shipmentid,$purchase,$amount)==1) {
			goah::Modules->AddMessage('debug',"Added productid $prod to shipment",__FILE__,__LINE__);
		} else {
			goah::Modules->AddMessage('error',"Can't add product id $prod to shipment!",__FILE__,__LINE__);
		}

	} else {

		goah::Modules->AddMessage('error',__("Can't add product to shipment. Nothing to add!"),__FILE__,__LINE__);
		return 1;
	}

	#
	# Last, update last modified information for the shipment
	#
	use goah::Database::Incomingshipments;
	my $bdata = goah::Database::Incomingshipments->retrieve($q->param('shipmentid'));
	unless($bdata) {
		goah::Modules->AddMessage('debug',"Can't update shipment, nothing found with ".$q->param('shipmentid'),__FILE__,__LINE__);
		return 1;
	}
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$bdata->set('updated' =>sprintf("%04d-%02d-%02d %02d:%02d:%02d",$year+1900,$mon+1,$mday,$hour,$min,$sec));
	$bdata->update();
	$bdata->commit;
	return 0;

}

#
# Function: AddToInventory
#
#   Function to handle adding product(s) to inventory. Function
#   understands both addproducts[] -array and productid -string
#   via HTTP variables, so the same function can be used on both,
#   adding individual product or several products at once to 
#   inventory.
#
# Parameters:
#
#   barcode - Optional, but if set try to search product via barcode instead of using product id
#
# Returns:
#
#   Success - 0
#   Fail - 1
#
sub AddToInventory {

	if($_[0]=~/Storagemanagement/) {
		shift;
	}

	my %data;
	my %fieldinfo;

	my $q = CGI->new();
	use goah::Modules::Productmanagement;

	# Addproducts is an array which we need to loop trough
	my $inventoryid;
	if($q->param('inventoryid')) {
		$inventoryid = $q->param('inventoryid');
	} else {
		goah::Modules->AddMessage('error',__("Can't add product(s) to inventory. Inventory id is missing."));
		return 1;
	}
	my $amount_after;

	# Loop trough an array of products
	if($q->param('addproducts')) {

		my @products = $q->param('addproducts');
		foreach my $prod (@products) {

			$amount_after = $q->param('amount_'.$prod);

			if(AddProductToInventory($prod,$inventoryid,$amount_after)==1) {
				goah::Modules->AddMessage('debug',"Added productid $prod to inventory",__FILE__,__LINE__);
			} else {
				goah::Modules->AddMessage('error',"Can't add product id $prod to inventory!",__FILE__,__LINE__);
			}
		}

	} elsif ($q->param('productid') || $_[0] || $q->param('code') ) {
		# Add only one product
		
		my $prod;
		# If we have an EAN -code read product information via that
		if($_[0]) {
			goah::Modules->AddMessage('debug',"Adding product via barcode ".$_[0],__FILE__,__LINE__);
			$prod = goah::Modules::Productmanagement->ReadProductByEAN($_[0]);
			if($prod==0) {
				goah::Modules->AddMessage('error',__("Product not found"),__FILE__,__LINE__);
				return 0;
			}
		} elsif ($q->param('code')) {

			$prod = goah::Modules::Productmanagement->ReadProductByCode($q->param('code'));
			unless($prod) {
				goah::Modules->AddMessage('error',__("Didn't find product code. Can't add product to inventory.")." Code:".$q->param('code'));
			} 

		} else {
			$prod = $q->param('productid');
		}
		unless($q->param('amount')) {
			$amount_after="+1";
		} else {
			$amount_after = $q->param('amount');
		}

		if(AddProductToInventory($prod,$inventoryid,$amount_after)==1) {
			goah::Modules->AddMessage('debug',"Added productid $prod to inventory",__FILE__,__LINE__);
		} else {
			goah::Modules->AddMessage('error',"Can't add product id $prod to inventory!",__FILE__,__LINE__);
		}

	} else {

		goah::Modules->AddMessage('error',__("Can't add product to inventory. Nothing to add!"),__FILE__,__LINE__);
		return 1;
	}

	return 0;

}

#
# Function: AddProductToShipment
#
#   Basically an helper function to assist adding products to shipment.
#   This function should be called only from AddToShipment -function
#   and it's only purpose is to make loops siplier.
#
# Parameters:
#
#   id - Product id to be added
#   basketid - Shipment id where product is added
#   purchase - Purchase price
#   amount - Row amount 
#   rowinfo - Additional information for the row
#
sub AddProductToShipment {

	unless($_[0]) {
		goah::Modules->AddMessage('error',__("Can't add individual product to shipment. Product ID is missing."),__FILE__,__LINE__);
		return 0;
	}

	goah::Modules->AddMessage('debug',"Fetch product info with uid ".$uid,__FILE__,__LINE__);
	my $pinfo = goah::Modules::Productmanagement->ReadData('products', $_[0], $uid);
	if($pinfo == 0) {
		goah::Modules->AddMessage('error', __("Invalid product id. Can't add product to shipment.")." (".$_[0].")",__FILE__,__LINE__);
		return 1;
	}
	my %prod = %$pinfo;

	my %data;

	$data{'productid'} = $_[0];
	$data{'shipmentid'} = $_[1];

	$data{'purchase'} = goah::GoaH->FormatCurrency($_[2],$prod{'vat'},$uid,'in',$settref);
	$data{'amount'} = decode("utf-8",$_[3]);
	$data{'rowinfo'} = decode("utf-8",$_[4]);

	use goah::Database::Incomingshipmentrows;
	goah::Database::Incomingshipmentrows->insert(\%data);

	return 1;
}

#
# Function: AddProductToInventory
#
#   Basically an helper function to assist adding products to inventory.
#   This function should be called only from AddToInventory -function
#   and it's only purpose is to make loops siplier.
#
# Parameters:
#
#   id - Product id to be added
#   inventoryid - Inventory id where product is added
#   amount - Row amount after inventory
#   rowinfo - Additional information for the row
#
# About:
# 	
#   Todo: Merge this function with AddProductToShipment
#
sub AddProductToInventory {

	unless($_[0]) {
		goah::Modules->AddMessage('error',__("Can't add individual product to inventory. Product ID is missing."),__FILE__,__LINE__);
		return 0;
	}

	goah::Modules->AddMessage('debug',"Fetch product info with uid ".$uid,__FILE__,__LINE__);
	my $pinfo = goah::Modules::Productmanagement->ReadData('products', $_[0], $uid);
	if($pinfo == 0) {
		goah::Modules->AddMessage('error', __("Invalid product id. Can't add product to inventory.")." (".$_[0].")",__FILE__,__LINE__);
		return 1;
	}
	my %prod = %$pinfo;

	my %data;

	$data{'productid'} = $_[0];
	$data{'inventoryid'} = $_[1];

	$data{'amount_before'} = $prod{'in_store'};
	$data{'rowinfo'} = decode("utf-8",$_[3]);

	use goah::Database::Inventoryrows;

	# Check if inventory already contains the product we're adding so that single product is
	# only once on each inventory
	my @inventorydata = goah::Database::Inventoryrows->search_where(inventoryid => $data{'inventoryid'}, productid=>$data{'productid'});
	goah::Modules->AddMessage('debug',"Got ".scalar(@inventorydata)." rows for product & inventoryid ".$data{'inventoryid'}."/".$data{'productid'},__FILE__,__LINE__);
	if(scalar(@inventorydata)>0) {
	
		my $row=$inventorydata[0];
		if($_[2]=~/^[+-]/) {
			$_[2]=~/^(.)([0-9])+/;
			my $amt = $2;
			if($1 eq '+') {
				$row->amount_after($row->amount_after+$amt);
			} elsif($1 eq '-') {
				$row->amount_after($row->amount_after-$amt);
			} else {
				goah::Modules->AddMessage('warn',__("Invalid number in amount after field: ").$_[2],__FILE__,__LINE__);
			}
		} else {
			$row->amount_after(decode("utf-8",$_[2]));
		}
		$row->update();
		$row->commit();
	} else {
		if($_[2]=~/^[+-]/) {
			$_[2]=~s/^.//;
			$data{'amount_after'}=$_[2];
		} else {
			$data{'amount_after'}=$_[2];
		}
		# Add new row
		goah::Database::Inventoryrows->insert(\%data);
		goah::Database::Inventoryrows->commit();
	}

	return 1;
}


#
# Function: ReadShipmentrows
#
#   Read indivirual rows for shipment. Prices are formatted (w or w/o VAT) based on
#   user settings.
#
# Parameters:
#
#   shipmentid - Shipment id from the database
#   rowid - If set read individual row from the database. If omitted read whole shipment..
#
# Returns:
#
#   Success - Hash reference to row data.
#   Fail - 0 
#
sub ReadShipmentrows {

	if($_[0]=~/goah::Modules::Storagemanagement/) {
		shift;
	}

	unless($_[0] || $_[1]) {
		goah::Modules->AddMessage('error',__("Can't read rows for shipment! Shipment id is missing!"),__FILE__,__LINE__);
		return 0;
	}

	use goah::Database::Incomingshipmentrows;
	my %rowdata;
	my $field;
	my $shipmenttotal=0;
	my $rowtotal=0;

	unless($_[1]) {
		# We don't have id for individual row, read all rows for
		# the shipment
		my @data = goah::Database::Incomingshipmentrows->search_where({shipmentid => $_[0]}, { order_by => 'id' });
		if(scalar(@data)==0) {
			return 0;
		}
		my $i=-1;
		foreach my $row (@data) {

			$i++;

			foreach my $key (keys %shipmentrowdbfields) {
				$field = $shipmentrowdbfields{$key}{'field'};
				if($field eq 'purchase') {
					my $prodpoint = goah::Modules::Productmanagement::ReadData('products',$row->productid,$uid);
					my %prod = %$prodpoint;
					$rowdata{$i}{$field} = goah::GoaH->FormatCurrency($row->get($field),$prod{'vat'},$uid,'out',$settref);
				} else {
					$rowdata{$i}{$field} = $row->get($field);
				}
			}

			unless($rowdata{$i}{'amount'}) {
				$rowdata{$i}{'amount'}=0;
			}

			$rowdata{$i}{'total'} = goah::GoaH->FormatCurrency( ($rowdata{$i}{'purchase'}*$rowdata{$i}{'amount'}),0,$uid,'out',$settref);
			$shipmenttotal+=($rowdata{$i}{'purchase'}*$rowdata{$i}{'amount'});
		}

		$rowdata{$i}{'shipmenttotal'} = goah::GoaH->FormatCurrency($shipmenttotal,0,$uid,'out',$settref);
		return \%rowdata;
	} else {

		# Row id is set, read only single row from the database
		my $data = goah::Database::Incomingshipmentrows->retrieve($_[1]);

		foreach my $key (keys %shipmentrowdbfields) {
			$field = $shipmentrowdbfields{$key}{'field'};

			if($field eq 'purchase') {
				my $prodpoint = goah::Modules::Productmanagement::ReadData('products',$data->productid,$uid);
				my %prod = %$prodpoint;
				$rowdata{$field} = goah::GoaH->FormatCurrency($data->get($field),$prod{'vat'},$uid,'out',$settref);
			} else {
				$rowdata{$field} = $data->get($field);
			}
		}
		$rowdata{'total'} = goah::GoaH->FormatCurrency( ($rowdata{'sell'}*$rowdata{'amount'}),0,$uid,'out',$settref);
		return \%rowdata;
	}
	return 0;
}

#
# Function: ReadInventoryrows
#
#   Read indivirual rows for inventory. 
#
# Parameters:
#
#   inventoryid - Inventory id from the database
#   rowid - If set read individual row from the database. If omitted read whole inventory..
#
# Returns:
#
#   Success - Hash reference to row data.
#   Fail - 0 
#
sub ReadInventoryrows {

	if($_[0]=~/goah::Modules::Storagemanagement/) {
		shift;
	}

	unless($_[0] || $_[1]) {
		goah::Modules->AddMessage('error',__("Can't read rows for inventory! Inventory id is missing!"),__FILE__,__LINE__);
		return 0;
	}

	use goah::Database::Inventoryrows;
	my %rowdata;
	my $field;

	unless($_[1]) {
		# We don't have id for individual row, read all rows for
		# the inventory
		my @data = goah::Database::Inventoryrows->search_where({inventoryid => $_[0]}, { order_by => 'id DESC' });
		my $i=-1;
		foreach my $row (@data) {

			$i = sprintf("%2d",$row->id);
			
			foreach my $key (keys %inventoryrowdbfields) {
				$field = $inventoryrowdbfields{$key}{'field'};
				$rowdata{$i}{$field} = $row->get($field);
			}

			unless($rowdata{$i}{'amount'}) {
				$rowdata{$i}{'amount'}=0;
			}
		}

		return \%rowdata;
	} else {

		# Row id is set, read only single row from the database
		my $data = goah::Database::Inventoryrows->retrieve($_[1]);

		foreach my $key (keys %inventoryrowdbfields) {
			$field = $shipmentrowdbfields{$key}{'field'};
			$rowdata{$field} = $data->get($field);
		}
		return \%rowdata;
	}
	return 0;
}


#
# Function: UpdateShipmentRow
#
#   Update values for individual shipment row. Update obviously
#   doesn't touch into referencing id values, so rows can't
#   be moved or copied to different shipments. However deleting
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
sub UpdateShipmentRow {

	my $q = CGI->new();
	unless($q->param('rowid')) {
		goah::Modules->AddMessage('error',__('ID -field missing.')." ".__("Can't update row information in database!"));
		return 1;
	}

	use goah::Database::Incomingshipmentrows;
	my $rowinfo = goah::Database::Incomingshipmentrows->retrieve($q->param('rowid')-0);

	if($q->param('delete') eq 'on') {
		goah::Modules->AddMessage('info',__("Row deleted from basket"));
		$rowinfo->delete;
		return 0;
	}

	my $prodinfo = goah::Modules::Productmanagement->ReadData('products',$rowinfo->productid,$uid);
	my %prod = %$prodinfo;

	my %fieldinfo;
	while(my($key,$value)= each (%shipmentrowdbfields)) {
		%fieldinfo = %$value;
		if($fieldinfo{'field'} eq 'productid' || $fieldinfo{'field'} eq 'shipmentid' || $fieldinfo{'id'} eq 'id') {
			next;
		}

		if($q->param($fieldinfo{'field'})) {

			if($fieldinfo{'field'} eq 'purchase' || $fieldinfo{'field'} eq 'sell') {
				my $amt = goah::GoaH->FormatCurrency($q->param($fieldinfo{'field'}),$prod{'vat'},$uid,'in',$settref);
				$rowinfo->set($fieldinfo{'field'} => $amt);
				goah::Modules->AddMessage('debug',"Updated ".$fieldinfo{'field'}." to value $amt",__FILE__,__LINE__);
			} else {
				$rowinfo->set($fieldinfo{'field'} => decode("utf-8",$q->param($fieldinfo{'field'})));
			}

		} else {
			#goah::Modules->AddMessage('debug',"Empty value via form for ".$fieldinfo{'field'});
			if($fieldinfo{'field'} eq 'purchase') {
				#goah::Modules->AddMessage('debug',"Default purchase price applied");
				$rowinfo->set('purchase' => $prodinfo->purchase);
			}
		}
	}

	$rowinfo->update();

	#
	# Finally, update last modified information 
	# for the basket
	#   TODO: This functionality could be done as an function, i.e. TouchBasket() since it's
	#         used on various locations.
	use goah::Database::Incomingshipments;
	my $data = goah::Database::Incomingshipments->retrieve($q->param('target'));
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$data->set('updated' =>sprintf("%04d-%02d-%02d %02d:%02d:%02d",$year+1900,$mon+1,$mday,$hour,$min,$sec));
	$data->update();

	return 0;
}


#
# Function: UpdateInventoryRow
#
#   Update values for individual inventory row. Update obviously
#   doesn't touch into referencing id values, so rows can't
#   be moved or copied to different inventories. However deleting
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
sub UpdateInventoryRow {

	my $q = CGI->new();
	unless($q->param('rowid')) {
		goah::Modules->AddMessage('error',__('ID -field missing.')." ".__("Can't update row information in database!"));
		return 1;
	}

	use goah::Database::Inventoryrows;
	my $rowinfo = goah::Database::Inventoryrows->retrieve($q->param('rowid')-0);

	if($q->param('delete') eq 'on') {
		goah::Modules->AddMessage('info',__("Row deleted from inventory"));
		$rowinfo->delete;
		return 0;
	}

	my $prodinfo = goah::Modules::Productmanagement->ReadData('products',$rowinfo->productid,$uid);
	my %prod = %$prodinfo;

	my %fieldinfo;
	while(my($key,$value)= each (%inventoryrowdbfields)) {
		%fieldinfo = %$value;
		if($fieldinfo{'field'} eq 'productid' || $fieldinfo{'field'} eq 'inventoryid' || $fieldinfo{'field'} eq 'id' || $fieldinfo{'field'} eq 'amount_before') {
			next;
		}

		if($q->param($fieldinfo{'field'})) {

			if($fieldinfo{'field'} eq 'amount_after') {
				if($q->param('amount_after')=~/^[+-]/) {
					$q->param('amount_after')=~/^(.)([0-9])+/;
					my $amt = $2;
					if($1 eq '+') {
						$rowinfo->set('amount_after' => $rowinfo->amount_after+$amt);
					} elsif($1 eq '-') {
						$rowinfo->set('amount_after' => $rowinfo->amount_after-$amt);
					} else {
						goah::Modules->AddMessage('warn',__("Invalid number in amount after field: ").$_[2],__FILE__,__LINE__);
					}
				} else {
					$rowinfo->set($fieldinfo{'field'} => decode("utf-8",$q->param($fieldinfo{'field'})));
				}
				goah::Modules->AddMessage('debug',"Changed amount_after to value ".$rowinfo->get('amount_after'),__FILE__,__LINE__);
			} else {	
				$rowinfo->set($fieldinfo{'field'} => decode("utf-8",$q->param($fieldinfo{'field'})));
				goah::Modules->AddMessage('debug',"Changed ".$fieldinfo{'field'}." to value ".$q->param($fieldinfo{'field'}),__FILE__,__LINE__);
			}
		} 
		
	}

	$rowinfo->update();
	$rowinfo->commit();

	return 0;
}


1;
