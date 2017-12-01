
#-------------------------------------------------------------------------------------------#
# Description: Parse drill data from layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::OutputData::OutputLayer::OutputClasses::DRILL;
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

	my $self = $class->SUPER::new( @_, Enums->Type_DRILL );
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

	return 0 unless ( $l->{"uniDTM"}->GetUniqueTools() );

	# Get all radiuses
 
	my $outputLayer = OutputLayer->new();    # layer process result

	my $drawLayer = $self->_SeparateFeatsBySymbolsNC( ["pad"] );
	
	# adjust DTM to finish size
 

	# 1) Set prepared layer name
	$outputLayer->SetLayer($drawLayer);

	# 2 Add another extra info to output layer

	$outputLayer->{"padFeatures"} = \@pads;               # All pads, which was processed in ori layer in this class
	$outputLayer->{"DTMTool"}     = $tool;                # DTM tool, which is used for this pads
	$outputLayer->{"radiusReal"}  = $radiusReal / 1000;

	$self->{"result"}->AddLayer($outputLayer);
}

# Set all NC layers to finish sizes (consider type of DTM vysledne/vrtane)
sub __SetFinishSizes {
	my $self   = shift;
	my @layers = @{ shift(@_) };

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	foreach my $l (@layers) {

		# except score latyer
		if ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_score ) {
			next;
		}

		my $lName = $l->{"gROWname"};

		# Prepare tool table for drill map and final sizes of data (depand on column DSize in DTM)

		my @tools = CamDTM->GetDTMTools( $inCAM, $jobId, $self->{"step"}, $lName );

		my $DTMType = CamDTM->GetDTMType( $inCAM, $jobId, $self->{"oriStep"}, $lName );

		# if DTM type not set, set default DTM type
		if ( $DTMType ne EnumsDrill->DTM_VRTANE && $DTMType ne EnumsDrill->DTM_VYSLEDNE ) {

			$DTMType = CamDTM->GetDTMDefaultType( $inCAM, $jobId, $self->{"oriStep"}, $lName, 1 );
		}

		if ( $DTMType ne EnumsDrill->DTM_VRTANE && $DTMType ne EnumsDrill->DTM_VYSLEDNE ) {
			die "Typ v Drill tool manageru (vysledne/vrtane) neni nastaven u vrstvy: '" . $lName . "' ";
		}

		# check if dest size are defined
		my @badSize = grep { !defined $_->{"gTOOLdrill_size"} || $_->{"gTOOLdrill_size"} == 0 || $_->{"gTOOLdrill_size"} eq "" } @tools;

		if (@badSize) {
			@badSize = map { $_->{"gTOOLfinish_size"} } @badSize;
			my $toolStr = join( ", ", @badSize );
			die "Tools: $toolStr, has not set drill size.\n";
		}

		# 1) If some tool has not finish size, correct it by putting there drill size (if vysledne resize -100µm)

		foreach my $t (@tools) {

			if ( !defined $t->{"gTOOLfinish_size"} || $t->{"gTOOLfinish_size"} == 0 || $t->{"gTOOLfinish_size"} eq "" ) {

				if ( $DTMType eq EnumsDrill->DTM_VYSLEDNE ) {

					$t->{"gTOOLfinish_size"} = $t->{"gTOOLdrill_size"} - $self->{"plateThick"};    # 100µm - this is size of plating

				}
				elsif ( $DTMType eq EnumsDrill->DTM_VRTANE ) {
					$t->{"gTOOLfinish_size"} = $t->{"gTOOLdrill_size"};
				}

			}
		}

		# 2) Copy 'finish' value to 'drill size' value.
		# Drill size has to contain value of finih size, because all pads, lines has size depand on this column
		# And we want diameters size after plating

		foreach my $t (@tools) {

			# if DTM is vrtane + layer is plated + it is plated through dps (layer cnt >= 2)
			if ( $DTMType eq EnumsDrill->DTM_VRTANE && $l->{"plated"} && $self->{"layerCnt"} >= 2 ) {
				$t->{"gTOOLdrill_size"} = $t->{"gTOOLfinish_size"} - $self->{"plateThick"};
			}
			else {
				$t->{"gTOOLdrill_size"} = $t->{"gTOOLfinish_size"};
			}
		}

		# 3) Set new values to DTM
		CamDTM->SetDTMTools( $inCAM, $jobId, $self->{"step"}, $lName, \@tools );

		$inCAM->INFO(
					  units           => 'mm',
					  angle_direction => 'ccw',
					  entity_type     => 'layer',
					  entity_path     => "$jobId/" . $self->{"step"} . "/$lName",
					  data_type       => 'TOOL',
					  options         => "break_sr"
		);

		# 4) If some tools same, merge it
		$inCAM->COM( "tools_merge", "layer" => $lName );

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
