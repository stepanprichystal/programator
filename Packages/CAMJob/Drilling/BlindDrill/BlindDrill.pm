#-------------------------------------------------------------------------------------------#
# Description: Function compute blind drill depth
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Drilling::BlindDrill::BlindDrill;

#3th party library
use utf8;
use strict;
use warnings;
use Math::Trig;
use Math::Trig ':pi';

#local library

use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsDrill';
use aliased 'Packages::CAMJob::Drilling::BlindDrill::Enums';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';
use aliased 'Packages::CAMJob::Drilling::BlindDrill::BlindDrillCheck';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

# Return type of calculation method for drill types
# Exist two types:
# - BLINDTYPE_STANDARD - Cylindrical part of tool ends at the middle of landing Cu (TYPE 1)
# - BLINDTYPE_SPECIAL - Concical part of tool is half way through the landing Cu (TYPE 2)
sub GetDrillType {
	my $self      = shift;
	my $stackup   = shift;
	my $drillSize = shift;          # DTM uni tool
	my $ncLayer   = shift;          # NC Layer with start/stop properties
	my $resData   = shift // {};    # resutl data when no drill type returned

	my $drillType = 0;

	$resData->{ Enums->BLINDTYPE_STANDARD } = {};
	$resData->{ Enums->BLINDTYPE_SPECIAL }  = {};

	# compute depth for type 1 and 2
	my $drillDepthT1 = $self->ComputeDrillDepth( $stackup, $drillSize, $ncLayer, Enums->BLINDTYPE_STANDARD );
	my $drillDepthT2 = $self->ComputeDrillDepth( $stackup, $drillSize, $ncLayer, Enums->BLINDTYPE_SPECIAL );

	# compute requested isolation for type 1 and 2
	my $t1IsolOk = BlindDrillCheck->CheckDrillIsolation( $stackup, $drillSize, $drillDepthT1, $ncLayer, Enums->BLINDTYPE_STANDARD,
														 $resData->{ Enums->BLINDTYPE_STANDARD } );
	my $t2IsolOk = BlindDrillCheck->CheckDrillIsolation( $stackup, $drillSize, $drillDepthT2, $ncLayer, Enums->BLINDTYPE_SPECIAL,
														 $resData->{ Enums->BLINDTYPE_SPECIAL } );

	# compute a for type 1 and 2
	my $t1AROk = BlindDrillCheck->AspectRatioCheck( $drillSize, $drillDepthT1, $resData->{ Enums->BLINDTYPE_STANDARD } );

	my $t2AROk = BlindDrillCheck->AspectRatioCheck( $drillSize, $drillDepthT2, $resData->{ Enums->BLINDTYPE_SPECIAL } );

	# Check if STANDARD type is possible
	if ( $t1IsolOk && $t1AROk ) {

		$drillType = Enums->BLINDTYPE_STANDARD;
	}

	# If not check if SPECIAL is possible
	elsif ( $t2IsolOk && $t2AROk ) {

		$drillType = Enums->BLINDTYPE_SPECIAL;
	}

	# store results
	$resData->{ Enums->BLINDTYPE_STANDARD }->{"isolOk"} = $t1IsolOk;
	$resData->{ Enums->BLINDTYPE_STANDARD }->{"arOk"}   = $t1AROk;
	$resData->{ Enums->BLINDTYPE_SPECIAL }->{"isolOk"}  = $t2IsolOk;
	$resData->{ Enums->BLINDTYPE_SPECIAL }->{"arOk"}    = $t2AROk;

	print STDERR "DRILL TYPE:$drillType\n";

	return $drillType;
}

# Compute blind drill depth
sub ComputeDrillDepth {
	my $self      = shift;
	my $stackup   = shift;
	my $drillSize = shift;    # DTM uni tool
	my $ncLayer   = shift;    # NC Layer with start/stop properties
	my $drillType = shift;    # Type 1 - cylindrial part to Cu , Type 2 - drill peak to Cu

	my $depth = 0;

	my $drillS   = $ncLayer->{"NCSigStartOrder"};
	my $drillE   = $ncLayer->{"NCSigEndOrder"};
	my $drillDir = $ncLayer->{"gROWdrl_dir"} ;

	# Stackup thick from start to end Cu of drilling (end cu - compute only half thick of Cu)
	my $stackThick = 0;       #µm

	my @layers = $stackup->GetAllLayers();
	@layers = reverse(@layers) if ( $drillDir eq "bot2top" );

	my $addThick = 0;
	foreach my $l (@layers) {

		# check "start layer" of computting total thickness
		if ( !$addThick && $l->GetType() eq StackEnums->MaterialType_COPPER ) {

			if (    $drillDir eq "bot2top" && $l->GetCopperNumber() <= $drillS
				 || $drillDir eq "top2bot" && $l->GetCopperNumber() >= $drillS )
			{
				$addThick = 1;
			}
		}

		next unless ($addThick);

		if ( $l->GetType() eq StackEnums->MaterialType_COPPER && $l->GetCopperNumber() eq $drillE ) {

			$stackThick += $l->GetThick() / 2;    # end cu computed only half thick
			last;
		}
		
		$stackThick += $l->GetThick();
	}
	
	die "Error during calculation of stackup thickness between start/end drill layer (".$ncLayer->{"gROWname"}.")" unless($stackThick);

	#  Absolute peak length/height
	my $peakLen = ( $drillSize / 2 ) / tan( deg2rad( Enums->DRILL_TOOL_ANGLE / 2 ) );

	# Final drill depth
	if ( $drillType eq Enums->BLINDTYPE_STANDARD ) {

		$depth = $stackThick + Enums->DRILL_TOLERANCE + $peakLen;

		print STDERR "Type 1: peak:" . $peakLen . ", depth = $depth\n";

	}
	elsif ( $drillType eq Enums->BLINDTYPE_SPECIAL ) {

		$depth = $stackThick + Enums->DRILL_TOLERANCE + $peakLen / 2;
		print STDERR "Type 2: peak:" . ( $peakLen / 2 ) . ", depth = $depth\n";
	}

	return $depth;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAMJob::Drilling::BlindDrill::BlindDrill';
	use aliased 'Packages::InCAM::InCAM';
	use aliased 'CamHelpers::CamDrilling';

	my $inCAM = InCAM->new();
	my $jobId = "d218211";
	my $step  = "o+1";

	use aliased 'Packages::Stackup::Stackup::Stackup';

	my $stackup = Stackup->new($jobId);

	my %res = ();

	my %l = ( "gROWname" => "sc2" );
	CamDrilling->AddLayerStartStop( $inCAM, $jobId, [ \%l ] );

	my $r = BlindDrill->GetDrillType( $stackup, 1650, \%l, \%res );

	print $r;

}

1;
