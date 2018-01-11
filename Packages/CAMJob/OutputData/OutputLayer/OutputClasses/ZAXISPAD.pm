
#-------------------------------------------------------------------------------------------#
# Description: Parse pad zaxis  from layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::OutputData::OutputLayer::OutputClasses::ZAXISPAD;
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
use aliased 'Packages::Polygon::Features::Features::Features';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $self = $class->SUPER::new( @_, Enums->Type_ZAXISPAD );
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
	  grep { $_->GetTypeProcess() eq DTMEnums->TypeProc_HOLE && !$_->GetSpecial() } $l->{"uniDTM"}->GetUniqueTools();

	return 0 unless (@tools);

	# Get all radiuses

	my @radiuses = uniq(map { $_->GetDrillSize() / 2 } @tools);

	foreach my $r (@radiuses) {

		my $outputLayer = OutputLayer->new();    # layer process result

		my $tool          = ( grep { $_->GetDrillSize()/2 == $r } @tools )[0];
		my $toolDepth     = $tool->GetDepth();
		my $toolDrillSize = $tool->GetDrillSize();
 

		# get all pads with this radius
		my $f = Features->new();
		$f->Parse( $inCAM, $jobId, $self->{"step"}, $lName );
		my @features = $f->GetFeatures();

		my @pads = grep { $_->{"type"} =~ /^p$/i && $_->{"thick"} / 2 == $r } @features;

		# get id of all features in chain
		my @featsId = map { $_->{'id'} } @pads;

		my $drawLayer = $self->_SeparateFeatsByIdNC( \@featsId );
		
		my $radiusReal = $tool->GetDrillSize()/2;

		if ( $l->{"plated"} ) {
			CamLayer->ResizeFeatures( $inCAM, -2 * Enums->Plating_THICK );
			$radiusReal -= Enums->Plating_THICK;
		}

		# 1) Set prepared layer name
		$outputLayer->SetLayerName($drawLayer);

		# 2 Add another extra info to output layer
 
		$outputLayer->{"padFeatures"} = \@pads;         # All pads, which was processed in ori layer in this class
		$outputLayer->{"DTMTool"} = $tool;				# DTM tool, which is used for this pads
		$outputLayer->{"radiusReal"} = $radiusReal/1000;

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