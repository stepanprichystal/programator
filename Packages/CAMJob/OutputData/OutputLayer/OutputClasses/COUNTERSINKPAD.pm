
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

	my $self = $class->SUPER::new( @_, Enums->Type_COUNTERSINKARC );
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

	my @radiuses = map { $_->GetDrillSize() } @tools;

	foreach my $r (@radiuses) {

		# get all pads with this radius
		my $f = Features->new();
		$f->Parse( $inCAM, $jobId, $self->{"step"}, $lName );
		my @features = $f->GetFeatures();

		# get all chain seq by radius, by tool diameter (same tool diameters must have same angle)
		my @matchCh =
		  grep { ( $_->{"radius"} - 0.01 ) < $r && ( $_->{"radius"} + 0.01 ) > $r && $_->GetChain()->GetChainSize() == $tool } @chainSeq;

		next unless (@matchCh);

		my $toolDepth = $matchCh[0]->GetChain()->GetChainTool()->GetUniDTMTool()->GetDepth();    # angle of tool
		my $toolAngle = $matchCh[0]->GetChain()->GetChainTool()->GetUniDTMTool()->GetAngle();    # angle of tool

		my $radiusNoDepth = $matchCh[0]->{"radius"};
		my $radiusReal = CountersinkHelper->GetSlotRadiusByToolDepth( $radiusNoDepth * 1000, $tool, $toolAngle, $toolDepth * 1000 ) / 1000;

		if ( $l->{"plated"} ) {
			$radiusReal -= 0.05;
		}

		# get id of all features in chain
		my @featsId = map { $_->{'id'} } map { $_->GetOriFeatures() } @matchCh;

		my $drawLayer = $self->_IdentifyFeaturesByIds( \@featsId );

		my $outputLayer = OutputLayer->new($drawLayer);

		# add another extra info to output layer

		$outputLayer->{"radiusReal"} = $radiusReal;    # real compted radius of features in layer
		$outputLayer->{"chainSeq"}   = \@matchCh;      # All chain seq, which was processed in ori layer in this class

		$self->{"result"}->AddLayer($outputLayer);
	}
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
