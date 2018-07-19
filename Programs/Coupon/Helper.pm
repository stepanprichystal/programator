#-------------------------------------------------------------------------------------------#
# Description: Helper function for coupon wizard
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::Helper;

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


# Return layer naumber for InCAM layer name c= 1
sub GetLayerNum{
	my $self     = shift;
	my $layer = shift;
	my $layerCnt = shift;
	
	my $num;
	
	if ( $layer eq "c" ) {
		$num = 1;
	}
	elsif ( $layer eq "s" ) {

		$num = $layerCnt;
	}
	elsif( $layer =~ m/v(\d+)/i) {

		$num = $1;
	}else{
		
		die "Invalid layer name";
	}
	
	return $num;
}

# return all InCAM layers name by number. e.g.: layer cnt = 4, return [c, v2, v3, s]
sub GetAllLayerNames{
	my $self     = shift;
	my $layerCnt = shift;
	
	my @names =  (1..$layerCnt);
	
	@names = map { $self->GetInCAMLayer("L".$_, $layerCnt) } @names;
	
	return @names;
	
}

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

# Return InStack layer name by inCAM layer name
sub GetInStackLayer {
	my $self     = shift;
	my $lName    = shift;
	my $layerCnt = shift;
	
 
	die "Wrong InCAM stackup layer name" if ( $lName !~ /[csv]\d*/i  );

	my $lInStack;
	
	my $lNum = $self->GetLayerNum($lName, $layerCnt);

	return "L".$lNum;
}
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

