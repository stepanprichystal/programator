#-------------------------------------------------------------------------------------------#
# Description: Wrapper for autopart/ sr autopart command
# Two ways how to use autopart:
# 1) Manual panel pick (or best) with result viewer
#  - AutopartAddPnlSize
#  - AutopartAddPnlBorderSpacing
#  - AutopartPanelise
# 2) Automatic panel creation without displaying result viewer
#  - SRAutopartPanelise
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Panelization::AutoPart;

#3th party library
use strict;
use warnings;

#local library

use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStepRepeat';

#-------------------------------------------------------------------------------------------#
#  Public methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
	$self->{"step"}  = shift;

	$self->{"inCAM"}->COM("auto_part_place_reset");

	return $self;
}

#-------------------------------------------------------------------------------------------#
# 1) Manual panel pick (or best) with result viewer
#-------------------------------------------------------------------------------------------#

sub AutoPartAddPnlSize {
	my $self   = shift;
	my $width  = shift;
	my $height = shift;

	my $inCAM    = $self->{"inCAM"};
	my $jobId    = $self->{"jobId"};
	my $stepName = $self->{"step"};

	$inCAM->COM( "auto_part_place_add_size", "width" => $width, "height" => $height );

}

sub AutoPartAddPnlBorderSpacing {
	my $self         = shift;
	my $topBorder    = shift;
	my $bottomBorder = shift;
	my $leftBorder   = shift;
	my $rightBorder  = shift;
	my $spaceX       = shift;
	my $spaceY       = shift;

	my $inCAM    = $self->{"inCAM"};
	my $jobId    = $self->{"jobId"};
	my $stepName = $self->{"step"};

	$inCAM->COM(
				 "auto_part_place_add_border_spacing",
				 "spaceX"       => $spaceX,
				 "spaceY"       => $spaceY,
				 "topBorder"    => $topBorder,
				 "bottomBorder" => $bottomBorder,
				 "leftBorder"   => $leftBorder,
				 "rightBorder"  => $rightBorder
	);

}

sub AutoPartPanelise {
	my $self            = shift;
	my $nestStep        = shift;
	my $unitsInPanel    = shift // "automatic";
	my $minUtilization  = shift // 1;
	my $minResults      = shift // 1;
	my $goldTab         = shift // "gold_none";
	my $autoSelectBest  = shift;                         # 0/1
	my $goldMode        = shift // "minimize_scoring";
	my $goldScoringDist = shift // 0;
	my $spacingAlign    = shift // "keep_in_center";
	my $numMaxSteps     = shift // "no_limit";
	my $transformation  = shift // "rotation";
	my $rotation        = shift // "any_rotation";
	my $pattern         = shift // "no_pattern";
	my $flip            = shift // "no_flip";
	my $interlock       = shift // "none";
	my $xmin            = shift // "0";
	my $ymin            = shift // "0";
	my $base_rotation   = shift // "0";

	my $inCAM    = $self->{"inCAM"};
	my $jobId    = $self->{"jobId"};
	my $stepName = $self->{"step"};

	$inCAM->COM(
				 "auto_part_place",
				 "step"            => $nestStep,
				 "unitsInPanel"    => $unitsInPanel,
				 "minUtilization"  => $minUtilization,
				 "minResults"      => $minResults,
				 "goldTab"         => $goldTab,
				 "autoSelectBest"  => ( !defined $autoSelectBest || $autoSelectBest == 0 ? "no" : "yes" ),
				 "goldMode"        => $goldMode,
				 "goldScoringDist" => $goldScoringDist,
				 "spacingAlign"    => $spacingAlign,
				 "numMaxSteps"     => $numMaxSteps,
				 "transformation"  => $transformation,
				 "rotation"        => $rotation,
				 "pattern"         => $pattern,
				 "flip"            => $flip,
				 "interlock"       => $interlock,
				 "xmin"            => $xmin,
				 "ymin"            => $ymin,
				 "base_rotation"   => $base_rotation
	);
	
	
}

#-------------------------------------------------------------------------------------------#
# 2) Automatic panel creation without displaying result viewer
#-------------------------------------------------------------------------------------------#

# Return hash with result, nested step cnt, utilization
# Raise error if nested steps are greater thjan active area
# Raise error alwas if there is no solution of panelisation (nested step == 0)
# Suppress InCAM exception before calling if necessary
sub SRAutoPartPanelise {
	my $self   = shift;
	my $width  = shift;
	my $height = shift;

	my $topBorder    = shift;
	my $bottomBorder = shift;
	my $leftBorder   = shift;
	my $rightBorder  = shift;
	my $spaceX       = shift;
	my $spaceY       = shift;

	my $nestStep        = shift;
	my $unitsInPanel    = shift // "automatic";
	my $minUtilization  = shift // 1;
	my $minResults      = shift // 1;
	my $goldTab         = shift // "gold_none";
	my $autoSelectBest  = shift;                         # 0/1
	my $goldMode        = shift // "minimize_scoring";
	my $goldScoringDist = shift // 0;
	my $spacingAlign    = shift // "keep_in_center";
	my $numMaxSteps     = shift // "no_limit";
	my $transformation  = shift // "rotation";
	my $rotation        = shift // "any_rotation";
	my $pattern         = shift // "no_pattern";
	my $flip            = shift // "no_flip";
	my $interlock       = shift // "none";
	my $xmin            = shift // "0";
	my $ymin            = shift // "0";
	my $base_rotation   = shift // "0";

	my $inCAM    = $self->{"inCAM"};
	my $jobId    = $self->{"jobId"};
	my $stepName = $self->{"step"};

	my $resAutoPlace = $inCAM->COM(
		"sr_auto_part_place",

		"width" => $width, "height" => $height,

		"spaceX"       => $spaceX,
		"spaceY"       => $spaceY,
		"topBorder"    => $topBorder,
		"bottomBorder" => $bottomBorder,
		"leftBorder"   => $leftBorder,
		"rightBorder"  => $rightBorder,

		"step"         => $nestStep,
		"unitsInPanel" => $unitsInPanel,

		# "minUtilization"  => $minUtilization,
		# "minResults"      => $minResults,
		"goldTab" => $goldTab,

		# "autoSelectBest"  => ( !defined $autoSelectBest || $autoSelectBest == 0 ? "no" : "yes" ),
		"goldMode"        => $goldMode,
		"goldScoringDist" => $goldScoringDist,
		"spacingAlign"    => $spacingAlign,
		"numMaxSteps"     => $numMaxSteps,
		"transformation"  => $transformation,
		"rotation"        => $rotation,
		"pattern"         => $pattern,
		"flip"            => $flip,
		"interlock"       => $interlock,
		"xmin"            => $xmin,
		"ymin"            => $ymin,
		"base_rotation"   => $base_rotation
	);

	my %res = ( "result" => 0, "stepCnt" => 0, "utilization" => 0 );

	if ( $resAutoPlace == 0 ) {

		my ( $stepCnt, $utilization ) = split( /\s+/, $inCAM->GetReply() );

		$res{"result"}      = 1;
		$res{"stepCnt"}     = $stepCnt;
		$res{"utilization"} = $utilization;

	}

	return %res;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAMJob::Panelization::SRStep';
	#
	use aliased 'Packages::InCAM::InCAM';
	#
	my $inCAM = InCAM->new();
	#
	my $jobId = "f52456";
	#
	#	my $mess = "";
	#
	#	my $control = SRStep->new( $inCAM, $jobId, "test" );
	#	my %p = ("x"=> -10, "y" => -20);
	#	$control->Create( 300, 400, 10,10,10,10, \%p );
	#	my $control = SRStep->new( $inCAM, $jobId, "test" );
	#	my %p = ("x"=> 10, "y" => +10);
	#	$control->Create( 300, 400, 10,10,10,10, \%p   );

}

1;

