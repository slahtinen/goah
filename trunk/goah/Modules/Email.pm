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
# Start the actual module. Module process is controlled via
# variables which are coming from another modules.
#
# Parameters:
#
#   None
#
# Returns:
#
#   1 for success
#

sub SendEmail {

	shift if($_[0]=~/goah::Modules::Email/);
	my %var = %{$_[0]};
	my %taskstates = %{$_[1]};
	my $subject;
	my $status;
	my %params;
	my %options;
	my $template;

	# Read setup values
	my $tmp_smtp = goah::Modules::Systemsettings->ReadSetup('smtpserver_name',1);
	my $tmp_port = goah::Modules::Systemsettings->ReadSetup('smtpserver_port',1);
	my $tmp_ssl = goah::Modules::Systemsettings->ReadSetup('smtpserver_ssl',1);
	my $tmp_user = goah::Modules::Systemsettings->ReadSetup('smtpserver_username',1);
	my $tmp_password = goah::Modules::Systemsettings->ReadSetup('smtpserver_password',1);

	my %smtp_server;
	my %smtp_port;
	my %smtp_ssl;
	my %smtp_user;
	my %smtp_password;

	# Check that we have HASH. There can be situation, where HASH mot created, if that setting
	# has not been saved.
	if ($tmp_smtp) {%smtp_server=%$tmp_smtp;}
	if ($tmp_port) {%smtp_port=%$tmp_port;}
	if ($tmp_ssl) {%smtp_ssl = %$tmp_ssl;}
	if ($tmp_user) {%smtp_user=%$tmp_user;}
	if ($tmp_password) {%smtp_password=%$tmp_password;}

	# Now, check that we have some real value. If not, set default values.
	if (length($smtp_server{'value'}) < 1) {$smtp_server{'value'} = 0;}
	if (length($smtp_port{'value'}) < 1) {$smtp_port{'value'} = 25;}
	if ($smtp_ssl{'value'} != 1) {$smtp_ssl{'value'} = '0';}
	if (length($smtp_user{'value'}) < 1) {$smtp_user{'value'} = '0';}
	if (length($smtp_password{'value'}) < 1) {$smtp_password{'value'} = '0';}

	# Tasks module
	if($var{'module'} eq 'Tasks') {

		if (($var{'status'} == 3) || ($var{'status'} == 4)) {
			my $tmpstat = lc($taskstates{$var{'status'}});
			$subject = "[#$var{'taskid'}]_Task_"."$tmpstat:_"."$var{'description'}";
		} else {
			$subject = "[#$var{'taskid'}] $taskstates{$var{'status'}} task: "."$var{'description'}";
		}
		
		$subject =~ s/\s+/_/g;;

	 	# goah::Modules->AddMessage('warn',"Subject: $subject");

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

	# Process email template
	my $tt = Template->new({
    		INCLUDE_PATH => 'templates/modules/Email/',
    		EVAL_PERL    => 1,
	});

	my $message;
	$tt->process($template, \%params, \$message);

	# Create and send email
	use Email::Sender::Simple qw(sendmail);
 	use Email::Simple;
  	use Email::Simple::Creator;
	use Email::Sender::Transport::SMTP;

	# Specify SMTP-connection parameters
	my $transport;
	if (($smtp_user{'value'}) && $smtp_password{'value'}){

		$transport = Email::Sender::Transport::SMTP->new({
    			host => $smtp_server{'value'},
    			port => $smtp_port{'value'},
			ssl => $smtp_ssl{'value'},
			sasl_username => $smtp_user{'value'}, 
			sasl_password => $smtp_password{'value'}, 
  		});

	} else {

		$transport = Email::Sender::Transport::SMTP->new({
    			host => $smtp_server{'value'},
    			port => $smtp_port{'value'},
			ssl => $smtp_ssl{'value'},
		});

	}

	# Put all together and process email
	my $email;
	if ($smtp_server{'value'}){
  		$email = Email::Simple->create(
    			header => [
      			To => $var{'to'},
			Cc=> $var{'cc'},
      			From => $var{'from'},
      			Subject => "=?UTF-8?Q?".$subject."?=",
    			],
    			body => $message,
		);

		sendmail($email, { transport => $transport});

	} else {
		goah::Modules->AddMessage('error',"Sending email failed: Incorrect settings! Supported connection types are: SMTP, SMTPS (SSL) and SMTP AUTH");
	}

}

1;
