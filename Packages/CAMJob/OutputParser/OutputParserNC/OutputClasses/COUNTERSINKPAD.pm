
#-------------------------------------------------------------------------------------------#
# Description: Parse pad countersink from layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::OutputParser::OutputParserNC::OutputClasses::COUNTERSINKPAD;
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
use aliased 'CamHelpers::CamLayer';
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
	my @tools =
	  grep { $_->GetTypeProcess() eq EnumsDrill->TypeProc_HOLE && $_->GetSpecial() && $_->GetAngle() > 0 } $l->{"uniDTM"}->GetUniqueTools();

	return 0 unless (@tools);

	# Get all radiuses

	my @radiuses = uniq( map { $_->GetDrillSize() / 2 } @tools );

	foreach my $r (@radiuses) {

		my $outputLayer = OutputLayer->new();    # layer process result

		my $toolDTM       = ( grep { $_->GetDrillSize() / 2 == $r } @tools )[0];
		my $toolDepth     = $toolDTM->GetDepth();
		my $toolDrillSize = $toolDTM->GetDrillSize();
		my $toolAngle     = $toolDTM->GetAngle();

		# get all pads with this radius
		my $f = Features->new();
		$f->Parse( $inCAM, $jobId, $self->{"step"}, $lName );
		my @features = $f->GetFeatures();

		my @pads = grep { $_->{"type"} =~ /^p$/i && $_->{"thick"} / 2 == $r } @features;

		# get id of all features in chain
		my @featsId = map { $_->{'id'} } @pads;

		my $drawLayer = $self->_SeparateFeatsByIdNC( \@featsId );

		my $radiusReal = CountersinkHelper->GetHoleRadiusByToolDepth( $toolDrillSize, $toolAngle, $toolDepth * 1000 ) / 1000;    # in mm
		my $exceededDepth = CountersinkHelper->GetToolExceededDepth( $toolDrillSize, $toolAngle, $toolDepth * 1000 ) / 1000;     # in mm

		if ( $l->{"plated"} ) {
			CamLayer->WorkLayer( $inCAM, $drawLayer );
			CamLayer->ResizeFeatures( $inCAM, -2 * Enums->Plating_THICK );
			$radiusReal -= Enums->Plating_THICKMM;
		}

		# 1) Set prepared layer name
		# Attention!
		# - layer contain original sizes of feature. ( if plated, features are resized by 2xplating thick)
		$outputLayer->SetLayerName($drawLayer);

		# 2 Add another extra info to output layer

		if ( $l->{"plated"} ) {
			$outputLayer->SetDataVal( "radiusBeforePlt", $radiusReal + Enums->Plating_THICKMM )
			  ;    # real compted radius of features in layer before plated [mm]
		}
		$outputLayer->SetDataVal( "radiusReal",    $radiusReal );     # real computed radius of features in layer [mm]
		$outputLayer->SetDataVal( "DTMTool",       $toolDTM );        # DTM tool, which is used for this pads
		$outputLayer->SetDataVal( "exceededDepth", $exceededDepth )
		  ;    # exceeded depth of tool if exist (if depth ot tool is bigger than size of tool peak)
		$outputLayer->SetDataVal( "padFeatures", \@pads );    # All pads, which was processed in ori layer in this class

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
