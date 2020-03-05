
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for AOI files creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::PreExport::PreMngr;
use base('Packages::ItemResult::ItemEventMngr');

use Class::Interface;
&implements('Packages::Export::IMngr');

#3th party library
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::Export::PreExport::LayerInvert';
use aliased 'Packages::CAMJob::Scheme::SchemeFrame::SchemeFrame';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::TifFile::TifLayers';
use aliased 'Packages::Export::PreExport::Enums';
use aliased 'CamHelpers::CamGoldArea';
use aliased 'Packages::CAMJob::PCBConnector::GoldFingersCheck';
use aliased 'Helpers::FileHelper';
use aliased 'Helpers::JobHelper';
use aliased 'Packages::CAMJob::Stackup::StackupConvertor';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class     = shift;
	my $packageId = __PACKAGE__;
	my $self      = $class->SUPER::new( $packageId, @_ );
	bless $self;

	$self->{"inCAM"}        = shift;
	$self->{"jobId"}        = shift;
	$self->{"signalLayers"} = shift;
	$self->{"otherLayers"}  = shift;

	$self->{"layerFrame"}  = SchemeFrame->new( $self->{"inCAM"}, $self->{"jobId"} );
	$self->{"layerInvert"} = LayerInvert->new( $self->{"inCAM"}, $self->{"jobId"} );

	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $self->{"jobId"} );

	return $self;
}

sub Run {
	my $self  = shift;
	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $isChanged = 0;    # tell if something was changed in pcb

	CamHelper->SetStep( $inCAM, "panel" );

	my $resultItemFrames = $self->_GetNewItem("Add schemas");

	# Insert pattern frame
	$self->__PatternFrame( \$isChanged );

	$self->_OnItemResult($resultItemFrames);

	# if job is changed, save it
	if ($isChanged) {

		my $resultItemSave = $self->_GetNewItem("Saving job");

		$inCAM->HandleException(1);

		CamJob->SaveJob( $inCAM, $self->{"jobId"} );

		$resultItemSave->AddError( $inCAM->GetExceptionError() );
		$inCAM->HandleException(0);

		$self->_OnItemResult($resultItemSave);
	}

	# 2) Save info to tif file
	my $resultItemDif = $self->_GetNewItem("Dif file");

	# Load old values
	my $tif       = TifLayers->new( $self->{"jobId"} );
	my %sigLayers = $tif->GetSignalLayers();

	# add new layers or change old
	foreach my $l ( @{ $self->{"signalLayers"} } ) {

		$sigLayers{ $l->{"name"} } = $l;
	}

	$tif->SetSignalLayers( \%sigLayers );

	# Load old values
	my %otherLayers = $tif->GetOtherLayers();

	# add new layers or change old
	foreach my $l ( @{ $self->{"otherLayers"} } ) {

		$otherLayers{ $l->{"name"} } = $l;
	}

	$tif->SetOtherLayers( \%otherLayers );
	$self->_OnItemResult($resultItemDif);

	# 3) Edit stackup if RigidFlex

	my $pcbType = JobHelper->GetPcbType( $self->{"jobId"} );

	if ( $pcbType eq EnumsGeneral->PcbType_RIGIDFLEXO || $pcbType eq EnumsGeneral->PcbType_RIGIDFLEXI ) {

		# remove all multicall stackup for curent job
		# (there could be more than one stackup (slightly different name) for one job)
		my @oldStackups = FileHelper->GetFilesNameByPattern( EnumsPaths->Jobs_STACKUPS, $jobId . "_" );
		unlink($_) foreach (@oldStackups);

		my $convertor = StackupConvertor->new( $inCAM, $jobId );
		my $res = $convertor->DoConvert();

		my $resultStack = $self->_GetNewItem("Edit RigidFlex stackup");

		unless ($res) {
			$resultStack->AddError("Failed to create MultiCal xml stackup");
		}

		$self->_OnItemResult($resultStack);
	}
 
}

sub __PatternFrame {
	my $self      = shift;
	my $isChanged = shift;

	my $patternSch;

	# choose pattern schema. Add pattern frame from surface fill to layer, whci has attribut add_schema = yes
	if ( $self->{"layerCnt"} > 2 ) {
		$patternSch = 'pattern-vv';

	}
	elsif ( $self->{"layerCnt"} == 2 ) {
		$patternSch = 'pattern-2v';
	}

	foreach my $l ( @{ $self->{"signalLayers"} } ) {

		if ( $l->{"etchingType"} eq EnumsGeneral->Etching_TENTING ) {

			if ( $self->{"layerFrame"}->ExistFrame( $l->{"name"}, Enums->Frame_PATTERN ) ) {

				$$isChanged = 1;

				$self->{"layerInvert"}->ChangeMarkPolarity( $l->{"name"} );

				$self->{"layerFrame"}->DeleteFrame( $l->{"name"}, Enums->Frame_PATTERN );
			}

		}
		elsif ( $l->{"etchingType"} eq EnumsGeneral->Etching_PATTERN ) {

			unless ( $self->{"layerFrame"}->ExistFrame( $l->{"name"}, Enums->Frame_PATTERN ) ) {

				$$isChanged = 1;

				$self->{"layerInvert"}->ChangeMarkPolarity( $l->{"name"} );

				$self->{"layerFrame"}->AddFrame( $l->{"name"}, Enums->Frame_PATTERN, $patternSch );
			}

		}
	}

}

sub TaskItemsCount {
	my $self = shift;

	my $totalCnt = 0;

	$totalCnt += 3;    # check pattern frames + save job

	return $totalCnt;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Export::PlotExport::PlotMngr';

	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "f13610";

	my @layers = CamJob->GetBoardBaseLayers( $inCAM, $jobId );

	foreach my $l (@layers) {

		$l->{"polarity"} = "positive";

		if ( $l->{"gROWname"} =~ /pc/ ) {
			$l->{"polarity"} = "negative";
		}

		$l->{"mirror"} = 0;
		if ( $l->{"gROWname"} =~ /c/ ) {
			$l->{"mirror"}      = 1;
			$l->{"etchingType"} = EnumsGeneral->Etching_PATTERN;
		}

		$l->{"compensation"} = 30;
		$l->{"name"}         = $l->{"gROWname"};
	}

	@layers = grep { $_->{"name"} =~ /p[cs]/ } @layers;

	my $mngr = PlotMngr->new( $inCAM, $jobId, \@layers );
	$mngr->Run();
}

1;

