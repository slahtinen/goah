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
	my $status;
	my %params;
	my %options;
	my $template;

	# Get SMTP values. This really need to be fixed after we have some better
	# way to get data from Systemsettings. Ugly, but necessary.

	my $tmp_smtp = goah::Modules::Systemsettings->ReadSetup('smtpserver_name',1);
	my $tmp_port = goah::Modules::Systemsettings->ReadSetup('smtpserver_port',1);
	my $tmp_ssl = goah::Modules::Systemsettings->ReadSetup('smtpserver_ssl',1);
	my $tmp_user = goah::Modules::Systemsettings->ReadSetup('smtpserver_username',1);
	my $tmp_password = goah::Modules::Systemsettings->ReadSetup('smtpserver_password',1);
	
	my $smtp_server;
	if ($tmp_smtp) {
		my %tmphash=%$tmp_smtp;
		$tmp_smtp=$tmphash{'10000000'};
		my %smtpdata=%$tmp_smtp;
		$smtp_server=$smtpdata{'value'};
	}

	my $smtp_port;
	if ($tmp_port) {
		my %tmphash=%$tmp_port;
		$tmp_port=$tmphash{'10000000'};
		my %smtpdata=%$tmp_port;
		$smtp_port=$smtpdata{'value'};
	}

	my $smtp_ssl;
	if ($tmp_ssl) {
		my %tmphash=%$tmp_ssl;
		$tmp_ssl=$tmphash{'10000000'};
		my %smtpdata=%$tmp_ssl;
		$smtp_ssl=$smtpdata{'value'};
	}

	my $smtp_username;
	if ($tmp_user) {
		my %tmphash=%$tmp_user;
		$tmp_user=$tmphash{'10000000'};
		my %smtpdata=%$tmp_user;
		$smtp_username=$smtpdata{'value'};
	}

	my $smtp_password;
	if ($tmp_password) {
		my %tmphash=%$tmp_password;
		$tmp_password=$tmphash{'10000000'};
		my %smtpdata=%$tmp_password;
		$smtp_password=$smtpdata{'value'};
	}

	# goah::Modules->AddMessage('warn',"SERVER: $smtp_server PORT: $smtp_port SSL: $smtp_ssl USER: $smtp_username PASS: $smtp_password");

	if($var{'module'} eq 'Tasks') {

		if ($var{'status'} eq "New") {
			$subject = "[#$var{'taskid'}] New task added: "."$var{'description'}";
			$status = "New task";
		} 
		if ($var{'status'} eq "Update") {
			$subject = "[#$var{'taskid'}] Task updated: "."$var{'description'}";
			$status = "Task updated";
		} 
		if ($var{'status'} eq "Complete") {
			$subject = "[#$var{'taskid'}] Task completed: "."$var{'description'}";
			$status = "Task closed";
		}

        	$params{status} = $status;
        	$params{taskid} = $var{'taskid'};
        	$params{customername} = $var{'customername'};
        	$params{assigneename} = $var{'assigneename'};
        	$params{creatorname} = $var{'creatorname'};
        	$params{description} = $var{'description'};
        	$params{longdescription} = $var{'longdescription'};
        	$params{gettext} = sub { return __($_[0]); };

		$template = 'tasks_fi.tt2';
	}
	
        use MIME::Lite::TT;

	$options{INCLUDE_PATH} = 'templates/modules/Email/';

        my $msg = MIME::Lite::TT->new(
		From => $var{'from'},
		To => $var{'to'},
		Cc => $var{'cc'},
		Charset => $var{'charset'},
		Subject => $subject,
		Template => $template,
		TmplOptions => \%options,
		TmplParams => \%params,
        ); 

	# Send email
	if ($smtp_ssl == 1) {
		use Net::SMTP::SSL;
		my $smtp = Net::SMTP::SSL->new($smtp_server, Port=>$smtp_port) or die "Can't connect";
			$smtp->auth($smtp_username, $smtp_password);
			$smtp->mail($var{'from'});
			$smtp->to($var{'to'});
			$smtp->cc($var{'cc'});
			$smtp->data();
			$smtp->datasend($msg->as_string);
			$smtp->dataend();
			$smtp->quit();
	} else {
        	$msg->send('smtp',$smtp_server);
	}
}

1;
