
#-------------------------------------------------------------------------------------------#
# Description: Parse drill data from layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::OutputData::OutputLayer::OutputClasses::DRILLBase;
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
use aliased 'Packages::Tooling::CountersinkHelper';
use aliased 'Packages::CAMJob::OutputData::OutputLayer::OutputResult::OutputLayer';
use aliased 'Packages::Polygon::Polygon::PolygonAttr';
use aliased 'Enums::EnumsRout';
use aliased 'CamHelpers::CamLayer';

use aliased 'Packages::Polygon::Features::Features::Features';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $self = $class->SUPER::new( @_, Enums->Type_DRILLBase );
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

	return 0 unless ( grep {$_->GetTypeProcess() eq DTMEnums->TypeProc_HOLE} $l->{"uniDTM"}->GetTools() );

	# Get all radiuses

	my $outputLayer = OutputLayer->new();    # layer process result
 

	my $drawLayer = $self->_SeparateFeatsBySymbolsNC( ["pads"] );
 
 
	# adjust DTM to finish size
	$self->_SetDTMFinishSizes($drawLayer);

	# 1) Set prepared layer name
	$outputLayer->SetLayerName($drawLayer);

	# 2 Add another extra info to output layer

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
