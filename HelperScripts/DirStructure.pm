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

	my @dirs = ();

	push( @dirs, EnumsPaths->Client_INCAMTMP );
	push( @dirs, EnumsPaths->Client_INCAMTMPSCRIPTS );
	push( @dirs, EnumsPaths->Client_INCAMTMPJOBMNGR );
	push( @dirs, EnumsPaths->Client_EXPORTFILES );
	push( @dirs, EnumsPaths->Client_INCAMTMPAOI );
	push( @dirs, EnumsPaths->Client_INCAMTMPNC );
	push( @dirs, EnumsPaths->Client_INCAMTMPCHECKER );
	push( @dirs, EnumsPaths->Client_INCAMTMPOTHER );
	push( @dirs, EnumsPaths->Client_INCAMTMPLOGS );
	push( @dirs, EnumsPaths->Jobs_EXPORT );
	push( @dirs, EnumsPaths->Jobs_EXPORTFILES );
	push( @dirs, EnumsPaths->Jobs_EXPORTFILESPCB );
	push( @dirs, EnumsPaths->Jobs_EXPORTFILESPOOL );


	foreach my $dir (@dirs) {

		unless ( -e $dir ) {
			mkdir($dir) or die "Can't create dir: " . $dir . $_;
		}

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
