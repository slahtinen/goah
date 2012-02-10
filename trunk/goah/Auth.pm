#!/usr/bin/perl -w

=begin nd

Package: goah::Auth

  This package contains functions to handle login and session
  management.

About: License

  This software is copyright (c) 2009 by Tietovirta Oy and associates.

  See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Auth;

use strict;
use warnings;

#
# Function: CheckLogin
#
#   Function fetches username and password from the database. If
#   credientials are correct we return an UID or if they're incorrect
#   return 0.
#
# Parameters:
#
#   login - Login name
#   pass - Password
#
# Returns:
#
#  uid - Login correct, return user id
#  0 - Login failed, return 0
#
sub CheckLogin {

	my $login = $_[1];
	my $pass = $_[2];

	use Cwd;
	use Locale::TextDomain ('GoaH', getcwd()."/locale");
	use goah::Database::users;

	# Tehdään salasanasta MD5-summa ja verrataan sitä tietokannassa olevaan
	use Digest::MD5;
	my $md5 = new Digest::MD5;
	$md5->add($pass);
	my $passMD5 = $md5->hexdigest();

	my @logininfo = goah::Database::users->search( login => $login, pass => $passMD5 );

	# Mikäli annetuilla ehdoilla löytyy rivi tietokannasta kirjautuminen on ok,
	# muuten ei.
	if(@logininfo >= 1) {
		if($logininfo[0]->disabled) {
			return -1;
		}
                return $logininfo[0]->accountid;
	} else {
		@logininfo = goah::Database::users->search( login => $login, pass => $pass );
		if(@logininfo >= 1) {
			if($logininfo[0]->disabled eq '1') {
				return -1;
			}
			goah::Modules->AddMessage('warn',__("Your password is stored in unencrypted format. Please change password."));
			return $logininfo[0]->accountid;
		} else {
			return 0;
		}
	}
}


#
# Function: CreateSessionid
#
#   Function creates an session id which is stored to database (and into
#   user's cookie). Session id is stored to database automatically.
#
# Parameters:
#
#   uid - User id
#
# Returns:
#
#   sessid - Session id stored to database
#
sub CreateSessionid {

	my $uid = $_[1];

	# Create session id from random number, remote address and user id
	use Digest::MD5;
	my $md5 = new Digest::MD5;
	$md5->add($uid.$ENV{'REMOTE_ADDR'});
	my $id = $md5->hexdigest;
	
	# Search user id from the database
	use goah::Database::users;
	my @user = goah::Database::users->search(accountid => $uid);

	unless(scalar(@user)) {
		goah::Modules->AddMessage('error',__("Can't read session data from the database!"));
		return -1;
	}

	my $u=$user[0];

	if($u->get('disabled')) {
		if($user[0]->disabled == 1) {
			return -1;
		}
	}
	# Store created session id and other information into database
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$user[0]->set('last_active' => sprintf("%04d-%02d-%02d %02d:%02d:%02d",$year+1900,$mon+1,$mday,$hour,$min,$sec));

	$user[0]->session_id($id);
	$user[0]->remote_addr($ENV{'REMOTE_ADDR'});
	$user[0]->update();

	return $id;
}

#
# Function: DestroySessionid
#
#   Destroy existing session id from database on logout
#
# Parameters:
#
#   uid - User id
#
# Returns:
#
#   0 - Fail
#   1 - Success
#
sub DestroySessionid {

	my $uid=$_[1];

	# Search user id from the database
	use goah::Database::users;
	my @user = goah::Database::users->search(accountid => $uid);

	$user[0]->session_id('');
	$user[0]->remote_addr('');
	$user[0]->update();
	$user[0]->commit();

	return 1;
}

#
# Function: CheckSessionid
#
#   Function checks if session id and uid are valid. 
#
# Parameters:
#
#   uid - User id to check against
#   sessionid - Session id to check against
#
# Returns:
#
#   1 - Session id is valid and login is ok
#   0 - Session id and uid doesn't match
#
sub CheckSessionid {
	
	my $uid = $_[1];
	my $sessid = $_[2];

	use goah::Database::users;
	my @logininfo = goah::Database::users->search(accountid => $uid, session_id => $sessid);

	# If given parameters return an line from the database login is vaid. 
	if(@logininfo >= 1) {
		if ($logininfo[0]->disabled) {
			$logininfo[0]->session_id('');
			return -2;
		}
		return 1;
	} else {
		return 0;
	}
}

1;
