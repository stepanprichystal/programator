#-------------------------------------------------------------------------------------------#
# Description: Do checks of tool in Universal DTM
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::UniRTM::UniRTMCheck;

#3th party library
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamDTM';
use aliased 'CamHelpers::CamDTMSurf';

use aliased 'Packages::CAM::UniDTM::Enums';
use aliased 'Enums::EnumsDrill';
use List::MoreUtils qw(uniq);

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"uniRTM"} = shift;

	return $self;
}




# Check if tools parameters are ok
# When some errors occure here, proper NC export is not possible
#sub CheckChains {
#	my $self = shift;
#	my $mess = shift;
#
#	my $result = 1;
#
#	unless ( RoutParser->CheckRoutAttributes($mess, $self->{"uniRTM"}->GetFeatures()) ) {
#		$result = 0;
#	}
# 
#	return $result;
#}
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f13608";

	my $f = FeatureFilter->new( $inCAM, "m" );

	$f->SetPolarity("positive");

 

	my @syms = ( "r500", "r1" );
	$f->AddIncludeSymbols( \[ "r500", "r1" ] );

	print $f->Select();

	print "fff";

}

1;

