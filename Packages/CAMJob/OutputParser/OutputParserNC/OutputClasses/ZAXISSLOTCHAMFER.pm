
#-------------------------------------------------------------------------------------------#
# Description: Parse slot chamfer  from layer (angle tool)
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::OutputParser::OutputParserNC::OutputClasses::ZAXISSLOTCHAMFER;
use base('Packages::CAMJob::OutputParser::OutputParserBase::OutputClasses::OutputClassBase');

use Class::Interface;
&implements('Packages::CAMJob::OutputParser::OutputParserBase::OutputClasses::IOutputClass');

#3th party library
use strict;
use warnings;
use List::Util qw[max min];
use List::MoreUtils qw(uniq);
use Math::Trig;
use Math::Geometry::Planar;

#local library

use aliased 'Packages::CAMJob::OutputParser::OutputParserNC::Enums';
use aliased 'Packages::CAMJob::OutputParser::OutputParserBase::OutputResult::OutputClassResult';

use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAM::UniDTM::Enums' => "DTMEnums";
use aliased 'Packages::CAM::UniRTM::Enums' => "RTMEnums";
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
use aliased 'Enums::EnumsDrill';
use aliased 'Packages::Tooling::CountersinkHelper';
use aliased 'Packages::CAMJob::OutputParser::OutputParserBase::OutputResult::OutputLayer';
use aliased 'Packages::Polygon::Polygon::PolygonAttr';
use aliased 'Enums::EnumsRout';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamMatrix';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $self = $class->SUPER::new( @_, Enums->Type_ZAXISSLOTCHAMFER );
	bless $self;
	return $self;
}

sub Prepare {
	my $self = shift;

	$self->_Prepare();

	return $self->{"result"};

}

sub _Prepare {
	my $self = shift;

	my $l = $self->{"layer"};

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	my $lName = $l->{"gROWname"};
	my @chainSeq = grep { $_->GetFeatureType() eq RTMEnums->FeatType_LINEARC } $l->{"uniRTM"}->GetChainSequences();

	return 0 unless (@chainSeq);

	# only special tools with angle
	@chainSeq =
	  grep { $_->GetChain()->GetChainTool()->GetUniDTMTool()->GetSpecial() && $_->GetChain()->GetChainTool()->GetUniDTMTool()->GetAngle() > 0 }
	  @chainSeq;

	my @toolSizes = uniq( map { $_->GetChain()->GetChainSize() } @chainSeq );

	foreach my $tool (@toolSizes) {

		my $outputLayer   = OutputLayer->new();                                              # layer process result
		my $toolDTM       = ( $chainSeq[0] )->GetChain()->GetChainTool()->GetUniDTMTool();
		my $toolDepth     = $toolDTM->GetDepth();
		my $toolDrillSize = $toolDTM->GetDrillSize();
		my $toolAngle     = $toolDTM->GetAngle();

		# get all chain seq by radius, by tool diameter (same tool diameters must have same angle)
		my @matchCh = grep { $_->GetChain()->GetChainSize() == $toolDrillSize } @chainSeq;

		next unless (@matchCh);

		# get id of all features in chain
		my @featsId = map { $_->{'id'} } map { $_->GetOriFeatures() } @matchCh;

		my $separateL = $self->_SeparateFeatsByIdNC( \@featsId );
	my $drawLayer = CamLayer->RoutCompensation( $inCAM, $separateL, "document" );
	CamMatrix->DeleteLayer( $inCAM, $jobId, $separateL );

		my $radiusReal = CountersinkHelper->GetHoleRadiusByToolDepth( $toolDrillSize, $toolAngle, $toolDepth * 1000 ) / 1000;    # in mm
		my $exceededDepth = CountersinkHelper->GetToolExceededDepth( $toolDrillSize, $toolAngle, $toolDepth * 1000 ) / 1000;     # in mm

		# Warning, conturization is necessary here in order properly feature resize.
		# Only for case, when rout is "cyclic" and compensation is "inside" (CW and Right)
		#CamLayer->Contourize( $inCAM, $drawLayer );
		

		#CamLayer->ResizeFeatures( $inCAM, -$resize );
		if ( $l->{"plated"} ) {
			CamLayer->WorkLayer( $inCAM, $drawLayer );
			CamLayer->ResizeFeatures( $inCAM, -2 * Enums->Plating_THICK );
			$radiusReal -= Enums->Plating_THICKMM;
		}

		# 1) Set prepared layer name
		# Attention!
		# - layer contain original sizes of feature. ( if plated, features are resized by 2xplating thick)
		# - rout layer are compensated to document (feature compnsate thickness is kept)
		$outputLayer->SetLayerName($drawLayer);

		# 2 Add another extra info to output layer

		$outputLayer->SetDataVal( "radiusReal",    $radiusReal );     # real compted radius of line arc [mm]
		$outputLayer->SetDataVal( "DTMTool",       $toolDTM );        # DTMTool which all chainSeq are processed by
		$outputLayer->SetDataVal( "exceededDepth", $exceededDepth )
		  ;    # exceeded depth of tool if exist (if depth ot tool is bigger than size of tool peak)
		$outputLayer->SetDataVal( "chainSeq", \@matchCh );    # All chain seq, which was processed in ori layer in this class

		$self->{"result"}->AddLayer($outputLayer);
	}
}

#-------------------------------------------------------------------------------------------#
#  Protected methods
#-------------------------------------------------------------------------------------------#

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
