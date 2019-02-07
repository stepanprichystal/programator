#-------------------------------------------------------------------------------------------#
# Description: Helper function for coupon wizard
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::InStackJob::Helper;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Stackup::Stackup::Stackup';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#
 

# Return InCAM layer name for InSIGHT layer name
sub GetInCAMLayer {
	my $self     = shift;
	my $lName    = shift;
	my $layerCnt = shift;
	
	return undef if( $lName =~ /no copper layer/i);

	die "Wrong InStack stackup layer name" if ( $lName !~ /l\d+/i  );

	my $lInCAM;

	# load copper layers
	my ($lNum) = $lName =~ /l(\d+)/i;

	if ( $lNum == 1 ) {
		$lInCAM = "c";
	}
	elsif ( $lNum == $layerCnt ) {

		$lInCAM = "s";
	}
	else {

		$lInCAM = "v" . $lNum;
	}

	return $lInCAM;
}
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

