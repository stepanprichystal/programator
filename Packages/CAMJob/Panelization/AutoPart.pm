#-------------------------------------------------------------------------------------------#
# Description: Responsible for preparing job board layers for output.

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
#  Interface
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

sub AddPnlSize {
	my $self   = shift;
	my $width  = shift;
	my $height = shift;

	my $inCAM    = $self->{"inCAM"};
	my $jobId    = $self->{"jobId"};
	my $stepName = $self->{"step"};

	$inCAM->COM( "auto_part_place_add_size", "width" => $width, "height" => $height );

}

sub AddPnlBorderSpacing {
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

sub Panelise {
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

