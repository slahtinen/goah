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

#
# Hash: basketdbfields
#
#   Database field definitions for baskets
#
my %basketdbfields = ( 
		0 => { field => 'id', name => 'id', type => 'hidden', required => '0' },
		1 => { field => 'companyid', name => __('Customer'), type => 'selectbox', required => '1', data => goah::Modules::Customermanagement->ReadAllCompanies() },
		2 => { field => 'locationid', name => __('Shipping address'), type => 'selectbox', required => '1', data => '0' },
		3 => { field => 'billingid', name => __('Billing address') , type => 'selectbox', required => '1', data => '0' },
		4 => { field => 'created', name => 'created', type => 'hidden', required => '0' },
		5 => { field => 'updated', name => 'updated', type => 'hidden', required => '0' },
		6 => { field => 'info', name => __('Description'), type => 'textarea', required => '0' },
		7 => { field => 'ownerid', name => 'ownerid', type => 'hidden', required => '0' }
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
		6 => { field => 'rowinfo', name => __("Row information"), type => 'textbox', required => '0' }
	);

#
# Hash: submenu
#
#   Submenu definition
#
my %submenu = ( 
		0 => { title => __("Stored baskets"), action => 'storedbaskets' }
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

	my $q = CGI->new();
	my %variables;

	$variables{'module'} = 'Basket';
	$variables{'gettext'} = sub { return __($_[0]); };
	$variables{'formatdate'} = sub { goah::GoaH::FormatDate($_[0]); };
	$variables{'basketdbfields'} = \%basketdbfields;
	$variables{'basketrowdbfields'} = \%basketrowdbfields;
	$variables{'submenu'} = \%submenu;
	$variables{'function'} = 'modules/Basket/showbaskets';
	$variables{'activebasket'} = 0;
	$variables{'products'} = sub { goah::Modules::Productmanagement::ReadData('products',,$uid,$settref) };

	use goah::Modules::Personalsettings;
	$variables{'usersettings'} = sub { goah::Modules::Personalsettings::ReadSettings($uid) };

	if($q->param('action')) {

		if($q->param('action') eq 'showbaskets') {

				$variables{'function'} = 'modules/Basket/showbaskets';

		} elsif($q->param('action') eq 'selectbasket') {

				$variables{'function'} = 'modules/Basket/activebasket';
				$variables{'activebasket'} = $q->param('target');
				$variables{'data'} = ReadBaskets($q->param('target'));
				$variables{'basketrows'} = ReadBasketrows($q->param('target'));

		} elsif($q->param('action') eq 'storedbaskets') {

				goah::Modules::AddMessage('info','Feature under construction');
				$variables{'function'} = 'modules/Basket/showbaskets';

		} elsif($q->param('action') eq 'newbasket') {

				my $basket = WriteNewBasket($uid);
				if($basket != 0) {
					goah::Modules->AddMessage('info', __("New basket created"));
				} else {
					goah::Modules->AddMessage('error',__("Can't add new basket to database"));
				}
				$variables{'function'} = 'modules/Basket/activebasket';
				$variables{'activebasket'} = $basket;
				$variables{'data'} = ReadBaskets($basket);
				$variables{'basketrows'} = ReadBasketrows($basket);

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
				$variables{'data'} = ReadBaskets($q->param('id'));
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
				$variables{'data'} = ReadBaskets($q->param('basketid'));
				$variables{'basketrows'} = ReadBasketrows($q->param('basketid'));
				$variables{'function'} = 'modules/Basket/activebasket';
				$variables{'activebasket'} = $q->param('basketid');

		} elsif($q->param('action') eq 'editrow') {

				if(UpdateBasketRow() == 0) {
					goah::Modules->AddMessage('info',__("Row updated"));
				} else {
					goah::Modules->AddMessage('error',__("Can't update row."));
				}
				$variables{'data'} = ReadBaskets($q->param('target'));
				$variables{'basketrows'} = ReadBasketrows($q->param('target'));
				$variables{'activebasket'} = $q->param('activebasket');
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

		} elsif($q->param('action') eq 'basket2invoice') {

				if(BasketToInvoice($q->param('target'))) {
					goah::Modules->AddMessage('info',__("Basket converted to invoice"));
				} else {
					goah::Modules->AddMessage('error',__("Can't create invoice"));
				}

		} elsif($q->param('action') eq 'showgroup') {

				$variables{'function'} = 'modules/Basket/showgroup';
				my $tmpdata = ReadBaskets($q->param('basketid'));
				$variables{'data'} = $tmpdata;
				$variables{'products'} = goah::Modules::Productmanagement::ReadProductsByGroup($q->param('groupid'),$uid);
				$variables{'productinfo'} = sub { goah::Modules::Productmanagement::ReadData('products',$_[0],$uid) };

		} else {
				goah::Modules->AddMessage('error',__("Module doesn't have function ")."'".$q->param('action')."'.");
				$variables{'function'} = 'modules/blank';
		}

	}

	$variables{'baskets'} = ReadBaskets('',$uid);
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
		if($fieldinfo{'required'} == '1' && !($q->param($fieldinfo{'field'})) ) {
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
	$data{'state'} = '0';
	$data{'ordernum'} = '0';
	$data{'ownerid'} = $_[0];

	my $basket = $db->insert(\%data);
	return $basket->id;
}

#
# Function: ReadBaskets
#
#   Read active baskets from the database.
#
# Parameters:
#
#   id - Id to retrieve from database. If omitted every basket is returned
#   ownerid - UID to search baskets since we show only 'owned' baskets to users (temporarily disabled)
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
	my $sort = 'updated';
	use goah::Database::Baskets;
	$db = new goah::Database::Baskets;

	my @data;
	if(!($_[0]) || $_[0] eq '') {
		# Dummy fix. This will show all baskets to all users.
		#@data = $db->search_where({ state => '0', ownerid => $_[1] }, { order_by => $sort });
		@data = $db->search_where({ state => '0' }, { order_by => $sort });
		my %baskets;
		my $i=0;
		my $f;
		my $br;
		my %basketrows;
		my @rows;
		my $total=0;
		foreach (@data) {
			foreach my $k (keys(%basketdbfields)) {
				$f=$basketdbfields{$k}{'field'};		
				$baskets{$i}{$f}=$_->get($f);
			}
			$br=ReadBasketrows($_->id);
			%basketrows=%$br;
			$baskets{$i}{'total'}=$basketrows{-1}{'baskettotal'};
			$total+=$basketrows{-1}{'baskettotal'};
			@rows=sort keys(%basketrows);
			$baskets{$i}{'rows'}=pop @rows;
			$baskets{$i}{'rows'}++;
			$i++;
		} 
		$baskets{-1}{'total'}=goah::GoaH->FormatCurrency($total,0,$uid,'out',$settref);
		return \%baskets;
	} else {
		@data = $db->search_where({ id => $_[0] });
		if(scalar(@data) == 0) {
			return 0;
		}
		return $data[0];
	}
	return 0;
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

		if($q->param($fieldinfo{'field'})) {

			if($fieldinfo{'field'} eq 'purchase' || $fieldinfo{'field'} eq 'sell') {
				my $amt = goah::GoaH->FormatCurrency($q->param($fieldinfo{'field'}),$prod{'vat'},$uid,'in',$settref);
				$rowinfo->set($fieldinfo{'field'} => $amt);
				goah::Modules->AddMessage('debug',"Updated ".$fieldinfo{'field'}." to value $amt",__FILE__,__LINE__);

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

			} else {
				$rowinfo->set($fieldinfo{'field'} => decode("utf-8",$q->param($fieldinfo{'field'})));
			}
			
		} else {
			#goah::Modules->AddMessage('debug',"Empty value via form for ".$fieldinfo{'field'});
			if($fieldinfo{'field'} eq 'purchase') {
				#goah::Modules->AddMessage('debug',"Default purchase price applied");
				$rowinfo->set('purchase' => $prodinfo->purchase);
			} elsif($fieldinfo{'field'} eq 'sell') {
				$rowinfo->set('sell' => $prodinfo->sell);
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
#   productcode- Manufacturer product code
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

	# Loop trough an array of products
	if($q->param('addproducts')) {

		my @products = $q->param('addproducts');
		foreach my $prod (@products) {
			
			$purchase = $q->param('purchase_'.$prod);
			$sell = $q->param('sell_'.$prod);
			$amount = $q->param('amount_'.$prod);
			
			# Feed validation
			$amount=~s/,/./;
			$amount=~s/\ //;
			unless($amount=~/^([0-9\.]+)$/) {
				goah::Modules->AddMessage('warn',__("Amount field is not numeric. Setting amount to 0"));
				$amount=0.00;
			}

			if(AddProductToBasket($prod,$basketid,$purchase,$sell,$amount)==1) {
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
			}
			if($_[1] eq "productcode") {
				goah::Modules->AddMessage('debug',"Adding product via product code ".$_[0],__FILE__,__LINE__);
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
			$sell = $proddata{'sell'};
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
#
sub AddProductToBasket {

	unless($_[0]) {
		goah::Modules->AddMessage('error',__("Can't add individual product to basket. Product ID is missing."));
		return 0;
	}

	goah::Modules->AddMessage('debug',"Fetch product info with uid ".$uid,__FILE__,__LINE__); 
	my $pinfo = goah::Modules::Productmanagement->ReadData('products', $_[0], $uid,$settref);
	if($pinfo == 0) {
		goah::Modules->AddMessage('error', __("Invalid product id. Can't add product to basket.")." (".$_[0].")");
		return 1;
	}
	my %prod = %$pinfo;
	my %data;

	$data{'productid'} = $_[0];
	$data{'basketid'} = $_[1];

	$data{'purchase'} = goah::GoaH->FormatCurrency($_[2],$prod{'vat'},$uid,'in',$settref);
	$data{'sell'} = goah::GoaH->FormatCurrency($_[3],$prod{'vat'},$uid,'in',$settref);
	$data{'amount'} = decode("utf-8",$_[4]);
	$data{'rowinfo'} = decode("utf-8",$_[5]);
	$data{'code'} = $prod{'code'};
	$data{'name'} = $prod{'name'};

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

	use goah::Database::Basketrows;
	use goah::Database::Products;
	my %rowdata;
	my $field;
	my $baskettotal=0;

	if( !($_[1]) || $_[1]==-1) {
		# We don't have id for individual row, read all rows for
		# the basket
		my @data = goah::Database::Basketrows->search_where({basketid => $_[0]}, { order_by => 'id' });
		my $i=-1;
		foreach my $row (@data) {
			
			$i++;
			
			foreach my $key (keys %basketrowdbfields) {
				$field = $basketrowdbfields{$key}{'field'};
				if($field eq 'purchase' || $field eq 'sell') {
					my $prodpoint = goah::Modules::Productmanagement::ReadData('products',$row->productid,$uid,$settref); 
					my %prod = %$prodpoint;
					if($_[1]==-1) {
						$rowdata{$i}{$field} = goah::GoaH->FormatCurrency($row->get($field),0,$uid,'in',$settref);
					} else {
						$rowdata{$i}{$field} = goah::GoaH->FormatCurrency($row->get($field),$prod{'vat'},$uid,'out',$settref);
					}
				} else {
					$rowdata{$i}{$field} = $row->get($field);
				}
			}
			unless($rowdata{$i}{'amount'}) {
				$rowdata{$i}{'amount'}=0;
			}
			$rowdata{$i}{'total'} = goah::GoaH->FormatCurrency( ($rowdata{$i}{'sell'}*$rowdata{$i}{'amount'}),0,$uid,'out',$settref);
			$baskettotal+=($rowdata{$i}{'sell'}*$rowdata{$i}{'amount'});
			$rowdata{$i}{'code'} = $row->get('code');
			$rowdata{$i}{'name'} = $row->get('name');

			my $proddata=goah::Database::Products->retrieve($row->get('productid'));
			$rowdata{$i}{'in_store'}=$proddata->get('in_store');

		}
		$rowdata{-1}{'baskettotal'} = goah::GoaH->FormatCurrency($baskettotal,0,$uid,'out',$settref);
		return \%rowdata;
	} else {
		# Row id is set, read only single row from the database
		my $data = goah::Database::Basketrows->retrieve($_[1]);
		foreach my $key (keys %basketrowdbfields) {
			$field = $basketrowdbfields{$key}{'field'};
			if($field eq 'purchase' || $field eq 'sell') {
				my $prodpoint = goah::Modules::Productmanagement::ReadData('products',$data->productid,$uid,$settref); 
				my %prod = %$prodpoint;
				$rowdata{$field} = goah::GoaH->FormatCurrency($data->get($field),$prod{'vat'},$uid,'out',$settref);
			} else {
				$rowdata{$field} = $data->get($field);
			}
		}
		$rowdata{'code'} = $data->get('code');
		$rowdata{'name'} = $data->get('name');
		$rowdata{'total'} = goah::GoaH->FormatCurrency( ($rowdata{'sell'}*$rowdata{'amount'}),0,$uid,'out',$settref);

		my $proddata=goah::Database::Products->retrieve($data->get('productid'));
		$rowdata{'in_store'}=$proddata->get('in_store');

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
		goah::Modules->AddMessage('error',__("DeleteBasket called outside package goah::Modules::Basket!"));
		return 0;
	}
	
	unless($_[0]) {
		goah::Modules->AddMessage('error',__("Can't delete basket! Basket id is missing!"));
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

	goah::Modules->AddMessage('debug',"BasketToInvoice -function started");

	unless($_[0]) {
		goah::Modules->AddMessage('error',__("Can't convert basket! Basket id is missing!"));
		return 0;
	}

	# Order ready, create referral
	use goah::Modules::Referrals;
	my $refid = goah::Modules::Referrals->NewReferral($_[0]);
	if($refid > 0) {
		goah::Modules->AddMessage('info',__("Referral created."));
	} else {
		goah::Modules->AddMessage('error',__("Can't create referral!"));
		return 0;
	}

	if(goah::Modules::Referrals->FillReferral($refid)) {
		goah::Modules->AddMessage('info',__("Filled referral amounts."));
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
		goah::Modules->AddMessage('info',__("Basket converted to order. Order number ").$ordernum);
	}

	return 1;

}

1;
