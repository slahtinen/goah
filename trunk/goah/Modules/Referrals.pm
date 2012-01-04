#!/usr/bin/perl -w -CSDA

=begin nd

Package: goah::Modules::Referrals

  This package contains functions to create and manage outgoing referrals and
  "open" shipments.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Modules::Referrals;

use Cwd;
use Locale::TextDomain ('Referrals', getcwd()."/locale");

use strict;
use warnings;
use utf8;
use Encode;

use goah::Modules::Customermanagement;
use goah::Modules::Productmanagement;

sub Start {

	my %variables;

	$variables{'module'} = 'Referrals';
	$variables{'gettext'} = sub { return __($_[0]); };

	return \%variables;
}


##################################
#
# Modules private functions
#

#
# Referral is always created from basket, so 
# we'll read referral information via basket.
sub NewReferral {

	# This function is called outside of the package internal namespace
	# so we need to handle that case as well.
	if($_[0]=~/goah::Modules::Referrals/) {
		shift;
	}

	unless($_[0]) {
		goah::Modules->AddMessage('error',__("Can't create new referral!")." ".__("Basket id is missing!"));
		return 0;
	}

	use goah::Database::Referrals;
	
	use goah::Modules::Basket;
	my $basketinfo = goah::Modules::Basket::ReadBaskets($_[0]);

	if($basketinfo==0) {
		goah::Modules->AddMessage('error',__("Can't create new referral!")." ".__("Can't read basket contents!"));
		return 0;
	}

	# Search for next referral number first
	my @tmp = goah::Database::Referrals->retrieve_all_sorted_by('refnum');
	my $lastnumber = pop(@tmp);
	if($lastnumber) {
		$lastnumber = $lastnumber->refnum;
	} else {
		$lastnumber = 1;
	}

	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	my $now = sprintf("%04d-%02d-%02d",$year+1900,$mon+1,$mday);


	my $referral = goah::Database::Referrals->insert( { 	refnum => ($lastnumber+1),
								orderid => $basketinfo->id,
								created => $now });

	# Read rows from basket as well, so they can be written into referral rows
	my $brows_pointer = goah::Modules::Basket::ReadBasketrows($_[0]);
	my %basketrows = %$brows_pointer;

	foreach my $rowkey (keys %basketrows) {
		if($rowkey<0) { next; }
		unless( AddRowToReferral($referral->id,$basketrows{$rowkey}{'id'},'0',$basketrows{$rowkey}{'rowinfo'}) ) {
			goah::Modules->AddMessage("debug","Insert check failed on referral creation");
			return 0;
		}
	}

	
	# Everything went ok, return 0 and let Basket module take care of 
	# removing basket which is now transferred to invoice
	return $referral->id;
	
}

#
# Function: AddRowToReferral
#
# TODO:
#   Comments missing.
#
sub AddRowToReferral {

	unless($_[0]) {
		goah::Modules->AddMessage('error',__("Can't add row to referral!")." ".__("Referral id is missing!"));
		return 0;
	}

	unless($_[1]=~/^[0-9]+$/) {
		goah::Modules->AddMessage('error',__("Can't add row to referral!")." ".__("Basket row id is missing!"));
		return 0;
	}

        use goah::Modules::Basket;
	my $rowpointer = goah::Modules::Basket::ReadBasketrows(0,$_[1]);

	if($rowpointer==0) {
		goah::Modules->AddMessage('error',__("Can't add row to referral!")." ".__("Can't read basket row!"));
		return 0;
	}

	my %rowinfo = %$rowpointer;
	my $remaining = $rowinfo{'amount'} - $_[2];

	use goah::Database::Referralrows;

	my @tmp = goah::Database::Referralrows->search_where({ rowid => $_[1] });
	if(scalar(@tmp) > 0) {
		my $data = $tmp[0];
		$data->sent($_[2]);
		$data->remaining($remaining);
		$data->update();
	} else {
		goah::Database::Referralrows->insert({ 	refid => $_[0],
							rowid => $_[1],
							sent => $_[2],
							remaining => $_[3]});
	}
	
	return 1;
}

#
# Function: FillReferral
#
#   An simple function to "fill in" referral so it can be quickly transferred
#   to invoice
#
# Parameters:
#
#   id - Referral id to fill
#
# Returns:
#   
#  0 - Fail
#  1 - Success
#
sub FillReferral {

	if($_[0]=~/goah::Modules::Referrals/) {
		shift;
	}

	unless($_[0]) {
		goah::Modules->AddMessage('error',__("Can't fill referral!")." ".__("Referral id is missing!"));
		return 0;
	}

	use goah::Modules::Basket;
	use goah::Database::Referralrows;
	use goah::Database::Products;

	my @rows = goah::Database::Referralrows->search_where({ refid => $_[0]});
	my $rowpointer;
	my %rowinfo;
	foreach my $row (@rows) {
		$rowpointer = goah::Modules::Basket::ReadBasketrows(0,$row->rowid);
		%rowinfo = %$rowpointer;

		$row->sent($rowinfo{'amount'});
		$row->remaining('0');
		$row->update;
		$row->commit;

		# We also need to calculate new storage value for product
		my $proddata = goah::Database::Products->retrieve($rowinfo{'productid'});
		my $amt = $proddata->in_store;
		if($rowinfo{'amount'}>=0) {
			$amt-=$rowinfo{'amount'};
		} else {
			$amt+=(-1*$rowinfo{'amount'});
		}
		$proddata->in_store($amt);

		# Don't let storage amount below 0
		if($proddata->in_store < 0) {
			$proddata->in_store(0);
		}
		goah::Modules->AddMessage('debug',"New storage value for ".$proddata->code.": ".$proddata->in_store,__FILE__,__LINE__);
		$proddata->update;
		$proddata->commit;
	}

        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	my $now = sprintf("%04d-%02d-%02d",$year+1900,$mon+1,$mday);

	use goah::Database::Referrals;
	my $refinfo = goah::Database::Referrals->retrieve($_[0]);

	$refinfo->sent($now);
	$refinfo->update();

	return 1;
}

#
# Function: DeleteReferral
#
#   Function to loop trough and delete referral and it's rows from
#   the database. This is used when invoice is converted back to basket
#
# Parameters:
#
#   id - Referral id to remove
#
# Returns:
#
#   0 - Success
#   1 - Fail
#
sub DeleteReferral {

	if($_[0]=~/goah::Modules::Referrals/) {
		shift;
	}

	unless($_[0]) {
		goah::Modules->AddMessage('error',__("Can't delete referral!")." ".__("Rererral id is missing!"));
		return 1;
	}

	use goah::Database::Referralrows;
	use goah::Modules::Basket;
	use goah::Database::Products;
	use goah::Database::Referrals;

	my $referral = goah::Database::Referrals->retrieve($_[0]);
	unless($referral) {
		goah::Modules->AddMessage('error',__("Can't delete referral!")." ".__("Couldn't read referral from database!"),__FILE__,__LINE__);
		return 1;
	}

	# Convert order into an basket
	use goah::Modules::Basket;
	if(goah::Modules::Basket->OrderToBasket($referral->orderid)) {
		goah::Modules->AddMessage('error',__("Couldn't convert order to basket!"),__FILE__,__LINE__);
		return 1;
	} else {
		#goah::Modules->AddMessage('info',__("Basket created from the order."),__FILE__,__LINE__);
	}
		
	$referral->delete;
	goah::Database::Referrals->commit;

	my @rows = goah::Database::Referralrows->search_where({ refid => $_[0]});
	my $rowpointer;
	my %rowinfo;
	foreach my $row (@rows) {

		$rowpointer = goah::Modules::Basket->ReadBasketrows(0,$row->rowid,1);
		unless($rowpointer) {
			goah::Modules->AddMessage('error',__("Couldn't read basket row with id ").$row->rowid,__FILE__,__LINE__);
			return 1;
		}
		%rowinfo = %$rowpointer;

		my $proddata = goah::Database::Products->retrieve($rowinfo{'productid'});
		my $amt = $proddata->in_store;
		if($rowinfo{'amount'}>=0) {
			$amt+=$rowinfo{'amount'};
		} else {
			$amt-=(-1*$rowinfo{'amount'});
		}
		$proddata->in_store($amt);

		# Don't let storage value below zero
		if($proddata->in_store < 0) {
			$proddata->in_store=0;
		}
		goah::Modules->AddMessage('debug',"New storage value for ".$proddata->code.": ".$proddata->in_store,__FILE__,__LINE__);
		$proddata->update;
		$proddata->commit;

		$row->delete;
		goah::Database::Referralrows->commit;
	}


	return 0;
}

1;
