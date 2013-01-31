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
# Module process is controlled with hash-variables which
# are passed from module as hashref. To work right, this
# module also needs template to process.
#
# Parameters:
#
#   Hashref from module, which should have at least basic
#   variables.
#
#   Required
#
#   to - Where to send email
#   subject - Subject of the email
#   template - Template to process
#   module - modulename where call comes from
#
# Returns:
#
#   1 for success
#   0 for fail
#

sub SendEmail {

	shift if($_[0]=~/goah::Modules::Email/);
	my %params = %{$_[0]};
	my %options;
	my $template;

	$params{'gettext'} = sub { return __($_[0]); };
	
	# Check that we have necessary values
	unless ($params{'to'}) {
		goah::Modules->AddMessage('error', __('Required value to missing'));
		return 0;			
	}

	unless ($params{'subject'}) {
		goah::Modules->AddMessage('error', __('Required value subject missing'));
		return 0;			
	}

	unless ($params{'template'}) {
		goah::Modules->AddMessage('error', __('Required value template missing'));
		return 0;			
	}

	unless ($params{'module'}) {
		goah::Modules->AddMessage('error', __('Required value module missing'));
		return 0;			
	}

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

	# Get 'from' address
    my $ownerinfo = goah::Modules::Systemsettings->ReadOwnerInfo();
    $params{'from'} = $ownerinfo->email;	

	# Process email template
	my $tt = Template->new({
    	INCLUDE_PATH => 'templates/modules/Email/',
    	EVAL_PERL    => 1,
	});

	my $message;
	$tt->process($params{'template'}, \%params, \$message);

	$params{'body'} = $message;

	# Create messageid and timestamp
	use Email::MessageID;
	$params{'messageid'} = Email::MessageID->new;
	$params{'timestamp'} = time();

	# Value for outgoing email
	$params{'type'} = '1';	

	# Save email to database.
	my $dbitem  = goah::Modules::Email->WriteEmail(\%params);
	my %dbdata  = %$dbitem;
	my $rowid   = $dbdata{'id'};

	# Create and send email
	use Email::Sender::Simple qw(sendmail);
 	use Email::Simple;
  	use Email::Simple::Creator;
	use Email::Sender::Transport::SMTP;
    use MIME::Words qw(:all);

	# Specify SMTP-connection parameters
	my $transport;
	if (($smtp_user{'value'}) && $smtp_password{'value'}){

		$transport = Email::Sender::Transport::SMTP->new({
            host            => $smtp_server{'value'},
            port            => $smtp_port{'value'},
            ssl             => $smtp_ssl{'value'},
            sasl_username   => $smtp_user{'value'}, 
            sasl_password   => $smtp_password{'value'}, 
  		});

	} else {

		$transport = Email::Sender::Transport::SMTP->new({
            host    => $smtp_server{'value'},
            port    => $smtp_port{'value'},
            ssl     => $smtp_ssl{'value'},
		});
	}

	# Put all together and process email
	my $email;
	if ($smtp_server{'value'}){
  		$email = Email::Simple->create(
            header => [
                To      => $params{'to'},
                Cc      => $params{'cc'},
                From    => $params{'from'},
                Subject => encode_mimeword($params{'subject'}, 'Q', 'utf-8'),
            ],
            body => $message,
		);

	    $email->header_set('Content-type'               => 'text/plain; charset="utf-8"');
	    $email->header_set('Content-Disposition'        => 'inline');
	    $email->header_set('Content-Transfer-Encoding'  => 'quoted-printable');
	    $email->header_set('X-GoaH-Message-Id'          => $params{'messageid'});

		# Ask confirmation for email reading?
		my $asknotify = $params{'asknotify'};
		if ($asknotify == 1) {
			$email->header_set('Disposition-Notification-To' => $params{'from'});
		}

		use Try::Tiny;
		try {
			# Send email
			sendmail($email, { transport => $transport});

			# Update database
			my %dbupdata;
			$dbupdata{'delivered'} = '1';
			goah::Modules::Email->UpdateEmail($rowid, \%dbupdata); 
			
		} catch {
			goah::Modules->AddMessage('error',"ERROR! $_");

			# Update database
			my %dbupdata;
			$dbupdata{'delivered'} = '0';
			goah::Modules::Email->UpdateEmail($rowid, \%dbupdata); 
		}
	}
}


#
# Function: WriteEmail
#
# Module saves email to database. Process is controlled with hash-variables which
# are passed as hashref from SendEmail.
#
# Parameters:
#
#   Hashref from SendEmail.
#
#   Required
#
#   from - Sender address
#   to - Where to send email
#   subject - Subject of the email
#
#
# Returns:
#
#   Hashref for added row
#

sub WriteEmail {

	use goah::Db::Email;

	shift if($_[0]=~/goah::Modules::Email/);
	my %vars = %{$_[0]};

	my %dbdata;
	$dbdata{'userid'} = $vars{'userid'};
	$dbdata{'timestamp'} = $vars{'timestamp'};
	$dbdata{'type'} = $vars{'type'};
	$dbdata{'delivered'} = $vars{'delivered'};
	$dbdata{'sender'} = $vars{'from'};
	$dbdata{'recipient'} = $vars{'to'};
	$dbdata{'cc'} = $vars{'cc'};
	$dbdata{'bcc'} = $vars{'bcc'};
	$dbdata{'subject'} = $vars{'subject'};
	$dbdata{'body'} = $vars{'body'};
	$dbdata{'attachments'} = $vars{'attachments'};
	$dbdata{'module'} = $vars{'module'};
	$dbdata{'messageid'} = $vars{'messageid'};

	my $emailitem = goah::Db::Email->new(%dbdata);
	$emailitem->save;

	return $emailitem;
	
}


#
# Function: UpdateEmail
#
# 
# Module updates selected row to database. Process is controlled with row id
# and parameters as hashref. Hashref keys must be named as Email-database columns.
#
# Parameters:
#
#   0 - Row id
#   1 -  Hashref from module.
#
#   Required
#
#   row id
#
# Returns:
#
#   1 for success
#

sub UpdateEmail {

	shift if($_[0] =~ /goah::Modules::Email/);

	my $rowid   = $_[0];
	my %vars    = %{$_[1]};

	my $emailitem = goah::Db::Email->new( id => $rowid );
	$emailitem->load;

	# Update values to database
	my $key;
	foreach $key (sort(keys %vars)) {
		$emailitem->{$key} = ($vars{$key});
	}

	$emailitem->save;
}

1;








