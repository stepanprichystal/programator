#-------------------------------------------------------------------------------------------#
# Description: Function for checking aspect ratio, isolation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Drilling::BlindDrill::BlindDrillCheck;

#3th party library
use strict;
use warnings;
use Math::Trig;
use Math::Trig ':pi';

#local library

use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamDrilling';
use aliased 'Enums::EnumsDrill';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';
use aliased 'Packages::CAMJob::Drilling::BlindDrill::Enums';
use aliased 'Packages::CAMJob::Drilling::BlindDrill::BlindDrill';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

# Check if real depth is in tolerance +-10µm with computed depth
sub CheckDrillDepth {
	my $self       = shift;
	my $stackup    = shift;
	my $drillSize  = shift;          # DTM uni tool
	my $drillDepth = shift;          # DTM uni tool
	my $ncLayer    = shift;          # NC Layer with start/stop properties
	my $resultData = shift // {};    # result data wehen check fail

	my $result = 1;

	# GetDrillType
	my $type = BlindDrill->GetDrillType( $stackup, $drillSize, $ncLayer );

	if ($type) {                     # Compute Depth

		my $depthComputed = BlindDrill->ComputeDrillDepth( $stackup, $drillSize, $ncLayer, $type );

		# tolerance 10µm
		if ( abs( $depthComputed - $drillDepth ) > 10 ) {
			$result = 0;

		}

		$resultData->{"computedDepth"} = $depthComputed;

	}
	else {
		die "Unable to compute drill depth, because no calculation type (STANDARD/SPECIAL) can by used";
	}
	
	return $result;

}

# Cehck if isolatiopn from peak to nexct Cu layer is equal or bigger than requested isolation
sub CheckDrillIsolation {
	my $self       = shift;
	my $stackup    = shift;
	my $drillSize  = shift;          # DTM uni tool with depth
	my $drillDepth = shift;
	my $ncLayer    = shift;          # NC Layer with start/stop properties
	my $drillType  = shift;          # Type 1 - cylindrial part to Cu , Type 2 - drill peak to Cu
	my $resultData = shift // {};    # result data wehen check fail

	my $result = 1;

	my $reqIsol = 0;                 # requested isolation for specificied tool
	my $reqIsolFromCu;               # name of Cu layer which isolation is requested for
	my $realIsol = 0;                # real isolation, which is between end drilled Cu layer and next Cu layer in drill direction

	# Real isolation
	my @layers = $stackup->GetAllLayers();
	@layers = reverse(@layers) if ( $ncLayer->{"gROWdrl_dir"} eq "bot2top" );

	for ( my $i = 0 ; $i < scalar(@layers) ; $i++ ) {
		my $l = $layers[$i];

		if ( $l->GetType() eq StackEnums->MaterialType_COPPER && $l->GetCopperNumber() eq $ncLayer->{"gROWdrl_end"} ) {
 
			$realIsol      = $layers[ $i + 1 ]->GetThick();
			$reqIsolFromCu = $layers[ $i + 2 ]->GetCopperName();
			last;
		}
	}

	# Peal absolute length
	my $peakLen = ( $drillSize / 2 ) / tan( deg2rad( Enums->DRILL_TOOL_ANGLE / 2 ) );

	# End half cu
	my $endCuThick = $stackup->GetCuLayer( $ncLayer->{"gROWdrl_end_name"} )->GetThick();

	if ( $drillType eq Enums->BLINDTYPE_STANDARD ) {

		$reqIsol = Enums->MIN_ISOLATION + Enums->DRILL_TOLERANCE + $peakLen - $endCuThick / 2;

		print STDERR "Type 1: Isolation: $reqIsol\n";

	}
	elsif ( $drillType eq Enums->BLINDTYPE_SPECIAL ) {

		$reqIsol =
		  Enums->MIN_ISOLATION + Enums->DRILL_TOLERANCE + ( ( $peakLen / 2 - $endCuThick / 2 ) < 0 ? 0 : ( $peakLen / 2 - $endCuThick / 2 ) );
		print STDERR "Type 2: Isolation: $reqIsol\n";
	}

	if ( $realIsol < $reqIsol ) {

		$result = 0;

	}

	$resultData->{"requestedIsolThick"}   = $reqIsol;
	$resultData->{"currentIsolThick"}     = $realIsol;
	$resultData->{"requestedIsolCuLayer"} = $reqIsolFromCu;

	return $result;

}

# Check aspect ratio for blind holes
sub AspectRatioCheck {
	my $self       = shift;
	my $drillSize  = shift;          # µm DTM uni tool with depth
	my $drillDepth = shift;          # µm
	my $resultData = shift // {};    # result data wehen check fail

	my $result = 1;

	my $ar = ($drillDepth) / $drillSize;

	if ( $ar <= 1 ) {
		$result = 1;
	}
	else {

		$result = 0;
	}

	$resultData->{"ar"} = $ar;

	return $result;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Packages::CAMJob::Drilling::BlindDrill::BlindDrillCheck';
	#	use aliased 'Packages::InCAM::InCAM';
	#	use aliased 'Packages::Stackup::Stackup::Stackup';
	#
	#	my $inCAM = InCAM->new();
	#	my $jobId = "d152457";
	#	my $step  = "o+1";
	#
	#	my $stackup = Stackup->new($jobId);
	#
	#	my %res = ();
	#	my $r = BlindDrillCheck->CheckDrillDepth( $stackup,  $step, \%res );
	#
	#	print $r;

}

1;
