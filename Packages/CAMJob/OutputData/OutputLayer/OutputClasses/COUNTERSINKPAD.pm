
#-------------------------------------------------------------------------------------------#
# Description: Parse Surface countersink from layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::OutputData::OutputLayer::OutputClasses::COUNTERSINKPAD;
use base('Packages::CAMJob::OutputData::OutputLayer::OutputClasses::OutputClassBase');

use Class::Interface;
&implements('Packages::CAMJob::OutputData::OutputLayer::OutputClasses::IOutputClass');

#3th party library
use strict;
use warnings;
use List::Util qw[max min];
use List::MoreUtils qw(uniq);
use Math::Trig;
use Math::Geometry::Planar;

#local library

use aliased 'Packages::CAMJob::OutputData::OutputLayer::Enums';
use aliased 'Packages::CAMJob::OutputData::OutputLayer::OutputResult::OutputClassResult';

use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAM::UniDTM::Enums' => "DTMEnums";
use aliased 'Packages::CAM::UniRTM::Enums' => "RTMEnums";
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
use aliased 'Enums::EnumsDrill';
use aliased 'Packages::Tooling::CountersinkHelper';
use aliased 'Packages::CAMJob::OutputData::OutputLayer::OutputResult::OutputLayer';
use aliased 'Packages::Polygon::Polygon::PolygonAttr';
use aliased 'Enums::EnumsRout';
use aliased 'Packages::Polygon::Features::Features::Features';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $self = $class->SUPER::new( @_, Enums->Type_COUNTERSINKPAD );
	bless $self;
	return $self;
}

sub Prepare {
	my $self = shift;

	$self->__Prepare();

	return $self->{"result"};

}

sub __Prepare {
	my $self = shift;

	my $l = $self->{"layer"};

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	my $lName = $l->{"gROWname"};
	my @tools =
	  grep { $_->GetTypeProcess() eq DTMEnums->TypeProc_HOLE && $_->GetSpecial() && $_->GetAngle() > 0 } $l->{"uniDTM"}->GetUniqueTools();

	return 0 unless (@tools);

	# Get all radiuses

	my @radiuses = uniq(map { $_->GetDrillSize() / 2 } @tools);

	foreach my $r (@radiuses) {

		my $outputLayer = OutputLayer->new();    # layer process result

		my $tool          = ( grep { $_->GetDrillSize()/2 == $r } @tools )[0];
		my $toolDepth     = $tool->GetDepth();
		my $toolDrillSize = $tool->GetDrillSize();
		my $toolAngle     = $tool->GetAngle();

		# get all pads with this radius
		my $f = Features->new();
		$f->Parse( $inCAM, $jobId, $self->{"step"}, $lName );
		my @features = $f->GetFeatures();

		my @pads = grep { $_->{"type"} =~ /^p$/i && $_->{"thick"} / 2 == $r } @features;

		# get id of all features in chain
		my @featsId = map { $_->{'id'} } @pads;

		my $drawLayer = $self->_SeparateFeatsByIdNC( \@featsId );

		# 1) Set prepared layer name
		$outputLayer->SetLayer($drawLayer);

		# 2 Add another extra info to output layer

		my $radiusReal = CountersinkHelper->GetHoleRadiusByToolDepth( $toolDrillSize, $toolAngle, $toolDepth*1000 ) / 1000;

		if ( $l->{"plated"} ) {
			$radiusReal -= 0.05;
		}

		$outputLayer->{"radiusReal"}  = $radiusReal;    # real computed radius of features in layer
		$outputLayer->{"padFeatures"} = \@pads;         # All pads, which was processed in ori layer in this class
		$outputLayer->{"DTMTool"} = $tool;				# DTM tool, which is used for this pads

		$self->{"result"}->AddLayer($outputLayer);
	}

}

#-------------------------------------------------------------------------------------------#
#  Protected methods
#-------------------------------------------------------------------------------------------#

# Remove all layers used in result
sub _FinalCheck {
	my $self   = shift;
	my $result = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	my %hist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $step, $result->GetOriLayer() );
	if ( $hist{"total"} > 0 ) {

		return 0;
	}
	else {

		return 1;
	}
}

# Remove all layers used in result
sub _Clear {
	my $self   = shift;
	my $result = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	foreach my $lName ( $result->GetLayers() ) {

		CamMatrix->DeleteLayer( $inCAM, $jobId, $lName );
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
