
#-------------------------------------------------------------------------------------------#
# Description: Parse Surface countersink from layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::OutputData::OutputLayer::OutputClasses::ZAXISSURFCHAMFER;
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
use aliased 'CamHelpers::CamLayer';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $self = $class->SUPER::new( @_, Enums->Type_ZAXISSURFCHAMFER );
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
	my @chainSeq = grep { $_->GetFeatureType() eq RTMEnums->FeatType_SURF } $l->{"uniRTM"}->GetChainSequences();

	return 0 unless (@chainSeq);

	# only special tools with angle
	@chainSeq =
	  grep { $_->GetChain()->GetChainTool()->GetUniDTMTool()->GetSpecial() && $_->GetChain()->GetChainTool()->GetUniDTMTool()->GetAngle() > 0 }
	  @chainSeq;

	my @toolSizes = uniq( map { $_->GetChain()->GetChainSize() } @chainSeq );

	foreach my $tool (@toolSizes) {

		my $outputLayer   = OutputLayer->new();                                              # layer process result
		my $tool          = ( $chainSeq[0] )->GetChain()->GetChainTool()->GetUniDTMTool();
		my $toolDepth     = $tool->GetDepth();
		my $toolDrillSize = $tool->GetDrillSize();
		my $toolAngle     = $tool->GetAngle();

		# get all chain seq by radius, by tool diameter (same tool diameters must have same angle)
		my @matchCh = grep { $_->GetChain()->GetChainSize() == $toolDrillSize } @chainSeq;

		next unless (@matchCh);

		# get id of all features in chain
		my @featsId = map { $_->{'id'} } map { $_->GetOriFeatures() } @matchCh;

		# During identification, surface are "compensate" to lines.
		# Asume tool go along border only (do one circle around whole suface)
		my $drawLayer = $self->_SeparateFeatsByIdNC( \@featsId ); 
 
		my $radiusReal = CountersinkHelper->GetHoleRadiusByToolDepth( $toolDrillSize, $toolAngle, $toolDepth * 1000 ) / 1000;

		if ( $l->{"plated"} ) {
			$radiusReal -= 0.05;
		}

		# resize all line/arc in drawLayer. Difference of (ToolDiameter/2 - $radiusReal)*2

		my $resize = ( $toolDrillSize / 2 - $radiusReal*1000 ) * 2;
	 
		# Warning, conturization is necessary here in order properly feature resize.
		# Only for case, when rout is "cyclic" and compensation is "inside" (CW and Right)
		CamLayer->Contourize( $inCAM, $drawLayer );
		CamLayer->WorkLayer( $inCAM, $drawLayer );
		CamLayer->ResizeFeatures( $inCAM, -$resize );

		# 1) Set prepared layer name
		$outputLayer->SetLayer($drawLayer);    # Attention! lazer contain original sizes of feature, not finish/real sizes

		# 2 Add another extra info to output layer

		$outputLayer->{"radiusReal"} = $radiusReal;    # real compted radius of line arc
		$outputLayer->{"chainSeq"}   = \@matchCh;      # All chain seq, which was processed in ori layer in this class

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
