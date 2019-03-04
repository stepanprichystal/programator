
#-------------------------------------------------------------------------------------------#
# Description: Parse rout data from layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::OutputParser::OutputParserNC::OutputClasses::ROUT;
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
use aliased 'CamHelpers::CamDTM';
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
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamMatrix';
use aliased 'Packages::Polygon::Features::Features::Features';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $self = $class->SUPER::new( @_, Enums->Type_ROUT );
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

	return 0 unless ( grep { $_->GetTypeProcess() eq DTMEnums->TypeProc_CHAIN } $l->{"uniDTM"}->GetTools() );

	# Get all radiuses

	my $outputLayer = OutputLayer->new();    # layer process result

	my $separateL = $self->_SeparateFeatsBySymbolsNC( [ "surface", "line", "arc", "text" ] );
	my $drawLayer = CamLayer->RoutCompensation( $inCAM, $separateL, "document" );
	CamMatrix->DeleteLayer( $inCAM, $jobId, $separateL );

	# if rout layer is plated, convert all to surface and resize properly
	if ( $l->{"plated"} ) {

		#CamLayer->Contourize( $inCAM, $drawLayer, "area", "25000" );
		CamLayer->WorkLayer( $inCAM, $drawLayer );
		$inCAM->COM( "sel_resize", "size" => -( 2 * Enums->Plating_THICK ), "corner_ctl" => "no" );
	}

	# 1) Set prepared layer name
	# Attention!
	# - layer contain original sizes of feature. ( if plated, features are resized by 2xplating thick)
	# - rout layer are compensated to document (feature compnsate thickness is kept)
	$outputLayer->SetLayerName($drawLayer);

	# 2) Add another extra info to output layer

	$self->{"result"}->AddLayer($outputLayer);

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
