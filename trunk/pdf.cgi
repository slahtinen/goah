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



	unless($q->param('type') && $q->param('id') && $q->param('type')=~/invoice/) {
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

	use goah::Modules::Invoice;
	my $invoicedata = goah::Modules::Invoice::ReadInvoices($q->param('id'));

	my $invoicerows = goah::Modules::Invoice::ReadInvoicerows($invoicedata->id,$uid);

	use goah::Modules::Customermanagement;
	my $customerinfo = goah::Modules::Customermanagement::ReadCompanydata($invoicedata->companyid);

	my $billingaddr;
	if($invoicedata->billingid && $invoicedata->billingid > 0) {
		$billingaddr = goah::Modules::Customermanagement::ReadLocationdata($invoicedata->billingid);
	} else {
		$billingaddr = { addr1 => 'N/A' };
	}

	my $shippingaddr;
	if($invoicedata->locationid && $invoicedata->locationid > 0) {
		$shippingaddr = goah::Modules::Customermanagement::ReadLocationdata($invoicedata->locationid);
	} else {
		$shippingaddr = { addr1 => 'N/A' };
	}

	# Bank accounts
	$templatevars{'bankaccounts'} = goah::Modules::Systemsettings->ReadBankAccounts();	

	# Ugly solution, this should be fixed
	use Encode;
	if($invoicedata->state == 0) {
		$templatevars{'file'} = 'invoicedraft_fi.tt2';
	} elsif($invoicedata->state == 5) {
		$templatevars{'file'} = 'invoice_cashreceipt.tt2';
		$templatevars{'paymentoption'} = sub { return encode('utf-8','Käteismaksu') };
	} elsif($invoicedata->state == 6) {
		$templatevars{'file'} = 'invoice_cashreceipt.tt2';
		$templatevars{'paymentoption'} = 'Pankki/luottokortti';
	} else {
		$templatevars{'file'} = 'invoice_fi.tt2';
	}

	$templatevars{'escape'}=sub{ $_[0]=~s/&euro;/\\euro/g; $_[0]=~ s/([\#\$\%\&\_\^\{\}\~])/\\$1/g; return $_[0]; };
	
	$templatevars{'invoicedata'} = $invoicedata;
	$templatevars{'invoicerows'} = $invoicerows;
	$templatevars{'customerinfo'} = $customerinfo;
	$templatevars{'billingaddr'} = $billingaddr;
	$templatevars{'shippingaddr'} = $shippingaddr;

	my $total = goah::Modules::Invoice::ReadInvoiceTotal($invoicedata->id);
	$templatevars{'total'} = $total;

	use goah::Modules::Productmanagement;
	$templatevars{'productinfo'} = sub { goah::Modules::Productmanagement::ReadData('products',$_[0],$uid) };
	$templatevars{'logo'} = getcwd()."/pdflogo.jpg";

	# Debugging, print only the tex -code
	if(1==0) {
		print $q->header( -type => 'text/plain', -charset => 'utf-8' );
		$tt->process($templatevars{'file'},\%templatevars) or
			die "ERR! ".$tt->error();
	}

	print $q->header( -type => 'application/pdf',
			  -'content-disposition' => 'attachment; filename=invoice_'.$invoicedata->invoicenumber.'.pdf');
	$tt->process('builddoc.tt2', \%templatevars, '', binmode => 1)
		|| die $tt->error();

} else {
	# Normal login
	print header( -charset => 'UTF-8');
	print "<h1>NOT LOGGED IN!</h1>\n";
}

1;


