
#-------------------------------------------------------------------------------------------#
# Description: Parse rout data from layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::OutputData::OutputLayer::OutputClasses::ROUT;
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
use aliased 'CamHelpers::CamDTM';
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

	return 0 unless ( grep {$_->GetTypeProcess() eq DTMEnums->TypeProc_CHAIN} $l->{"uniDTM"}->GetTools() );

	# Get all radiuses

	my $outputLayer = OutputLayer->new();    # layer process result

	my $lTmp = $self->_SeparateFeatsBySymbolsNC( [ "surfaces", "lines", "arcs", "text" ] );

	my $drawLayer = CamLayer->RoutCompensation( $inCAM, $lTmp, "document" );

	# if rout layer is plated, convert all to surface and resize properly
	if ( $l->{"plated"} ) {

		CamLayer->Contourize( $inCAM, $drawLayer, "area", "25000" );
		CamLayer->WorkLayer($inCAM,  $drawLayer);
		$inCAM->COM( "sel_resize", "size" => -( 2 * Enums->Plating_THICK ), "corner_ctl" => "no" );
		 
	}
	
	CamMatrix->DeleteLayer($inCAM, $jobId, $lTmp);
  
	# 1) Set prepared layer name
	$outputLayer->SetLayerName($drawLayer);

	# 2) Add another extra info to output layer

	$self->{"result"}->AddLayer($outputLayer);
	
	
	# Rout layer can contain pads "r0" - bridges, delete theses pads
	# If we do not delete theses pads, finel layer check on emty lazer fail (Outut parser, final check)
	
	my $f = FeatureFilter->new( $inCAM, $jobId, $lName );
	$f->AddFeatureIndexes($featuresId);

	if ( $f->Select() > 0 ) {

		$inCAM->COM(
			"sel_move_other",

			# "dest"         => "layer_name",
			"target_layer" => $lName
		);

		CamLayer->WorkLayer( $inCAM, $lName );
		my $lComp = CamLayer->RoutCompensation( $inCAM, $lName, "document" );

		CamLayer->WorkLayer( $inCAM, $lName );
		$inCAM->COM("sel_delete");
	
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
