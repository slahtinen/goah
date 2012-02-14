#!/usr/bin/perl -w 

=begin nd

Package: goah::Database::Companies

Database definition for companies used by GoaH. This database
stores both customer and owner information.

About: License

This software is copyritght (c) 2009 by Tietovirta Oy and associates.

See LICENSE and COPYRIGHT -files for full details.

=cut

package goah::Database::Companies;
use base 'goah::Database';

use strict;
use utf8;
use warnings;

goah::Database::Companies->table('Companies');
goah::Database::Companies->columns(All => qw/id vat_id name custtype payment_condition delay_interest reclamation_time www bank_accounts isowner description hidden firstname customerreference/);  

1;
