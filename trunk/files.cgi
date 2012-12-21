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
        $params{'row_id'} = $q->param('row_id');
        $params{'customerid'} = $q->param('customerid');

	# Get defaults from config file
	my $cref = goah::GoaH->GetConfig;
	my %conf = %$cref;
	$params{'dir'} = $conf{'files.data_dir'};
	$params{'max_upload'} = $conf{'files.max_upload'};
	
	# Get return url to open after file operation
	my $tmp_url = referer();

	# Split url, so we dont have same url many times after multiple uploads
	my @url = split('&files_action', $tmp_url);
	$params{'url'} = $url[0];

        if ($params{'action'} eq 'upload') {
                FileUpload(\%params);
        }

	if ($params{'action'} eq 'download') {
		FileDownload(\%params);
	}

	if ($params{'action'} eq 'delete') {
		FileDelete(\%params);
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
	#   customerid - Customers id
	#
	# Returns:
	#
	#   1 for success
	#

	sub FileUpload {

		use Data::UUID;
		
        	my %vars = %{$_[0]};
		my $url;

		# Put module to another variable, so we can preserve real information even if 
		# call comes directly from Files.pm (which case we need to change it).
		my $email_module = $vars{'module'};

		# If we are uploading directly from files module, then only option for upload
		# is upload for specified customer to Customermanagement module.
		if ($vars{'module'} eq 'Files') {
			$vars{'target_id'} = $vars{'customerid'};	
			$vars{'module'} = 'Customermanagement';
		}

		# Check that we have necessary variables and manage errors.
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

		if (!($vars{'customerid'}) || ($vars{'customerid'} eq 'not_selected')) { 
			$url = $vars{'url'}.'&files_action=upload&status=error&msg=customerid_missing';
			die print redirect($url);
		}

		# Directory and file
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

		# Check if module have directory. If not, create it
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
		use File::Type;
		my $ft = File::Type->new();
		$vars{'mimetype'} = $ft->checktype_filename("$dir/$subdir/$newfile");

		# Get date
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);

		# Add file information to database
		my %dbvars;
		$dbvars{'userid'} = $vars{'userid'};
		$dbvars{'target_id'} = $vars{'target_id'};
        	$dbvars{'date'} = sprintf("%04d-%02d-%02d %02d:%02d:%02d",$year+1900,$mon+1,$mday,$hour,$min,$sec);
		$dbvars{'mimetype'} = $vars{'mimetype'};
		$dbvars{'datadir'} = "$dir/$subdir";
		$dbvars{'int_filename'} = $newfile;
		$dbvars{'orig_filename'} = $file;
		$dbvars{'status'} = 1;
		$dbvars{'info'} = $vars{'info'};
		$dbvars{'module'} = $vars{'module'};
		$dbvars{'customerid'} = $vars{'customerid'};

		use goah::Db::Files;
		my $filesitem = goah::Db::Files->new(%dbvars);
		my $dbsave = $filesitem->save;

		# Send email if notify option is selected
		if ($q->param('notify_goah_users') eq 'on') {

                	# Get company name
                    	my (%companyinfo,$company_ref);
                       	if ($vars{'customerid'}) {
                   		$company_ref = goah::Modules::Customermanagement->ReadCompanydata($vars{'customerid'},1);
                    	}

                    	unless ($company_ref == 0) {
                  		%companyinfo = %$company_ref;
                    	}
	
			my $companyname;
			if ($companyinfo{'vat_id'} eq '00000000') {
				$companyname = $companyinfo{'name'}.' '.$companyinfo{'firstname'};
			} else {
				$companyname = $companyinfo{'name'};
			}

			# Get GoaH internal users email-addresses
			use goah::Modules::Systemsettings;
			my $g_user_ref = goah::Modules::Systemsettings->ReadOwnerPersonnel;
			my %g_users = %$g_user_ref;

			my $email_to;
			foreach my $key (keys %g_users) {
				$email_to = $g_users{$key}{'email'}.','.$email_to;
			}
			chop $email_to;

			# Fix url if we are coming from index.cgi
			my $email_url = $vars{'url'};
			$email_url =~ s/index\.cgi/files\.cgi/;

			# Generate and send email
             		my %emailvars;
            		$emailvars{'to'} = $email_to;
            		$emailvars{'subject'} = __('New file').': '.$file;
            		$emailvars{'orig_filename'} = $file;
             		$emailvars{'action'} = 'File '.$vars{'action'};
              		$emailvars{'info'} = $vars{'info'};
             		$emailvars{'template'} = 'files.tt2';
             		$emailvars{'companyname'} = $companyname;
			$emailvars{'date'} = goah::GoaH->FormatDate($filesitem->date);
			$emailvars{'url'} = $email_url.'&action=download&file='.$newfile;
			$emailvars{'module'} = $email_module;

	       	 	# Check that we have smtp-server specified before trying to send email
        		my $tmp_smtp = goah::Modules::Systemsettings->ReadSetup('smtpserver_name',1);
        		my %smtp_server = %$tmp_smtp;

        		use Try::Tiny;
        		if ($tmp_smtp) {
                		my $tmp = $smtp_server{'value'};
                		if (length($tmp) > 3) {
                        		try {
                                		use goah::Modules::Email;
                                		my $email = goah::Modules::Email->SendEmail(\%emailvars);
				
						if ($email == 0) {
							$url = $vars{'url'}.'&files_action=upload&status=error&msg=sending_email_failed_but_file_added_succesfully';
							die print redirect($url);
						}
                        		} catch {
						$url = $vars{'url'}.'&files_action=upload&status=error&msg=sending_email_failed_but_file_added_succesfully';
						die print redirect($url);
                        		}
                		}	
        		}
		}
		
		# Redirect back
		$url = $vars{'url'}.'&files_action=upload&status=success';
		print redirect($url);
	
		
	}
	
	#
	# Function: FileDownload
	#
	# Module for download file. Process is controlled with hash-variables
	# which are passed as hashref.
	#
	# Parameters:
	#
	#   Hashref
	#
	#   Required
	#
	#   userid - User id of user who requests file
	#   file - Internal filename (int_filename)
	#
	# Returns:
	#
	#   1 for success
	#

	sub FileDownload {
		
		my %vars = %{$_[0]};
		my $file = $vars{'file'};
		my $target_id = $vars{'target_id'};

		use goah::Modules::Files;
		my $filerow_ref;

		#  only specified file
		if (($file) && !($target_id)) {
			$filerow_ref = goah::Modules::Files->GetFileRows('',$file);
		}

		# Return all files with id. 
		# Commented out, atleast for now, because there ain't currently any reason why 
		# files.cgi should handle more than one file per action.
		#
		# if (($target_id) && !($file)) {
		# 	$filerow_ref = goah::Modules::Files->GetFileRows($target_id,'');
		# }

		unless ($filerow_ref) {
			# Redirect an case of error. For now, this handles only internal calls from module.
			# For getting error message out, module should have some function to parse status and msg.
			my $url = $vars{'url'}.'&files_action=download&status=error&msg=file_not_found';
			print redirect($url);
		}

		my %dbdata = %$filerow_ref;

		# File and directory
		my $dir = $dbdata{'datadir'};
		my $orig_filename = $dbdata{'orig_filename'};

   		open(my $DOWNFILE, '<', "$dir/$file") or die "$!";
 
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


	#
	# Function: FileDelete
	#
	# Module for file delete. Process is controlled with hash-variables
	# which are passed as hashref.
	#
	# Parameters:
	#
	#   Hashref
	#
	#   Required
	#
	#   userid - User id of user who requests file
	#   file - Internal filename (int_filename)
	#   rowid - Database row id
	#
	# Returns:
	#
	#   1 for success
	#

	sub FileDelete {

		my %vars = %{$_[0]};
		my $row_id = $vars{'row_id'};
		my $int_filename = $vars{'file'};
		my $url;

		# Check that we have necessary variables
		unless ($vars{'userid'}) { 
			$url = $vars{'url'}.'&files_action=delete&status=error&msg=userid_missing';
			die print redirect($url);
		}
		
		unless ($vars{'file'}) { 
			$url = $vars{'url'}.'&files_action=delete&status=error&msg=select_file_to_upload';
			die print redirect($url);
		}

		unless ($vars{'row_id'}) { 
			$url = $vars{'url'}.'&files_action=delete&status=error&msg=rowid_missing';
			die print redirect($url);
		}

		my $del_ref = goah::Modules::Files->DeleteFileRows($row_id,$int_filename);
		my %del = %$del_ref;
 
		$url = $vars{'url'}.'&files_action=delete&status=success';
		print redirect($url);
	}

} else {
	# Normal login
	print header( -charset => 'UTF-8');
	print "<h1>NOT LOGGED IN!</h1>\n";
}

1;


