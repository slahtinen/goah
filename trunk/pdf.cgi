#!/usr/bin/perl -w

=begin nd

Script: pdf.cgi

  An script to output pdf documents from GoaH. Basically this script
  is an modified version of index.cgi -file.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.
  See LICENSE and COPYRIGHT -files for full details.

About: TODO

  Currently this file only creates PDF documents for invoices. Basic
  functionality to include referrals and other documents is built but
  it's currently disabled.

=cut


use CGI::Carp qw(fatalsToBrowser);

use strict;
use warnings;
use utf8;

use CGI qw(:standard);
use Template;

use lib qw(.);
use goah::Auth;

use POSIX;

use Locale::TextDomain ('GoaH', getcwd()."/locale");

my $uid=0;
my $sessid;
my $auth=0;

my $q = new CGI;

# Read information from cookie, and check session id.
my $keksi = $q->cookie('goah');
if($keksi && length($keksi)>1) {
        my @tmp = split(/\./,$keksi);
        $uid = $tmp[0];
        $sessid = $tmp[1];
        $auth = goah::Auth->CheckSessionid($uid,$sessid);
} 

# If login isn't valid let's check if user has given login/password information.
# This check is made only if login isn't validated earlier
if($auth == 0) {

	# Check if user has given information and make sure they're not empty
	if($q->param('user') && $q->param('pass')) {
			
		# Tarkistetaan syötetyt tiedot
		$uid = goah::Auth->CheckLogin($q->param('user'),$q->param('pass'));
		if($uid!=0) {
			$auth=1; # Login ok
		} else {
			$auth=-1; # Incorrect username/password
		}
	} elsif($q->param('user') || $q->param('pass') ) {
		$auth=-1;
	}

}

my %templatevars; # Variables for Template Toolkit

$auth=1;

# We're logged in to system
if($auth==1) {

	use Template::Latex;
	my $tt;

	$tt = Template::Latex->new({
		INCLUDE_PATH  => 'templates/pdf/',
		OUTPUT_PATH   => 'tmp/',
		LATEX_FORMAT  => 'pdf',
		});
	
	use Template;
	$tt = Template->new( {
		ABSOLUTE => 1,
		INCLUDE_PATH  => 'templates/pdf/',
		POST_CHOMP => 1
	} );



	unless($q->param('type') && $q->param('id') && $q->param('type')=~/(invoice|basket)/) {
		print $q->header( -charset => "UTF-8" );
		print $q->start_html("PDF.CGI error"),
			$q->h1("PDF.CGI error"),
			"<p>Required parameters missing or not valid. Aborting.</p>",
			$q->end_html;
		exit;
	}

	use goah::Modules::Systemsettings;
	my $owner = goah::Modules::Systemsettings->ReadOwnerInfo();
	my $ownerloc = goah::Modules::Systemsettings->ReadDefaultOwnerLocation();

	$templatevars{'owner'} = $owner;	
	$templatevars{'ownerloc'} = $ownerloc;
	$templatevars{'formatdate'} = sub { goah::GoaH::FormatDate($_[0]); };

	use goah::Modules::Customermanagement;

	use Encode;
	my $billingaddr = { addr1 => 'N/A' };
	my $shippingaddr= { addr1 => 'N/A' };
	my $customerinfo;
	my $data;
	my $rows;

	# Read data for invoices
	if($q->param('type') eq 'invoice') {
		use goah::Modules::Invoice;
		$data = goah::Modules::Invoice::ReadInvoices($q->param('id'));
		$rows = goah::Modules::Invoice::ReadInvoicerows($data->id,$uid);

		# Bank accounts
		$templatevars{'bankaccounts'} = goah::Modules::Systemsettings->ReadBankAccounts();	

		my $total = goah::Modules::Invoice::ReadInvoiceTotal($data->id);
		$templatevars{'total'} = $total;

		# Process common data
		if($data->billingid && $data->billingid > 0) {
			$billingaddr = goah::Modules::Customermanagement::ReadLocationdata($data->billingid);
		} 
		if($data->locationid && $data->locationid > 0) {
			$shippingaddr = goah::Modules::Customermanagement::ReadLocationdata($data->locationid);
		}
		$customerinfo = goah::Modules::Customermanagement::ReadCompanydata($data->companyid);


		# Ugly solution, this should be fixed
		if($data->state == 0) {
			$templatevars{'file'} = 'invoicedraft_fi.tt2';
		} elsif($data->state == 5) {
			$templatevars{'file'} = 'invoice_cashreceipt.tt2';
			$templatevars{'paymentoption'} = sub { return encode('utf-8','Käteismaksu') };
		} elsif($data->state == 6) {
			$templatevars{'file'} = 'invoice_cashreceipt.tt2';
			$templatevars{'paymentoption'} = 'Pankki/luottokortti';
		} else {
			$templatevars{'file'} = 'invoice_fi.tt2';
		}

	}

	# Read data for baskets
	my %basketdata;
	if($q->param('type') eq 'basket') {

		use goah::Modules::Basket;
		$data = goah::Modules::Basket::ReadBaskets($q->param('id'));
		%basketdata=%$data;
		$rows = goah::Modules::Basket::ReadBasketrows($q->param('id'));

		# Process common data
		if($basketdata{'billingid'} && $basketdata{'billingid'} > 0) {
			$billingaddr = goah::Modules::Customermanagement::ReadLocationdata($basketdata{'billingid'});
		}
		if($basketdata{'locationid'} && $basketdata{'locationid'} > 0) {
			$shippingaddr = goah::Modules::Customermanagement::ReadLocationdata($basketdata{'locationid'});
		}
		$customerinfo = goah::Modules::Customermanagement::ReadCompanydata($basketdata{'companyid'});

		# Reformat longinfo for latex
		$basketdata{'longinfo'}=~s/&euro;/\\euro/g;
		$basketdata{'longinfo'}=~s/([\#\$\%\&\_\^\{\}\~])/\\$1/g;
		$basketdata{'longinfo'}=~s/= (.*) =/\\textbf{\1}\\\\/gi;
		#$basketdata{'longinfo'}=~s/_(.*)_/\\uline{\1}/gi;
		$basketdata{'longinfo'}=~s/\n/\\\\/g;

		$data=\%basketdata;
		$templatevars{'file'}='offer_fi.tt2';

	}

	$templatevars{'data'} = $data;
	$templatevars{'rows'} = $rows;
	$templatevars{'customerinfo'} = $customerinfo;
	$templatevars{'billingaddr'} = $billingaddr;
	$templatevars{'shippingaddr'} = $shippingaddr;

	$templatevars{'escape'}= sub{ 
					$_[0]=~s/&euro;/\\euro/g; 
					$_[0]=~ s/([\#\$\%\&\_\^\{\}\~])/\\$1/g; 
					if($_[1] && $_[1]>0) {
						if(length($_[0])>$_[1]) {
							$_[0]=~s/(.{$_[1]})/\1\\allowbreak /g;
						}
					}
					return $_[0]; 
				};

	use goah::Modules::Productmanagement;
	$templatevars{'productinfo'} = sub { goah::Modules::Productmanagement::ReadData('products',$_[0],$uid) };
	$templatevars{'logo'} = getcwd()."/pdflogo.jpg";

	# Debugging, print only the tex -code
	if(0==1) {
		print $q->header( -type => 'text/plain', -charset => 'utf-8' );
		$tt->process($templatevars{'file'},\%templatevars) or
			die "ERR! ".$tt->error();
	}

	my $filename;
	if($q->param('type') eq 'invoice') {
		$filename='invoice_'.$data->invoicenumber;
	} elsif($q->param('type') eq 'basket') {
		$filename="basket_".$basketdata{'id'};
	} else {
		$filename='unknown';
	}

	print $q->header( -type => 'application/pdf',
			  -'content-disposition' => 'attachment; filename='.$filename.".pdf");
	$tt->process('builddoc.tt2', \%templatevars, '', binmode => 1)
		|| die $tt->error();

} else {
	# Normal login
	print header( -charset => 'UTF-8');
	print "<h1>NOT LOGGED IN!</h1>\n";
}

1;


