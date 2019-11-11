
#-------------------------------------------------------------------------------------------#
# Description: Parse Multical xml stackup
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::StackupBase::StackupParsers::InStackParser;

use Class::Interface;
&implements('Packages::Stackup::StackupBase::StackupParsers::IStackupParser');

#3th party library
use strict;
use warnings;
use XML::LibXML qw(:threads_shared);

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::Stackup::Enums';
use aliased 'Packages::Stackup::StackupBase::StackupHelper';
use aliased 'Packages::Stackup::StackupBase::StackupInfo';
use aliased 'Packages::Stackup::StackupBase::Layer::PrepregLayer';
use aliased 'Packages::Stackup::StackupBase::Layer::CoreLayer';
use aliased 'Packages::Stackup::StackupBase::Layer::CopperLayer';
use aliased 'Packages::Stackup::StackupBase::Layer::StackupLayerBase';
use aliased 'Connectors::HeliosConnector::HegMethods';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"jobId"} = shift;

	return $self;
}

#Return array with stackup info
#Every item array is Hash, which contain information about layer, like thick, usage, name etc.
sub ParseStackup {
	my $self = shift;

	my $jobId = $self->{"jobId"};

	my $stcFile = EnumsPaths->Jobs_COUPONS . "$jobId.xml";
	die "Stackup file ($stcFile) doesn't exists" unless ( -e $stcFile );

	my $stackupXml = XML::LibXML->load_xml( "location" => $stcFile );

	my @layers = ();

	#temporary solution, reading real thickness of prepreg from special file
	my $realPrepregThicks = StackupHelper->__ReadPrepregThick();

	#helper class with technical info for stackup material
	my $stackuInfoData = StackupInfo->new();

	my @segs = $stackupXml->findnodes('/document/interfacelist/JOB/STACKUP/STACKUP/STACKUP_SEGS/STACKUP_SEG');

	my $coreCnt   = 0;    #tell how many cores stackup contains
	my $copperCnt = 0;    #tell how many cores stackup contains

	# sort segments by stackup index
	my @mat = $stackupXml->findnodes('/document/interfacelist/JOB/STACKUP/STACKUP/STACKUP_SEGS/STACKUP_SEG/SEGMENT_MATERIALS/SEGMENT_MATERIAL');

	@segs = sort { $a->{"STACKUP_SEG_INDEX"} <=> $b->{"STACKUP_SEG_INDEX"} } @segs;

	# Load material uda info
	my %matUda = ();

	foreach my $matName ( map { $_->{"MATERIAL_NAME"} } @mat ) {

		unless ( $matUda{$matName} ) {
			my $uda = HegMethods->GetMatInfo($matName);
			die "Material info was not found in IS (material ref: $matName)" unless ($uda);
			$matUda{$matName} = $uda;
		}
	}

	# Load copper layer info
	my %copperLayersInfo = ();
	my @copperLayers     = $stackupXml->findnodes('/document/interfacelist/JOB/COPPER_LAYERS/COPPER_LAYER');

	foreach my $cl (@copperLayers) {

		$copperLayersInfo{ $cl->{"DESIGN_LAYER_INDEX"} } = $cl;
	}

	for ( my $i = 0 ; $i < scalar(@segs) ; $i++ ) {

		my $seg = $segs[$i];

		#$layerInfo->{"type"} = $elType;

		if ( $seg->{"SEGMENT_TYPE"} eq Enums->InStackMaterialType_FOIL ) {

			my $layerInfo = CopperLayer->new();

			$copperCnt++;

			my $matRef = ( $seg->findnodes('./SEGMENT_MATERIALS/SEGMENT_MATERIAL') )[0]->{"MATERIAL_NAME"};

			my $info = $stackuInfoData->GetCopperInfo( $matUda{$matRef}->{"dps_id"} );

			$layerInfo->{"type"}         = Enums->MaterialType_COPPER;
			$layerInfo->{"thick"}        = $info->{d};
			$layerInfo->{"usage"}        = $copperLayersInfo{$copperCnt}->{"COPPER_USAGE"} / 100.0;    #percentage usage of cu
			$layerInfo->{"text"}         = $info->{text};
			$layerInfo->{"typetext"}     = $info->{typetext};
			$layerInfo->{"copperNumber"} = $copperCnt;
			$layerInfo->{"id"}           = $matUda{$matRef}->{"dps_id"};

			push( @layers, $layerInfo );

		}

		elsif ( $seg->{"SEGMENT_TYPE"} eq Enums->InStackMaterialType_ISOLATOR ) {

			foreach my $matSeg ( $seg->findnodes('./SEGMENT_MATERIALS/SEGMENT_MATERIAL') ) {

				my $matRef = $matSeg->{"MATERIAL_NAME"};
				my $info =
				  $stackuInfoData->GetPrepregInfo( $matUda{$matRef}->{"dps_qid"}, $matUda{$matRef}->{"dps_id"}, $realPrepregThicks );

				my $layerInfo = PrepregLayer->new();

				$layerInfo->{"type"}     = Enums->MaterialType_PREPREG;
				$layerInfo->{"thick"}    = $info->{d};
				$layerInfo->{"text"}     = $info->{text};
				$layerInfo->{"typetext"} = $info->{typetext};
				$layerInfo->{"id"}       = $matUda{$matRef}->{"dps_id"};
				$layerInfo->{"qId"}      = $matUda{$matRef}->{"dps_qid"};
				# prepreg is noflow if contains text "no flow"
				$layerInfo->{"noFlow"}   = $layerInfo->{"typetext"} =~ /((no)|(low)).*flow/i ? 1 : 0;

				push( @layers, $layerInfo );
			}

		}
		elsif ( $seg->{"SEGMENT_TYPE"} eq Enums->InStackMaterialType_CORE ) {

			my $matRef = ( $seg->findnodes('./SEGMENT_MATERIALS/SEGMENT_MATERIAL') )[0]->{"MATERIAL_NAME"};

			# Add top copper layer
			my $copperInfo = $stackuInfoData->GetCopperInfo( $matUda{$matRef}->{"dps_id2"} );

			my $copperTop = CopperLayer->new();

			$copperCnt++;

			$copperTop->{"type"}         = Enums->MaterialType_COPPER;
			$copperTop->{"thick"}        = $copperInfo->{d};
			$copperTop->{"usage"}        = $copperLayersInfo{$copperCnt}->{"COPPER_USAGE"} / 100.0;    #percentage usage of cu
			$copperTop->{"text"}         = $copperInfo->{text};
			$copperTop->{"typetext"}     = $copperInfo->{typetext};
			$copperTop->{"copperNumber"} = $copperCnt;
			$copperTop->{"id"}           = $matUda{$matRef}->{"dps_id2"};

			push( @layers, $copperTop );

			# add core layer
			my $layerInfo = CoreLayer->new();

			$coreCnt++;

			

			my $info = $stackuInfoData->GetCoreInfo( $matUda{$matRef}->{"dps_qid"}, $matUda{$matRef}->{"dps_id"} );

			$layerInfo->{"type"}       = Enums->MaterialType_CORE;
			$layerInfo->{"thick"}      = $info->{d};
			$layerInfo->{"text"}       = $info->{text};
			$layerInfo->{"typetext"}   = $info->{typetext};
			$layerInfo->{"coreNumber"} = $coreCnt;
			$layerInfo->{"id"}         = $matUda{$matRef}->{"dps_id"};
			$layerInfo->{"qId"}        = $matUda{$matRef}->{"dps_qid"};

			push( @layers, $layerInfo );

			# Add bot copper layer

			my $copperBot = CopperLayer->new();

			$copperCnt++;

			$copperBot->{"type"}         = Enums->MaterialType_COPPER;
			$copperBot->{"thick"}        = $copperInfo->{d};
			$copperBot->{"usage"}        = $copperLayersInfo{$copperCnt}->{"COPPER_USAGE"} / 100.0;    #percentage usage of cu
			$copperBot->{"text"}         = $copperInfo->{text};
			$copperBot->{"typetext"}     = $copperInfo->{typetext};
			$copperBot->{"copperNumber"} = $copperCnt;
			$copperBot->{"id"}           = $matUda{$matRef}->{"dps_id2"};

			push( @layers, $copperBot );

		}
		else {

			die "Unknown material type: " . $seg->{"SEGMENT_TYPE"};
		}

	}



	return @layers;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Stackup::StackupBase::StackupParsers::InStackParser';
	my $jobId  = "d200694_test";
	my $parser = InStackParser->new($jobId);
	$parser->ParseStackup();

}

1;

