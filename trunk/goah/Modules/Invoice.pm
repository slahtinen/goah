#!/usr/bin/perl -w -CSDA

=begin nd

Package: goah::Modules::Invoice

  Functions to create, modify and print invoice information. Functions
  rely quite heavily to Productmanagement -funtions to access product
  information.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.
  See LICENSE and COPYRIGHT -files for full details.

About: See also

  <goah::Modules::Productmanagement>

=cut

package goah::Modules::Invoice;

use Cwd;
use Locale::TextDomain ('Invoice', getcwd()."/locale");

use strict;
use warnings;

use goah::Modules::Customermanagement;
use goah::Modules::Productmanagement;
use goah::GoaH;


#
# Hash: invoicestates
#
#   Defines possible states for the invoice. *NOTE:* This variable
#   should be removed soon.
#
my %invoicestates = ( 	0 => __("Open"),
			1 => __("Sent"),
			2 => __("Remark1"),
			3 => __("Remark2"),
			4 => __("Closed, payment received"),
			5 => __("Closed, cash payment"),
			6 => __("Closed, card payment") );

#
# String: uid
#
#   User id, get's stored via Start() -function
#
my $uid='';
my $settref='';


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

	$uid = $_[1];
	$settref = $_[2];

	my %variables;

	$variables{'function'} = 'modules/Invoice/invoices';
	$variables{'module'} = 'Invoice';
	$variables{'gettext'} = sub { return __($_[0]); };
        $variables{'formatdate'} = sub { goah::GoaH::FormatDate($_[0]); };
	$variables{'invoicestates'} = \%invoicestates;

	$variables{'customers'}=goah::Modules::Customermanagement->ReadAllCompanies(1);
	$variables{'companyinfo'} = sub { goah::Modules::Customermanagement::ReadCompanydata($_[0],1) };
	$variables{'locationinfo'} = sub { goah::Modules::Customermanagement::ReadLocationdata($_[0]) };
	$variables{'locations'} = sub { goah::Modules::Customermanagement::ReadCompanylocations($_[0]) };
	$variables{'products'} = sub { goah::Modules::Productmanagement::ReadData('products',,$uid,$settref) };
	$variables{'productinfo'} = sub { goah::Modules::Productmanagement::ReadData('products',$_[0],$uid,$settref) };

	$variables{'paymentconditions'}=goah::Modules::Customermanagement::ReadSetup('paymentcondition');

	my $total = sub { ReadInvoiceTotal($_[0]) }; 
	$variables{'readtotal'} = $total;

	my $q = CGI->new();
	my $tmp;
	if($q->param('action')) {

		if($q->param('action') eq 'show') {

			$tmp = ReadInvoices($q->param('target'));
			$variables{'invoice'} = $tmp;

			$tmp = ReadInvoicerows($q->param('target'));
			$variables{'invoicerows'} = $tmp;

			$tmp = ReadInvoicehistory($q->param('target'));
			$variables{'invoicehistory'} = $tmp;
	
			$variables{'function'} = 'modules/Invoice/invoiceinfo';

		} elsif($q->param('action') eq 'addevent') {

			if(AddEventToInvoice($q->param('target'),$q->param('information'))) {
				goah::Modules->AddMessage('info',__("Event added to invoice"));
			} else {
				goah::Modules->AddMessage('error',__("Can't add event to invoice."));
			}

			
			$tmp = ReadInvoices($q->param('target'));
			$variables{'invoice'} = $tmp;

			$tmp = ReadInvoicerows($q->param('target'));
			$variables{'invoicerows'} = $tmp;

			$tmp = ReadInvoicehistory($q->param('target'));
			$variables{'invoicehistory'} = $tmp;

			$variables{'function'} = 'modules/Invoice/invoiceinfo';

		} elsif($q->param('action') eq 'updateinvoice') {

			my $state;

			if($q->param('invoicetobilling')) {
				$state=1;
			} elsif($q->param('invoicetocashreceipt')) {
				$state=5;
			} elsif($q->param('invoicetocardreceipt')) {
				$state=6;
			} elsif($q->param('invoicebacktobasket')) {
		
				# Convert unsent invoice back to basket

				# First, check that invoice status is convertable
				my $invoice = ReadInvoices($q->param('target'));
				unless($invoice->id eq $q->param('target')) {
					goah::Modules->AddMessage('error',__("Can't read invoice information. Can't revert invoice into an basket."),__FILE__,__LINE__);
				} else {
					my $ok=1;
					unless($invoice->state eq "0") {
						goah::Modules->AddMessage('error',__("Can't delete invoice! Invoice already sent!"));
						goah::Modules->AddMessage('debug',"Invoice state: ".$invoice->state,__FILE__,__LINE__);
						$ok=0;
					}
					# Actually delete the invoice and referral included in it
					use goah::Modules::Referrals;
					my $delref = goah::Modules::Referrals->DeleteReferral($invoice->referralid);

					if($delref==0 && $ok==1) {
						goah::Modules->AddMessage('info',__("Referral removed."));
						if(DeleteInvoice($q->param('target'))) {
							goah::Modules->AddMessage('info',__("Invoice converted to basket"),__FILE__,__LINE__);
						} else {
							goah::Modules->AddMessage('error',__("Couldn't convert invoice to basket!"),__FILE__,__LINE__);
						}
					} elsif($ok==1) {
						goah::Modules->AddMessage('error',__("Couldn't delete referral. Leaving invoice untouched!"));
					}
				}

			}

			unless($q->param('invoicebacktobasket')) {
				if(UpdateInvoiceinfo($q->param('target'),$state)) {
					goah::Modules->AddMessage('info',__("Invoice information updated."));
				} else {
					goah::Modules->AddMessage('error',__("Can't update invoice information!"));
				}

				$tmp = ReadInvoices($q->param('target'));
				$variables{'invoice'} = $tmp;

				$tmp = ReadInvoicerows($q->param('target'));
				$variables{'invoicerows'} = $tmp;

				$tmp = ReadInvoicehistory($q->param('target'));
				$variables{'invoicehistory'} = $tmp;

				$variables{'function'} = 'modules/Invoice/invoiceinfo';
			} else {

				$variables{'function'} = 'modules/Invoice/invoices';
				$variables{'invoices'} = ReadInvoices();
				my @tmp;
				@tmp=qw(0 1 2 3);
				my $csvurl.="&states=".join("&states=",@tmp);
				$variables{'csvurl'}=$csvurl;
				$variables{'search_states'}=\@tmp;
			}

		} elsif($q->param('action') eq 'invoicetobilling') {

			if(UpdateInvoiceinfo($q->param('target'))) {
				goah::Modules->AddMessage('info',__("Invoice transferred to billing. Don't forget to print out PDF!"));
			} else {
				goah::Modules->AddMessage('error',__("Can't update invoice information!"));
			}

			$tmp = ReadInvoices($q->param('target'));
			$variables{'invoice'} = $tmp;
			$tmp = ReadInvoicerows($q->param('target'));
			$variables{'invoicerows'} = $tmp;
			$tmp = ReadInvoicehistory($q->param('target'));
			$variables{'invoicehistory'} = $tmp;
			$variables{'function'} = 'modules/Invoice/invoiceinfo';
		} elsif( ($q->param('action') eq 'invoicetocashreceipt') || $q->param('action') eq 'invoicetocardreceipt') {
			if(UpdateInvoiceinfo($q->param('target'))) {
				if($q->param('action') eq 'invoicetocashreceipt') {
					goah::Modules->AddMessage('info',__("Cash payment received. Don't forget to print out PDF!"));
				} else {
					goah::Modules->AddMessage('info',__("Card payment received. Don't forget to print out PDF!"));
				}
			} else {
				goah::Modules->AddMessage('error',__("Can't update invoice information!"));
			}
                        $tmp = ReadInvoices($q->param('target'));
                        $variables{'invoice'} = $tmp;
                        $tmp = ReadInvoicerows($q->param('target'));
                        $variables{'invoicerows'} = $tmp;
                        $tmp = ReadInvoicehistory($q->param('target'));
                        $variables{'invoicehistory'} = $tmp;
                        $variables{'function'} = 'modules/Invoice/invoiceinfo';
		} elsif($q->param('action') eq 'invoicepaymentreceived') {
			if(UpdateInvoiceinfo($q->param('target'))) {
				goah::Modules->AddMessage('info',__("Invoice payment received."));
			} else {
				goah::Modules->AddMessage('info',__("Card payment received. Don't forget to print out PDF!"));
			}
                        $tmp = ReadInvoices($q->param('target'));
                        $variables{'invoice'} = $tmp;
                        $tmp = ReadInvoicerows($q->param('target'));
                        $variables{'invoicerows'} = $tmp;
                        $tmp = ReadInvoicehistory($q->param('target'));
                        $variables{'invoicehistory'} = $tmp;
                        $variables{'function'} = 'modules/Invoice/invoiceinfo';
		} else {  

			goah::Modules->AddMessage('error',__("Module doesn't have function ")."'".$q->param('action')."'.");
			$variables{'function'} = 'modules/blank';
		}

	} else {
		$variables{'invoices'} = ReadInvoices();

		my @tmp;
		my $csvurl="module=Invoice";
		if($q->param('subaction') eq 'search') {
			@tmp=$q->param('states');
			$variables{'search_startdate'}=$q->param('fromdate');
			$variables{'search_enddate'}=$q->param('todate');
			if($q->param('customer')) {
				$variables{'search_customer'}=$q->param('customer');
			} else {
				$variables{'search_customer'}='*';
			}
			$csvurl.="&subaction=search&";
			$csvurl.="fromdate=".$q->param('fromdate')."&";
			$csvurl.="todate=".$q->param('todate')."&";
			$csvurl.="customer=".$variables{'search_customer'};
		} else {
			@tmp=qw(0 1 2 3);
		}
		$csvurl.="&states=".join("&states=",@tmp);
		$variables{'csvurl'}=$csvurl;
		$variables{'search_states'}=\@tmp;
	}



	return \%variables;
}


#
# Function: NewInvoice
#
# Create new invoice. Invoice is always created from basket, so 
# we'll read invoice information via basket.
#
# Parameters:
#
#   id - ID number for basket which is used to create invoice
#
# Returns:
#  
#   success - 1
#   fail - 0
#
sub NewInvoice {

	# This function is called outside of the package internal namespace
	# so we need to handle that case as well.
	if($_[0]=~/goah::Modules::Invoice/) {
		shift;
	}

	unless($_[0]) {
		goah::Modules->AddMessage('error',__("Can't create new invoice!")." ".__("Referral id is missing!"));
		return 0;
	}

	use goah::Database::Invoices;

	#
	# THIS NEEDS TO BE CHANGED TO GET DATA FROM Referrals -MODULE ITSELF!
	# NOT DIRECTLY FROM THE DATABASE!
	use goah::Database::Referrals;
	my $refinfo = goah::Database::Referrals->retrieve($_[0]);
	
	use goah::Modules::Basket;
	my $basketinfo = goah::Modules::Basket::ReadBaskets($refinfo->orderid);

	unless($basketinfo) {
		goah::Modules->AddMessage('error',__("Can't create new invoice!")." ".__("Can't read order contents!"));
		return 0;
	}

	# Search for next invoice number first
	#my @tmp = goah::Database::Invoices->retrieve_all_sorted_by('invoicenumber');
	#my $lastnumber = pop(@tmp);
	#	# We need atleast 3 digit invoice number so that referral numbers get calculated correctly.
	#if($lastnumber && $lastnumber>=100) {
	#	$lastnumber = $lastnumber->invoicenumber;
	#} else {
	#	$lastnumber = 100;
	#}

	my $lastnumber = '000';
	my $refnro = '000';
	#my $refnro = CreateReferencenumber($lastnumber);
	#if($refnro == 0) {
	#	goah::Modules->AddMessage('error',__("Can't get reference number for invoice number! Can't create invoice!"),__FILE__,__LINE__);
	#	return 0;
	#}
	
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	my $created = sprintf("%04d-%02d-%02d",$year+1900,$mon+1,$mday);

	use Date::Calc qw(Add_Delta_Days);
	my $customerdata = goah::Modules::Customermanagement->ReadCompanydata($basketinfo->companyid);
	my $due;
	if($customerdata == 0) {
		goah::Modules->AddMessage('error',__("Couldn't read customer data from the database. Can't calculate due date."));
		$due = $created;
	} else {
		my ($dyear,$dmon,$dmday) = Add_Delta_Days($year+1900,$mon+1,$mday,$customerdata->payment_condition);
		$due = sprintf("%04d-%02d-%02d",$dyear,$dmon,$dmday);
	}


	my $invoice = goah::Database::Invoices->insert( { 	invoicenumber => $lastnumber,
								referralid => $refinfo->id,
								companyid => $basketinfo->companyid,
								locationid => $basketinfo->locationid,
								billingid => $basketinfo->billingid,
								state => '0',
								referencenumber => $refnro,
								created => $created,
								due => $due,
								payment_condition => $customerdata->payment_condition});
	
	# Read rows from basket as well, so they can be written into invoice rows
	my $brows_pointer = goah::Modules::Basket::ReadBasketrows($refinfo->orderid,-1);
	my %basketrows = %$brows_pointer;

	#
	# THIS NEEDS TO BE CHANGED TO GET DATA FROM Referrals -MODULE ITSELF!
	# NOT DIRECTLY FROM THE DATABASE!
	use goah::Database::Referralrows;
	my $refrow;
	
	goah::Modules->AddMessage('debug',"Writing ".scalar(keys %basketrows)." rows to invoice");
	foreach my $rowkey (keys %basketrows) {
		if($rowkey<0) { next; }
		my @tmp = goah::Database::Referralrows->search_where({ rowid => $basketrows{$rowkey}{'id'} });
		my $refrow = $tmp[0];
		unless( AddRowToInvoice($invoice->id,$basketrows{$rowkey}{'productid'},$basketrows{$rowkey}{'purchase'},$basketrows{$rowkey}{'sell'},$refrow->sent,$basketrows{$rowkey}{'rowinfo'},$basketrows{$rowkey}{'productcode'},$basketrows{$rowkey}{'productname'}) ) {
			goah::Modules->AddMessage("debug","Insert check failed");
			return 0;
		}
	}


	# Add event to invoice about creation
	AddEventToInvoice($invoice->id,"Invoice created",$invoice->state);
	
	# Everything went ok, return 0 and let Basket module take care of 
	# removing basket which is now transferred to invoice
	return 1;
	
}

#
# Function: CreateReferencenumber
#
# Create reference number for the bill from invoice number. This calculation
# creates reference number fit for Finnish banking system, other countries
# may need to create something different.
#
# Parameters:
#
#   id - ID for invoice
#
# Returns:
#
#   success - Reference number for invoice
#   failure - 0
#
sub CreateReferencenumber {

	unless($_[0]) {
		goah::Modules->AddMessage('error', __("Can't create reference number for the bill! Invoice number is missing!"));
		return 0;
	}

	# Code derived from GoaH 1.2.5, I'll trust that ;)

	my $ref=$_[0];
	my $counter=0;
	my $sum=0;
	my $csum;
	my $len = length($ref);
	my @multipliers = (7, 3, 1);

	if($len > 19) {
		goah::Modules->AddMessage('error',__("Invoice number too long! Can't create reference number!"));
		return 0;
	}

	if($len < 3) {
		$ref = sprintf("%02d",$ref);
	}

	my $csumref=$ref;
	while($counter < $len) {
		$sum += ($csumref % 10) * $multipliers[($counter % 3)];
		$csumref = int($csumref / 10);
		$counter++;
	}

	$csum = (10 - ($sum % 10)) % 10;

	return $ref.$csum;

}

#
# Function: AddRowToInvoice
#
# Add row to invoice based on parameters
#
# Parameters:
#  
#   invoiceid - ID number for invoice (from database)
#   productid - ID number for product (from database)
#   purchase - Purchase price for unit (float)
#   sell - Sell price for unit (float)
#   amount - Amount to be added (float)
#   rowinfo - Additional information for the row
#   product code - Product code
#   product name - Product name
#
# Returns:
#
#   Always 1 (why?)
#
sub AddRowToInvoice {

	unless($_[0]) {
		goah::Modules->AddMessage('error',__("Can't add row to invoice!")." ".__("Invoice id is missing!"));
		return 1;
	}

	unless($_[1]=~/^[0-9]+$/) {
		goah::Modules->AddMessage('error',__("Can't add row to invoice!")." ".__("Product id is missing!"));
		goah::Modules->AddMessage('debug',"Product id: ".$_[1]);
		return 1;
	}

	use goah::Database::Invoicerows;
	goah::Database::Invoicerows->insert({ 	invoiceid => $_[0],
						productid => $_[1],
						purchase => $_[2],
						sell => $_[3],
						amount => $_[4],
						rowinfo => $_[5],
						code => $_[6],
						name => $_[7]});
	
	return 1;

}

#
# Function: ReadInvoices
#
# Read either all invoices or single invoice from database.
#
# Parameters
#
#   id - If ID is empty read all invoices, either read invoice by ID number
#
sub ReadInvoices {

	#use goah::Database::Invoices;
	use goah::Db::Invoices::Manager;
	my @data;
	
	if(!($_[0]) || $_[0] eq '') {

		my $datap=goah::Db::Invoices::Manager->get_invoices( sort_by => 'state,due' );
		@data=@$datap;
		#@data = goah::Database::Invoices->retrieve_all_sorted_by('state,due');

		# Search invoices.
		# ---------------
		# This is really slow approach, but let's fix this later, 
		# since it'll require modifications to Database modules
		# as well.
		my @states= qw(0 1 2 3);
		my $datestart='';
		my $dateend='';
		my $customer='';
		my %totalsum;

		my $q = CGI->new;
		if($q->param('subaction') eq 'search') {
			@states=$q->param('states');
		}

		if($q->param('fromdate')) {
			$datestart=$q->param('fromdate');
			unless($datestart=~/[0-9]{2}\.[0-9]{2}\.[0-9]{4}/) {
				goah::Modules->AddMessage('error',__("Start date isn't formatted correctly. Ignoring filter."));
				$datestart='';
			}
		}

		if($q->param('todate')) {
			$dateend=$q->param('todate');
			unless($dateend=~/[0-9]{2}\.[0-9]{2}\.[0-9]{4}/) {
				goah::Modules->AddMessage('error',__("End date isn't formatted correctly. Ignoring filter."));
				$dateend='';
			}
		}

		goah::Modules->AddMessage('debug',"States: @states");
		my %invoices;
		my $add;
		my $sortcounter=1000000;
		foreach my $inv (@data) {

			$add=-1;
			foreach my $s (@states) {
				if($s == $inv->state) {
					$add=1;
				} else {
					if($add!=1) {
						$add=0;
					}
				}

			}

			use Time::Local;
			my @invdate=split(/-/,$inv->created);
			my $invts=timelocal("00","00","00",$invdate[2],($invdate[1]-1),$invdate[0]);
			if($datestart!='' && $add==1) {
				my @searchdate=split(/\./,$datestart);
				my $searchts=timelocal("00","00","00",$searchdate[0],($searchdate[1]-1),$searchdate[2]);
				if($invts<$searchts) {
					$add=0;
				}
			}

			if($dateend!='' && $add==1) {
				my @searchdate=split(/\./,$dateend);
				my $searchts=timelocal("00","00","00",$searchdate[0],($searchdate[1]-1),$searchdate[2]);
				if($invts>$searchts) {
					$add=0;
				}
			}

			if($q->param('customer') && $add==1) {
				unless($q->param('customer') eq '*') {
					my $search=$q->param('customer');
					$search=~s/\*/\.\*/g;
				
					use goah::Modules::Customermanagement;
					my $cust=goah::Modules::Customermanagement->ReadCompanydata($inv->companyid);
					unless($cust->name=~/^$search$/i) {
						$add=0;
					}
				}
			}	


			if($add==1) {
				my $t = goah::Modules::Invoice->ReadInvoiceTotal($inv->id);
				my %tot=%$t;
				$totalsum{'vat0'}+=$tot{'vat0'};
				$totalsum{'inclvat'}+=$tot{'inclvat'};
				$totalsum{'vat'}+=$tot{'vat'};

				#$invoices{$inv->invoicenumber.'.'.$inv->id}=$inv;
				$sortcounter++;
				$invoices{$sortcounter}=$inv;
			}
		}

		$invoices{'total'}{'vat0'}=goah::GoaH->FormatCurrency($totalsum{'vat0'},0,$uid,'out',$settref);
		$invoices{'total'}{'inclvat'}=goah::GoaH->FormatCurrency($totalsum{'inclvat'},0,$uid,'out',$settref);
		$invoices{'total'}{'vat'}=goah::GoaH->FormatCurrency($totalsum{'vat'},0,$uid,'out',$settref);
		return \%invoices;
	} else {
		@data = goah::Database::Invoices->retrieve($_[0]);
		if(scalar(@data) == 0) {
			return 0;
		}
		return $data[0];
	}
	return 0;
}


#
# Function: ReadInvoicerows
#
# Read all rows and their data for spesific invoice.
#
# Parameters:
#
#   id - Invoice ID -number from database
#
# Returns:
#
#   Fail - 0
#   Success - Hash reference to invoice data
#
sub ReadInvoicerows {

	unless($_[0]) {
		goah::Modules->AddMessage('error',__("Can't read rows for invoice!")." ".__("Invoice id is missing!"));
		return 0;
	}

	if($uid eq '') {
		if($_[1]) {
			$uid = $_[1];
		} else {
			goah::Modules->AddMessage('error',__("Can't read rows for invoice!")." ".__("UID is missing"));
			return 0;
		}
	}

	#use goah::Database::Invoicerows;
	#my @rows = goah::Database::Invoicerows->search_where( { invoiceid => $_[0] }, { order_by => 'id' } );
	use goah::Db::Invoicerows::Manager;
	my $rowp=goah::Db::Invoicerows::Manager->get_invoicerows( query => [ invoiceid => $_[0] ], sort_by => 'id' );

	my @rows = @$rowp;

	my $i=0;
	my %rowdata;
	my %productdata;
	my $pdata;
	my $vat;
	foreach my $row (@rows) {
		#my $prodpoint = goah::Modules::Productmanagement::ReadData('products',$row->productid);
		#my %prod = %$prodpoint;

		$rowdata{$i}{'purchase'} = goah::GoaH->FormatCurrency($row->purchase,0,$uid,'out',$settref);
		$rowdata{$i}{'sell'} = goah::GoaH->FormatCurrency($row->sell,0,$uid,'out',$settref);
		$rowdata{$i}{'amount'} = sprintf("%.02f",$row->amount);
		$rowdata{$i}{'rowtotal'} = goah::GoaH->FormatCurrency(($row->sell*$row->amount),0,$uid,'out',$settref);
		$rowdata{$i}{'rowinfo'} = $row->rowinfo;
		$rowdata{$i}{'rowinfo'} =~s/€/&euro;/g;

		$pdata = goah::Modules::Productmanagement::ReadData('products',$row->productid,$uid,$settref);
		if($pdata==0) {
			goah::Modules->AddMessage('error',__("Fatal error! Can't read product information for invoice with id ".$row->productid));
			return 0;
		}
		%productdata = %$pdata;

		$vat = ($productdata{'vat'}/100)+1;
		$rowdata{$i}{'rowtotal'} = goah::GoaH->FormatCurrency(($row->sell*$row->amount),0,$uid,'out',$settref);
		$rowdata{$i}{'rowtotalvat'} = goah::GoaH->FormatCurrency(($row->sell*$row->amount*$vat),0,$uid,'out',$settref);
		$rowdata{$i}{'sellvat'} = goah::GoaH->FormatCurrency(($row->sell*$vat),0,$uid,'out',$settref);

		$rowdata{$i}{'code'} = $productdata{'code'};
		$rowdata{$i}{'name'} = $productdata{'name'};
		$rowdata{$i}{'unit'} = $productdata{'unit'};
		$rowdata{$i}{'vat'} = $productdata{'vat'};

		$i++;
	}

	return \%rowdata;
}

#
# Function: ReadInvoicehistory
#
# Read event history for invoice
#
# Parameters:
#   
#   id - Invoice id
#
# Returns:
#
#   success -  Reference for Class::DBI results
#   fail - 0
#
sub ReadInvoicehistory {

	unless($_[0]) {
		goah::Modules->AddMessage('error',__("Can't read invoice history!")." ".__("Invoice id is missing!"));
		return 0;
	}

	use goah::Database::Invoicehistory;
	my @data = goah::Database::Invoicehistory->search_where( { invoiceid => $_[0] },{ order_by => 'time' } );

	my %hist;
	my $i=0;
	foreach my $row (@data) {

		$hist{$i}{'time'} = goah::GoaH->FormatDate($row->time);
		$hist{$i}{'action'} = $row->action;
		$hist{$i}{'startstate'} = $row->startstate;
		$hist{$i}{'endstate'} = $row->endstate;
		$hist{$i}{'info'} = $row->info;

		$i++;
	}
	return \%hist;
}

#
# Function: ReadInvoiceTotal
#
# Read and calculate total sum for invoice. Calculation includes
# total sum VAT0, total sum incl. VAT and VAT amount.
#
# Parameters:
#
#   id - Invoice id
#
# Returns:
#
#   fail - 0
#   success - Hash reference with keys vat0, inclcvat and vat
#
sub ReadInvoiceTotal {

	if($_[0]=~/goah::Modules::Invoice/) {
		shift;
	}

	unless($_[0]) {
		goah::Modules->AddMessage('error',__("Can't calculate total sum for invoice! Invoice id is missing!"));
		return 0;
	}

	my $rowpointer = ReadInvoicerows($_[0]);
	if($rowpointer == 0) {
		goah::Modules->AddMessage('error',__("Fatal error. Can't read invoice total due to faulty invoice rows!"));
		return 0;
	}
	my %rows = %$rowpointer;
	my %total;
	$total{'vat0'}=0; # price without VAT
	$total{'inclvat'}=0; # price including VAT
	$total{'vat'}=0; # basically inclvat - vat0, VAT share of total sum

	my $proddata;
	my $vat;
	foreach my $key (keys %rows) {
		$total{'vat0'}+=$rows{$key}{'rowtotal'};
		$total{'inclvat'}+=$rows{$key}{'rowtotalvat'};
		$total{'vat'}+=$rows{$key}{'rowtotalvat'}-$rows{$key}{'rowtotal'};
	}

	$total{'vat0'}=goah::GoaH->FormatCurrency($total{'vat0'},0,$uid,'out',$settref);
	$total{'inclvat'}=goah::GoaH->FormatCurrency($total{'inclvat'},0,$uid,'out',$settref);
	$total{'vat'}=goah::GoaH->FormatCurrency($total{'vat'},0,$uid,'out',$settref);

	return \%total;
}

#
# Function: AddEventToInvoice
#
# Add event to invoice history. Event contains mainly
# information about invoice life cycle, but it's possible
# to add other kind information as well.
#
# Parameters:
#
#   id - Id for invoice from database
#   content - Event content information
#   state - State for the invoice after event
#   action - Type of the event. If none supplied will default to 'note'
#
# Returns:
#
#   Failure - 0
#   Success - 1
#
sub AddEventToInvoice {

	unless($_[0]) {
		goah::Modules->AddMessage('error',__("Can't add event to invoice!")." ".__("Invoice id is missing!"));
		return 0;
	}

	unless($_[1]) {
		goah::Modules->AddMessage('error',__("Can't add event to invoice!")." ".__("Event content is missing!"));
	}

	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	my $datetime = sprintf("%04d-%02d-%02d %02d:%02d:%02d",$year+1900,$mon+1,$mday,$hour,$min,$sec);

	my $invoicedata = ReadInvoices($_[0]);

	my $endstate;
	if($_[2]=~/[0-9]/) {
		$endstate = $_[2];
	} else {
		$endstate = $invoicedata->state;
	}

	my $action='note';
	if($_[3]) {
		$action = $_[3];
	}

	use goah::Database::Invoicehistory;
	goah::Database::Invoicehistory->insert({	invoiceid => $_[0],
							action => $action,
							info => $_[1],
							time => $datetime,
							startstate => $invoicedata->state,
							endstate => $endstate
						});
	
	return 1;
}

#
# Function: UpdateInvoiceinfo
#
#   Update invoice information to database. Function uses either HTTP-variables or
#   actual parameters to process the data.
#
# Parameters:
# 
#   id - Invoice id from database
#   state - Invoice state. Optional, if omitted uses HTTP variables
#
# Returns:
#
#   Success - 1
#   Failure - 0
#
sub UpdateInvoiceinfo {

	unless($_[0]) {
		goah::Modules->AddMessage('error',__("Can't update invoice information!")." ".__("Invoice id is missing!"),__FILE__,__LINE__);
		return 0;
	}

	my $q = CGI->new();

	my $invoice = ReadInvoices($_[0]);

        my $state;
        if($_[1]) {
                $state=$_[1];
        } elsif( !($q->param('state') eq '') ) {
                $state=$q->param('state');
        } else {
                goah::Modules->AddMessage('error',__("Can't update invoice information!")." ".__("Invoice state is missing!"),__FILE__,__LINE__);
                return 0;
        }

	if($invoice->state == 0 && $state == 1) {
		AddEventToInvoice($_[0],'Invoice transferred for billing.',$state,'update');
	} elsif($invoice->state == 0 && ($state == 5 || $state == 6)) {
		AddEventToInvoice($_[0],'Received payment for the invoice',$state,'closed');
	} elsif($invoice->state == 1 && ($state == 4) ) {
		AddEventToInvoice($_[0],'Invoice payment received.',$state,'closed');
	} else {
		AddEventToInvoice($_[0],'Invoice information updated.',$state,'update');
	}

	if($invoice->state==0 && $state != 0) {
	
		# Search for next invoice number first
		my @tmp = goah::Database::Invoices->retrieve_all_sorted_by('invoicenumber');
		my $lastnumber = pop(@tmp);
		if($lastnumber->invoicenumber && $lastnumber->invoicenumber>=100) {
			$lastnumber = $lastnumber->invoicenumber;
		} else {
			$lastnumber = 50000;
		}
		$lastnumber++;
		$invoice->invoicenumber($lastnumber);

		my $refnro = CreateReferencenumber($lastnumber);
		if($refnro == 0) {
			goah::Modules->AddMessage('error',__("Can't get reference number for invoice number! Can't create invoice!"),__FILE__,__LINE__);
			return 0;
		}
		$invoice->referencenumber($refnro);

                # Change billing date as well for today, unless user has 
                # changed the date
                if( !($q->param('created'))) {

                        # Switch created-date for today
                        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
                        my $today=sprintf("%04d-%02d-%02d",$year+1900,$mon+1,$mday);
                        $invoice->created($today);

                        goah::Modules->AddMessage('debug','Changed billing date to today',__FILE__,__LINE__);

                } else {
                        $invoice->created(goah::GoaH->FormatDate($q->param('created')));
                        goah::Modules->AddMessage('debug','Changed billing date to user setting',__FILE__,__LINE__);
                }

                $invoice->payment_condition($q->param('payment_condition'));
                my @created = split("-",$invoice->created);
                my ($dyear,$dmon,$dmday) = Add_Delta_Days($created[0],$created[1],$created[2],$invoice->payment_condition);
                my $due = sprintf("%04d-%02d-%02d",$dyear,$dmon,$dmday);
                $invoice->due($due);
	}

	$invoice->state($state);
	if($invoice->state==0 && $state == 0) {
		$invoice->created(goah::GoaH->FormatDate($q->param('created')));
		$invoice->payment_condition($q->param('payment_condition'));
	
		use Date::Calc qw(Add_Delta_Days);
		my $due;
		unless($invoice->payment_condition != '-1') {
			goah::Modules->AddMessage('error',__("Couldn't read payment condition! Can't calculate due date."));
			$due = $invoice->created();
		} else {
			if( ($invoice->state == 0) && ($state == 0) ) {
				my @created = split("-",$invoice->created);
				my ($dyear,$dmon,$dmday) = Add_Delta_Days($created[0],$created[1],$created[2],$invoice->payment_condition);
				$due = sprintf("%04d-%02d-%02d",$dyear,$dmon,$dmday);
			}
		}

		$invoice->due($due);
	}

	if($state == 5 || $state == 6) {
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
		my $received = sprintf("%04d-%02d-%02d",$year+1900,$mon+1,$mday);
		$invoice->received($received);
	}

	if($state == 4) {
		my $received;
		if($q->param('received') && !($q->param('received') eq '')) {
			$received=goah::GoaH->FormatDate($q->param('received'));
		} else {
			my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
			$received = sprintf("%04d-%02d-%02d",$year+1900,$mon+1,$mday);
		}
		$invoice->received($received);
	}

	$invoice->customerreference($q->param('customerreference'));

	$invoice->update;
	$invoice->commit;
	
	return 1;

}


# 
# Function: DeleteInvoice
#
#   Function to delete invoice information from the database. This is used only
#   when the invoice is converted back into an basket.
#
# Parameters:
#
#   id - Invoice id for removal
#
# Returns:
#
#   1 - Success
#   0 - Fail
#
sub DeleteInvoice {

	if($_[0]=~/goah::Modules::Invoice/) {
		shift;
	}

	unless($_[0]) {
		goah::Modules->AddMessage('error',__("Can't delete invoice! Id is missing!"),__FILE__,__LINE__);
		return 0;
	}

	use goah::Database::Invoices;
	use goah::Database::Invoicerows;

	my $invoice=goah::Database::Invoices->retrieve($_[0]);
	$invoice->delete;
	goah::Database::Invoices->commit;

	my @invoicerows=goah::Database::Invoicerows->search_where('invoiceid' => $_[0]);

	foreach my $row (@invoicerows) {
		$row->delete;
	}
	goah::Database::Invoicerows->commit;

	return 1;
}

1;
