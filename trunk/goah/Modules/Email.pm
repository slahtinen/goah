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
	my $hashtmp2 = $_[1];
	my %taskstates = %$hashtmp2;
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
	
	my %smtp_server=%$tmp_smtp;
	my %smtp_port=%$tmp_port;
	my %smtp_ssl=%$tmp_ssl;
	my %smtp_user=%$tmp_user;
	my %smtp_password=%$tmp_password;

	# goah::Modules->AddMessage('warn',"SERVER: $smtp_server PORT: $smtp_port SSL: $smtp_ssl USER: $smtp_username PASS: $smtp_password");

	if($var{'module'} eq 'Tasks') {

		if (($var{'status'} == 3) || ($var{'status'} == 4)) {
			my $tmpstat = lc($taskstates{$var{'status'}});
			$subject = "[#$var{'taskid'}] Task $tmpstat: "."$var{'description'}";
		} else {
			$subject = "[#$var{'taskid'}] $taskstates{$var{'status'}} task: "."$var{'description'}";
		}

        	$params{status} = $taskstates{$var{'status'}};
        	$params{taskid} = $var{'taskid'};
        	$params{customername} = $var{'customername'};
        	$params{assigneename} = $var{'assigneename'};
        	$params{creatorname} = $var{'creatorname'};
        	$params{description} = $var{'description'};
        	$params{longdescription} = $var{'longdescription'};
        	$params{gettext} = sub { return __($_[0]); };

		$template = 'tasks.tt2';
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
	if ($smtp_ssl{'value'} == 1) {
		use Net::SMTP::SSL;
		my $smtp = Net::SMTP::SSL->new($smtp_server{'value'}, Port=>$smtp_port{'value'}) or die "Can't connect";
			$smtp->auth($smtp_user{'value'}, $smtp_password{'value'});
			$smtp->mail($var{'from'});
			$smtp->to($var{'to'});
			$smtp->cc($var{'cc'});
			$smtp->data();
			$smtp->datasend($msg->as_string);
			$smtp->dataend();
			$smtp->quit();
	} else {
        	$msg->send('smtp',$smtp_server{'value'});
	}
}

1;
