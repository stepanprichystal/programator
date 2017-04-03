#-------------------------------------------------------------------------------------------#
# Description: Special structure for flatenning step. Contain position of SR in step
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::RoutLayer::FlattenRout::SRFlatten::SRFlatten::SRFlatten;

#3th party library
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library
use aliased 'Packages::CAM::UniRTM::Enums';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamAttributes';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Packages::Routing::RoutLayer::FlattenRout::SRFlatten::SRFlatten::SRStepPos';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}     = shift;
	$self->{"jobId"}     = shift;
	$self->{"SRStep"}    = shift;
	$self->{"flatLayer"} = shift;

	my @stepPos = ();
	$self->{"stepPos"} = \@stepPos;

	return $self;
}

sub Init {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	CamHelper->SetStep( $inCAM, $self->{"SRStep"}->GetStep() );

	# init steps
	my @repeatsSR = CamStepRepeat->GetRepeatStep( $inCAM, $jobId, $self->{"SRStep"}->GetStep() );
	foreach my $rStep (@repeatsSR) {

		my $nestStep = $self->{"SRStep"}->GetNestedStep( $rStep->{"stepName"}, $rStep->{"angle"} );

		my $srStepPos = SRStepPos->new( $nestStep, $rStep->{"originX"}, $rStep->{"originY"} );
		push( @{ $self->{"stepPos"} }, $srStepPos );

	}
}

sub GetStepPositions {
	my $self = shift;

	return @{ $self->{"stepPos"} };
}

sub GetStep {
	my $self = shift;

	return $self->{"SRStep"}->GetStep();
}

sub GetSourceLayer {
	my $self = shift;

	return $self->{"SRStep"}->GetSourceLayer();
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

