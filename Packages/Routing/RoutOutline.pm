#-------------------------------------------------------------------------------------------#
# Description: Get defualt route parameters according PCB type
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::RoutOutline;

#3th party library
use strict;
use warnings;
use Math::Polygon;
use List::Util qw[max];

#local library
use aliased 'Helpers::JobHelper';
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::Routing::RoutLayer::RoutStart::RoutStart';
use aliased 'Enums::EnumsRout';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

# Get PCB outline rout start corner according PCB type and stackup
# - EnumsRout->OutlineStart_LEFTTOP
# - EnumsRout->OutlineStart_RIGHTTOP
sub GetDefRoutStart {
	my $self  = shift;
	my $jobId = shift;

	# Default is LEFT-TOP corner

	my $outlRoutStart = EnumsRout->OutlineStart_LEFTTOP;

	if ( JobHelper->GetIsFlex($jobId) ) {

		# Flex PCB

		$outlRoutStart = EnumsRout->OutlineStart_RIGHTTOP;

	}
	else {

		# Semi-hybrid PCB

		my $isSemiHybrid = 0;
		my $isHybrid = JobHelper->GetIsHybridMat( $jobId, undef, [], \$isSemiHybrid );

		if ($isSemiHybrid) {
			$outlRoutStart = EnumsRout->OutlineStart_RIGHTTOP;
		}
	}

	return $outlRoutStart;
}

# Get PCB outline rout sequence for routing PCB in production panel/mpanel
# - EnumsRout->SEQUENCE_BTRL
# - EnumsRout->SEQUENCE_BTLR
sub GetDefRoutSeq {
	my $self  = shift;
	my $jobId = shift;

	# Default is BTRL

	my $outlSeq = EnumsRout->SEQUENCE_BTRL;

	if ( JobHelper->GetIsFlex($jobId) ) {

		# Flex PCB

		$outlSeq = EnumsRout->SEQUENCE_BTLR;

	}
	else {

		# Semi-hybrid PCB

		my $isSemiHybrid = 0;
		my $isHybrid = JobHelper->GetIsHybridMat( $jobId, undef, [], \$isSemiHybrid );

		if ($isSemiHybrid) {
			$outlSeq = EnumsRout->SEQUENCE_BTLR;
		}
	}

	return $outlSeq;
}

# Get PCB outline rout direction
# - EnumsRout->Dir_CW
# - EnumsRout->Dir_CCW
sub GetDefRoutDirection {
	my $self  = shift;
	my $jobId = shift;

	# Default is LEFT-TOP corner

	my $outlDir = EnumsRout->Dir_CW;

	if ( JobHelper->GetIsFlex($jobId) ) {

		# Flex PCB

		$outlDir = EnumsRout->Dir_CCW;

	}
	else {

		# Semi-hybrid PCB

		my $isSemiHybrid = 0;
		my $isHybrid = JobHelper->GetIsHybridMat( $jobId, undef, [], \$isSemiHybrid );

		if ($isSemiHybrid) {
			$outlDir = EnumsRout->Dir_CCW;
		}
	}

	return $outlDir;
}

# Get PCB outline rout compensation
# - EnumsRout->Comp_LEFT
# - EnumsRout->Comp_RIGHT
sub GetDefRoutComp {
	my $self  = shift;
	my $jobId = shift;

	# Default is LEFT-TOP corner

	my $outlDir = EnumsRout->Comp_LEFT;

	if ( JobHelper->GetIsFlex($jobId) ) {

		# Flex PCB

		$outlDir = EnumsRout->Comp_RIGHT;

	}
	else {

		# Semi-hybrid PCB

		my $isSemiHybrid = 0;
		my $isHybrid = JobHelper->GetIsHybridMat( $jobId, undef, [], \$isSemiHybrid );

		if ($isSemiHybrid) {
			$outlDir = EnumsRout->Comp_RIGHT;
		}
	}

	return $outlDir;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Routing::PilotHole';
	use aliased 'Packages::InCAM::InCAM';

	my $jobId = "d113609";
	my $inCAM = InCAM->new();

	my $step = "o+1";

	my $max = PilotHole->AddPilotHole( $inCAM, $jobId, $step, "r" );

}

1;
