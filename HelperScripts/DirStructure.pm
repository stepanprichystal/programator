#!/usr/bin/perl -w


#-------------------------------------------------------------------------------------------#
# Description: Create directory structure needed for runing tpv scripts
# Author:SPR
#-------------------------------------------------------------------------------------------#

package HelperScripts::DirStructure;

#3th party library
use strict;
use warnings;

#loading of locale modules
use aliased 'Helpers::GeneralHelper';

#3th party library
use strict;
use warnings;

use aliased 'Enums::EnumsPaths';

sub Create {

	unless ( -e EnumsPaths->Client_INCAMTMPSCRIPTS ) {
		mkdir( EnumsPaths->Client_INCAMTMPSCRIPTS ) or die "Can't create dir: " . EnumsPaths->Client_INCAMTMPSCRIPTS . $_;
	}

	unless ( -e EnumsPaths->Client_INCAMTMPJOBMNGR ) {
		mkdir( EnumsPaths->Client_INCAMTMPJOBMNGR ) or die "Can't create dir: " . EnumsPaths->Client_INCAMTMPJOBMNGR . $_;
	}

	unless ( -e EnumsPaths->Client_EXPORTFILES ) {
		mkdir( EnumsPaths->Client_EXPORTFILES ) or die "Can't create dir: " . EnumsPaths->Client_EXPORTFILES . $_;
	}

	unless ( -e EnumsPaths->Client_INCAMTMPAOI ) {
		mkdir( EnumsPaths->Client_INCAMTMPAOI ) or die "Can't create dir: " . EnumsPaths->Client_INCAMTMPAOI . $_;
	}

	unless ( -e EnumsPaths->Client_INCAMTMPNC ) {
		mkdir( EnumsPaths->Client_INCAMTMPNC ) or die "Can't create dir: " . EnumsPaths->Client_INCAMTMPNC . $_;
	}

	unless ( -e EnumsPaths->Client_INCAMTMPCHECKER ) {
		mkdir( EnumsPaths->Client_INCAMTMPCHECKER ) or die "Can't create dir: " . EnumsPaths->Client_INCAMTMPCHECKER . $_;
	}

	unless ( -e EnumsPaths->Client_INCAMTMPOTHER ) {
		mkdir( EnumsPaths->Client_INCAMTMPOTHER ) or die "Can't create dir: " . EnumsPaths->Client_INCAMTMPOTHER . $_;
	}
	
	unless ( -e EnumsPaths->Client_INCAMTMPLOGS ) {
		mkdir( EnumsPaths->Client_INCAMTMPLOGS ) or die "Can't create dir: " . EnumsPaths->Client_INCAMTMPLOGS . $_;
	}

}

1;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#my $self             = shift;
	#	my $inCAM            = shift;

	use aliased 'HelperScripts::DirStructure';

	DirStructure->Create();

}

1;
