#!/usr/bin/perl -w

=begin nd

Package: goah::Modules::Email

  Module to send emails from another modules

About: License

  This software is copyritght (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Modules::Email;

use Cwd;
use Locale::TextDomain ('Email', getcwd()."/locale");

use strict;
use warnings;
use utf8;
use Encode;

#
# String: module
#
#   Defines module internal name to be used in control flow
my $module='Email';

#
# Function: SendEmail
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
#   Hash containing relevant bits for frameset generation
#

sub SendEmail {

	shift if($_[0]=~/goah::Modules::Email/);
	my $hashtmp = $_[0];
	my %var = %$hashtmp;
	my $subject;
	my %params;
	my $template;


	my $tmp=goah::Modules::Systemsettings->ReadSetup('smtpserver_name',1);
	my %tmphash=%$tmp;
	$tmp=$tmphash{'10000000'};
	my %smtpdata=%$tmp;
	my $smtpserver=$smtpdata{'value'};

	#goah::Modules->AddMessage('debug',"SMTP:"."$smtpserver".join(";",keys(%smtpdata)),__FILE__,__LINE__);

	if($var{'module'} eq 'Tasks') {

		if ($var{'status'} eq "New") {
			$subject = "New task added: "."$var{'description'}";
		} 
		if ($var{'status'} eq "Update") {
			$subject = "Task updated: "."$var{'description'}";
		} 
		if ($var{'status'} eq "Delete") {
			$subject = "Task deleted: "."$var{'description'}";
		}
		if ($var{'status'} eq "Complete") {
			$subject = "Task completed: "."$var{'description'}";
		}

        	$params{status} = $subject;
        	$params{assigneename} = $var{'assigneename'};
        	$params{description} = $var{'description'};
        	$params{longdescription} = $var{'longdescription'};

		$template = 'tasks_fi.tt2';
	}

        use MIME::Lite::TT;
        my $msg = MIME::Lite::TT->new(
		From => $var{'from'},
		To => $var{'to'},
		Cc => $var{'cc'},
		Charset => $var{'charset'},
		Subject => $subject,
		Template => './templates/modules/Email/'.$template,
		TmplParams => \%params,
        ); 

        $msg->send('smtp',$smtpserver);

}

1;
