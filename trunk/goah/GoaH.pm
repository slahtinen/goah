#!/usr/bin/perl -w

=begin nd

Package: goah::GoaH

  General helper functions to format numbers, dates etc.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.
  See LICENSE and COPYRIGHT -files for full details.

=cut


package goah::GoaH;

use Cwd;
use Locale::TextDomain ('GoaH_GoaH', getcwd()."/locale");

use strict;
use warnings;

#
# Function: SetConfig
#
#   Initialise %Config -variable with default
#   location & options
#
# Parameters: 
#
#   None
#
# Returns:
#
#   0
#
sub SetConfig {

	# Read Configuration file, currently the location of config
	# file is hardcoded.
	unless(-e '/etc/goah.conf') {
		print "Content-type: text/html\n\n";
		print "<h1>Configuration file missing at /etc/goah.conf. Aborting.</h1>";
		exit;
	}

	use Config::Simple;
	Config::Simple->import_from('/etc/goah.conf',\%goah::GoaH::Config);
}

#
# Function: GetConfig
#
#   Return previously read Config hashref
#
# Parameters:
#
#   None
#
# Returns:
#
#   href - Hash reference to %Config
#
sub GetConfig {
	SetConfig;
	return \%goah::GoaH::Config;
}


# 
# Function: FormatCurrency
#
#   Function to format number format properly. 
#
#   *This function will take care of VAT0/Incl. VAT calculations etc. later on
#   so don't misuse this one!*
#
# Parameters:
#
#   num - Number to format
#   vat - Vat% to use in calculations. If omitted defaults to 0
#   uid - User id who's using GoaH so that we can assign VAT correctly. If omitted defaults not to include VAT
#   direction - in or out. Decides wether VAT is added or subtracted from amount. Defaults as out.
#   settings reference - Reference to user settings hash
#   decimal numbers - How many decimals to return, if omitted uses automatic algorithm
#
# Returns:
#  
#   Fail - 0 
#   Success - Formatted number as a string
#
sub FormatCurrency {

	shift if ($_[0]=~/goah::GoaH/);

	unless(length($_[0])) {
		goah::Modules->AddMessage('debug',__('No number to reformat.'),__FILE__,__LINE__,caller());
		return 0;
	}

	unless($_[0]=~/^-?([0-9\,\.\ ]+)$/) {
		if($_[0] eq '') {
			return 0;
		}
		goah::Modules->AddMessage('error',__('No number to reformat. Got '.$_[0]),__FILE__,__LINE__);
		return 0;
	}

	$_[0]=~s/,/\./g;
	$_[0]=~s/\ //g;


	goah::Modules->AddMessage('debug',"FormatCurrency called, this shouldn't happen anymore.",__FILE__,__LINE__,caller());

	my $vat=1; # Even if we set up VAT% as 0% we still need to use 1 as an multiplier
	unless ($_[1]=~/^[0-9\.\ ]+$/) {
		goah::Modules->AddMessage('error',__("Incorrectly formatted VAT% (".$_[1]."). Reverting to 0."),__FILE__,__LINE__);
	} else {
		unless($_[1]==0) {
			$vat = ($_[1]/100)+1;
		}
	}

	my $set;
	unless($_[4] && $_[2] != -1) {
		goah::Modules->AddMessage('debug',__("Slow version of FormatCurrency called"),__FILE__,__LINE__,caller());
		use goah::Modules::Personalsettings;
		$set = goah::Modules::Personalsettings->ReadSettings($_[2]);
	} else {
		if($_[2]==-1) {
			$set=0;
		} else {
			$set=$_[4];
		}
	}
	my %settings;
	unless($set==0 && $_[2] != -1) {
		%settings = %$set;

		# Check if user wants to see prices with VAT. If not then revert VAT-multiplier to 1.
		unless($settings{'showvat'} eq 'on') {
			$vat = 1;
		}
	} else {
		goah::Modules->AddMessage('warn',__("Couldn't read settings. Defaulting to VAT0%."),__FILE__,__LINE__);
		$vat = 1;
	}


	my $ret;
	if($_[3] && $_[3] eq 'in') {
		$ret = sprintf("%.05f",($_[0]/$vat) );
	} else {

		my $format = "%.03f";
		$format=".02f" if($vat!=1);
		
		# Override decimals from parameter
		if($_[5]) {
			$format="%.0".$_[5]."f";
		}

		# Ignoring user settings atleast temporarily, since
		# they don't apply everywhere it kind of makes the whole 
		# thing pointless
		#if($settings{'decimals'} && $settings{'decimals'} > 0) {
		#	$format = "%.0".$settings{'decimals'}."f";
		#}
		$ret = sprintf($format,($_[0]*$vat) );
	}

	return $ret;
}


#
# Function: FormatCurrencyNopref
#
#   Alternative function for currency formatting. This is used when there's need to format 
#   currency with/without vat regardless of the user's preference
#
# Parameters:
#
#   num - Number to format
#   vat - Vat% to use in calculations. If omitted defaults to 0
#   includevat - Tells if number to format already contains VAT
#   direction - In or out, Decides wether VAT is added or subtracted from amount. Defaults as out.
#   returnwithvat - If set to 1 include VAT in outgoing number 
#   decimals - How many decimals to show. If omitted returns decimals via automated algorithm
#
sub FormatCurrencyNopref {

	if($_[0]=~/goah::GoaH/) {
		shift;
	}

	unless ($_[0]) { 
		if(length($_[0])>0) {
			if($_[3] && $_[3] eq 'out') {
				if($_[4] && $_[4]==1) {
					return "0.00";
				} else {
					return "0.000";
				}
			}
			return "0";
		}
		goah::Modules->AddMessage('error',__('No number to reformat at all.'),__FILE__,__LINE__,caller());
		return 0;
	}

	unless ($_[0]=~/^-?([0-9\,\.\ ]+)$/) {
		goah::Modules->AddMessage('error',__('No number to reformat. Got '.$_[0]),__FILE__,__LINE__);	
		return 0;
	}

	$_[0]=~s/,/\./g;
	$_[0]=~s/\ //g;

	my $vat=1; # Even if we set up VAT% as 0% we still need to use 1 as an multiplier
	unless ($_[1]=~/^[0-9\.\ ]+$/) {
		goah::Modules->AddMessage('error',__("Incorrectly formatted VAT% (".$_[1]."). Reverting to 0."),__FILE__,__LINE__);
	} else {
		unless($_[1]==0) {
			$vat = ($_[1]/100)+1;
		}
	}

	my $sum=$_[0];
	if($_[2]=~/^([0-9])+$/ && $_[2] == 1) {
		goah::Modules->AddMessage('debug',"Removing VAT from amount",__FILE__,__LINE__);
		$sum=$sum/$vat;
	}


	#goah::Modules->AddMessage('debug',"Formatting number ".$_[0]." vat $vat",__FILE__,__LINE__);

	my $ret;
	if($_[3] && $_[3] eq 'in') {
		$ret = sprintf("%.05f",($_[0]/$vat));
	} else {
		my $format;
		my $sum;
		if($_[4] && $_[4]==1) {
			$format = "%.02f";
			$sum = $_[0]*$vat;
			#goah::Modules->AddMessage('debug',"Returning $ret from ".$_[0]*$vat,__FILE__,__LINE__);
		} else {
			$format = "%.03f";
			$sum = $_[0];
			#goah::Modules->AddMessage('debug',"Number $ret passed trough",__FILE__,__LINE__,caller());
		}
		if($_[5]) {
			$format = "%.0".$_[5]."f";
		}

		$ret=sprintf($format,$sum);
	}

	return $ret;
}
		
#
# Function: FormatDate
#
#   Function to format date and time properly.
#
# Parameters:
#
#   date - Date from sql database OR date in 'dd.mm.yyyy hh:ii:ss' -format
#   format - Optional. Define which format to return. Currently only supported format is unixtime.
#
# Returns:
#
#   Fail - 0
#   Success - Date formatted in user preferences or in SQL-format (YYYY-MM-DD)
#
sub FormatDate {

	if($_[0]=~/goah::GoaH/) {
		shift;
	}

	unless($_[0]) {
		goah::Modules->AddMessage('error',__("No date to reformat"),__FILE__,__LINE__,caller());
		return 0;
	}

	# With timestamp
	if($_[0]=~/[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}/) {
		my @tmp = split(/ /,$_[0]);
		my @date = split(/-/,$tmp[0]);
		my @time = split(/:/,$tmp[1]);

		if($_[1] && $_[1] eq 'unix') {
			use DateTime;
			my $dt=DateTime->new( 	year => $date[0],
						month => $date[1],
						day => $date[2],
						hour => $time[0],
						minute => $time[1],
						second => $time[2]);
			return $dt->epoch;

		}
		return $date[2].'.'.$date[1].'.'.$date[0].' '.$time[0].':'.$time[1];

	} elsif ($_[0]=~/[0-9]{4}-[0-9]{2}-[0-9]{2}/) {
		# Without timestamp
		my @date = split(/-/,$_[0]);
		return $date[2].'.'.$date[1].'.'.$date[0];
	} elsif ($_[0]=~/[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{4}/) {
		my @date = split(/\./,$_[0]);

		# Check that there's reasonable month
		if($date[1]>12) {
			goah::Modules->AddMessage('warn',__("There's only 12 months in year!"));
			$date[1]=12;
		}
	
		# Check and override given value if date is bigger than there's days in 
		# current month.
		use Date::Calc;
		my $days_in_month=Date::Calc::Days_in_Month(sprintf("%04d",$date[2]),sprintf("%02d",$date[1]));
		if($date[0]>$days_in_month) {
			goah::Modules->AddMessage('warn',__("Given day is bigger than there's days in given month."));
			$date[0]=$days_in_month;
		}

		return sprintf("%04d-%02d-%02d",$date[2],$date[1],$date[0]);
	} else {
		goah::Modules->AddMessage('error',__("Given variable isn't in supported format"),__FILE__,__LINE__);
		return 0;
	}

}


#
# Function: ReadLanguages
#
#   Read available languages so that user can choose used
#   language for user interface.
#
# About: TODO
#   
#   This function really doesn't read any available languages
#   but it just returns an pre-defined hash as a proof of consept.
#
# Parameters:
#
#   None
#
# Returns:
#
#   Hash reference for available languages
#
sub ReadLanguages {

	my %lang = (    fi => { locale => 'fi_FI.UTF-8', language => 'Suomi' },
			en => { locale => 'en_US.UTF-8', language => 'English' }
	);

	return \%lang;
}


1;
