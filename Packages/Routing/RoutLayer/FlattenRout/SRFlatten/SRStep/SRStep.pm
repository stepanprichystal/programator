#-------------------------------------------------------------------------------------------#
# Description: Helper class, which copy rout in nested steps (contained in flattened step)
# and rotate them by SR table. Than we can do modification such as set rout start, do checks etc..
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::RoutLayer::FlattenRout::SRFlatten::SRStep::SRStep;

#3th party library
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library
use aliased 'Packages::CAM::UniRTM::Enums';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamAttributes';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamStep';
use aliased 'Packages::Routing::RoutLayer::FlattenRout::SRFlatten::SRStep::SRNestedStep';
use aliased 'Packages::CAM::UniRTM::UniRTM';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}       = shift;
	$self->{"jobId"}       = shift;
	$self->{"step"}        = shift;
	$self->{"sourceLayer"} = shift;
	$self->{"excludeSteps"} = shift; # exclude specified steps from rout creating#

	my @nestedSteps = ();
	$self->{"nestedSteps"} = \@nestedSteps;

	return $self;
}

sub Init {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	CamHelper->SetStep( $inCAM, $self->GetStep() );

	# init steps

	my @repeatsSR = CamStepRepeat->GetRepeatStep( $inCAM, $jobId, $self->{"step"} );
	
	# exclude steps if requested
	if($self->{"excludeSteps"}){
		my %tmp;
		@tmp{ @{$self->{"excludeSteps"}} } = ();
		@repeatsSR = grep { !exists $tmp{ $_->{"stepName"} } } @repeatsSR;
	}
	

	foreach my $rStep (@repeatsSR) {

		my $alreadyInit = scalar( grep { $_->GetStepName() eq $rStep->{"stepName"} && $_->GetAngle() eq $rStep->{"angle"} } $self->GetNestedSteps() );

		unless ($alreadyInit) {
			my $nestedStep = SRNestedStep->new( $rStep->{"stepName"}, $rStep->{"angle"} );
			$self->__InitNestedStep($nestedStep);

			push( @{ $self->{"nestedSteps"} }, $nestedStep );
		}

	}
}

sub __InitNestedStep {
	my $self       = shift;
	my $nestedStep = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# Prepare rout work layer

	$inCAM->COM(
		'copy_layer',
		"source_job"   => $jobId,
		"source_step"  => $nestedStep->GetStepName(),
		"source_layer" => $self->{"sourceLayer"},
		"dest"         => 'layer_name',
		"dest_layer"   => $nestedStep->GetRoutLayer(),
		"mode"         => 'replace',
		"invert"       => 'no'

	);

	# move to zero

	my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $nestedStep->GetStepName(), 1 );
	my %datum = CamStep->GetDatumPoint( $inCAM, $jobId, $nestedStep->GetStepName(), 1 );

	if ( abs($lim{"xMin"} - $datum{"x"}) > 0.01 || abs($lim{"yMin"} - $datum{"y"}) > 0.01 ) {
		die "Step: \""
		  . $nestedStep->GetStepName()
		  . "\" . Left down corner of profile is not equal to datum point. Move datump point to left down corner of step profile!.\n";
	}

	if ( $lim{"xMin"} < 0 || $lim{"yMin"} < 0 ) {

		CamLayer->WorkLayer( $inCAM, $nestedStep->GetRoutLayer() );
		$inCAM->COM(
					 "sel_transform",
					 "oper"      => "",
					 "x_anchor"  => "0",
					 "y_anchor"  => "0",
					 "angle"     => "0",
					 "direction" => "ccw",
					 "x_scale"   => "1",
					 "y_scale"   => "1",
					 "x_offset"  => -$lim{"xMin"},
					 "y_offset"  => -$lim{"yMin"},
					 "mode"      => "anchor",
					 "duplicate" => "no"
		);
	}

	if ( $nestedStep->GetAngle() > 0 ) {

		CamLayer->WorkLayer( $inCAM, $nestedStep->GetRoutLayer() );
		$inCAM->COM(
					 "sel_transform",
					 "direction" => "ccw",
					 "x_anchor"  => 0,
					 "y_anchor"  => 0,
					 "oper"      => "rotate",
					 "angle"     => $nestedStep->GetAngle()
		);
	}

	# Load uniRTM
	my $uniRTM = UniRTM->new( $inCAM, $jobId, $self->GetStep(), $nestedStep->GetRoutLayer() );
	$nestedStep->SetUniRTM($uniRTM);

	# Load necessary att

	my %att = CamAttributes->GetStepAttr( $inCAM, $jobId, $nestedStep->GetStepName() );

	if ( defined $att{"rout_on_bridges"} && $att{"rout_on_bridges"} eq "yes" ) {
		$nestedStep->{"userRoutOnBridges"} = 1;
	}

}

# Remove layer, where step rout was coppied
sub Clean {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @routLayers = map { $_->GetRoutLayer() } @{ $self->{"nestedSteps"} };

	foreach my $l (@routLayers) {

		if ( CamHelper->LayerExists( $inCAM, $jobId, $l ) ) {

			$inCAM->COM( 'delete_layer', "layer" => $l );
		}
	}

}

sub GetNestedStep {
	my $self     = shift;
	my $stepName = shift;
	my $rotation = shift;

	my $step = ( grep { $_->GetStepName() eq $stepName && $_->GetAngle() == $rotation } @{ $self->{"nestedSteps"} } )[0];

	return $step;
}

sub GetNestedSteps {
	my $self = shift;

	return @{ $self->{"nestedSteps"} };
}

sub GetStep {
	my $self = shift;

	return $self->{"step"};
}

sub GetSourceLayer {
	my $self = shift;

	return $self->{"sourceLayer"};
}

sub ReloadStepUniRTM {
	my $self       = shift;
	my $nestedStep = shift;
	my $inCAM      = $self->{"inCAM"};
	my $jobId      = $self->{"jobId"};

	my $u = UniRTM->new( $inCAM, $jobId, $self->GetStep(), $nestedStep->GetRoutLayer() );
	$nestedStep->SetUniRTM($u);
}



#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

