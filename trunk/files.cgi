#!/usr/bin/perl -w

=begin nd

Script: files.cgi

  An script to handle file management from GoaH. Basically this script
  is an modified version of index.cgi -file.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.
  See LICENSE and COPYRIGHT -files for full details.

=cut


use CGI::Carp qw(fatalsToBrowser);

use strict;
use warnings;
use utf8;

use CGI qw(:standard);
use Template;
use File::Util;

use lib qw(.);
use goah::Auth;

use POSIX;

use Locale::TextDomain ('GoaH', getcwd()."/locale");

my $uid=0;
my $sessid;
my $auth=0;

my $q = new CGI;

# Read information from cookie, and check session id.
my $cookie = $q->cookie('goah');
if($cookie && length($cookie)>1) {
        my @tmp = split(/\./,$cookie);
        $uid = $tmp[0];
        $sessid = $tmp[1];
        $auth = goah::Auth->CheckSessionid($uid,$sessid);
} 

# If login isn't valid let's check if user has given login/password information.
# This check is made only if login isn't validated earlier
if($auth == 0) {

	# Check if user has given information and make sure they're not empty
	if($q->param('user') && $q->param('pass')) {
			
		# Check input values
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

# We're logged in to system
if($auth==1) {

        my %params;
        $params{'gettext'} = sub { return __($_[0]); };
        $params{'userid'} = $uid;
        $params{'module'} = $q->param('module');
        $params{'file'} = $q->param('file');
        $params{'info'} = $q->param('info');
        $params{'action'} = $q->param('action');
        $params{'target_id'} = $q->param('target_id');

	# Get defaults from config file
	my $cref = goah::GoaH->GetConfig;
	my %conf = %$cref;
	$params{'dir'} = $conf{'files.data_dir'};
	$params{'max_upload'} = $conf{'files.max_upload'};
	
	# Get return url to open after file operation
	my $tmp_url = referer();
	my @url = split('&files_action', $tmp_url);
	$params{'url'} = $url[0];

        if ($params{'action'} eq 'upload') {
                FileUpload(\%params);
        }

	if ($params{'action'} eq 'download') {
		FileDownload(\%params);
	}
	
	#
	# Function: FileUpload
	#
	# Module for file upload. Process is controlled with hash-variables
	# which are passed as hashref from another module.
	#
	# Parameters:
	#
	#   Hashref
	#
	#   Required
	#
	#   userid - User id of user who made upload
	#   file - Filename
	#   module - Module name for directory
	#   target_id - Name for subdirectory
	#
	# Returns:
	#
	#   1 for success
	#

	sub FileUpload {

		use Data::UUID;
		use File::MimeInfo;
		
        	my %vars = %{$_[0]};
		my $url;

		# Check that we have necessary variables
		unless ($vars{'dir'}) { 
			$url = $vars{'url'}.'&files_action=upload&status=error&msg=data_directory_not_specified';
			die print redirect($url);
		}

		unless ($vars{'userid'}) { 
			$url = $vars{'url'}.'&files_action=upload&status=error&msg=userid_missing';
			die print redirect($url);
		}
		
		unless ($vars{'file'}) { 
			$url = $vars{'url'}.'&files_action=upload&status=error&msg=select_file_to_upload';
			die print redirect($url);
		}

		unless ($vars{'target_id'}) { 
			$url = $vars{'url'}.'&files_action=upload&status=error&msg=targetid_missing';
			die print redirect($url);
		}

		# File and directory
		my $dir = "$vars{'dir'}/$vars{'module'}";
		my $subdir = $vars{'target_id'};
		my $file = $vars{'file'};

		# Split filename to get extension
		my @tmp = split('\.', $file, 2);

		# Generate unique filename
		my $ug = new Data::UUID;
		my $newfile = $ug->create_b64();
		$newfile =~ s/[^A-Za-z0-9]//g;
		$newfile = $newfile.'.'.$tmp[1];

		# Check does module have directory
		unless (-e $dir){
			mkdir $dir or die "$!";
		}

		# Module subdirectory
		unless (-e "$dir/$subdir"){
			mkdir "$dir/$subdir" or die "$!";
		}

		# Upload file
		my $upload_fh = $q->upload("file");

		open ( UPFILE, ">$dir/$subdir/$file" ) or die "$!";
		binmode UPFILE;

		while ( <$upload_fh> ) {
			print UPFILE;
		}

		close UPFILE;

		# Change filename
		rename("$dir/$subdir/$file", "$dir/$subdir/$newfile");

		# Get MIME-Type
		$vars{'mimetype'} = mimetype("$dir/$subdir/$newfile");

		# Get date
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);

		# Add file information to database
		my %dbvars;
		$dbvars{'userid'} = $vars{'userid'};
		$dbvars{'moduleid'} = $vars{'target_id'};
        	$dbvars{'date'} = sprintf("%04d-%02d-%02d %02d:%02d:%02d",$year+1900,$mon+1,$mday,$hour,$min,$sec);
		$dbvars{'mimetype'} = $vars{'mimetype'};
		$dbvars{'datadir'} = "$dir/$subdir";
		$dbvars{'int_filename'} = $newfile;
		$dbvars{'orig_filename'} = $file;
		$dbvars{'status'} = 1;
		$dbvars{'info'} = $vars{'info'};
		$dbvars{'module'} = $vars{'module'};

		use goah::Db::Files;
		my $filesitem = goah::Db::Files->new(%dbvars);
		$filesitem->save;

		$url = $vars{'url'}.'&files_action=upload&status=success';
		print redirect($url);
	
		
	}
	
	#
	# Function: FileDownload
	#
	# Module for download file. Process is controlled with hash-variables
	# which are passed as hashref from another module.
	#
	# Parameters:
	#
	#   Hashref
	#
	#   Required
	#
	#   userid - User id of user who requests file
	#   file - Filename
	#
	# Returns:
	#
	#   1 for success
	#

	sub FileDownload {
		
		my %vars = %{$_[0]};
		my $file = $vars{'file'};

		use goah::Modules::Files;
		my $filerow_ref = goah::Modules::Files->GetFileRows('',$file);
		my %dbdata = %$filerow_ref;
 
		# File and directory
		my $dir = $dbdata{'datadir'};
		my $orig_filename = $dbdata{'orig_filename'};

   		open(my $DOWNFILE, '<', "$dir/$file") or return(0);
 
   		print $q->header(
			-type => 'application/x-download',
                    	-attachment => $orig_filename,
                    	-Content_length => -s "$dir/$file",
   		);
 
   		binmode $DOWNFILE;
   		print while <$DOWNFILE>;
  		undef ($DOWNFILE);

		close DOWNFILE;
	}



} else {
	# Normal login
	print header( -charset => 'UTF-8');
	print "<h1>NOT LOGGED IN!</h1>\n";
}

1;


