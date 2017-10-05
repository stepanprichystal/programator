
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
use aliased 'Packages::Export::PreExport::LayerInvert';
use aliased 'Packages::Export::PreExport::LayerFrame';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::TifFile::TifSigLayers';
use aliased 'Packages::Export::PreExport::Enums';
use aliased 'CamHelpers::CamGoldArea';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class     = shift;
	my $packageId = __PACKAGE__;
	my $self      = $class->SUPER::new( $packageId, @_ );
	bless $self;

	$self->{"inCAM"}  = shift;
	$self->{"jobId"}  = shift;
	$self->{"layers"} = shift;

	$self->{"layerFrame"} = LayerFrame->new( $self->{"inCAM"}, $self->{"jobId"} );
	$self->{"layerInvert"} = LayerInvert->new( $self->{"inCAM"}, $self->{"jobId"} );

	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $self->{"jobId"} );

	return $self;
}

sub Run {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};

	my $isChanged = 0;    # tell if something was changed in pcb

	CamHelper->SetStep( $inCAM, "panel" );

	my $resultItemFrames = $self->_GetNewItem("Add schemas");

	# Insert pattern frame
	$self->__PatternFrame( \$isChanged );

	# Inser gold frame
	$self->__GoldFrame( \$isChanged, $resultItemFrames );

	$self->_OnItemResult($resultItemFrames);

	my $resultItem = $self->_GetNewItem("Save job");
	$self->_OnItemResult($resultItem);

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
	my $file = TifSigLayers->new( $self->{"jobId"} );

	# Load old values
	my %layers = $file->GetSignalLayers();

	# add new layers or change old
	foreach my $l ( @{ $self->{"layers"} } ) {

		$layers{ $l->{"name"} } = $l;

		# dif contain information about physis mirror
		# but layer info contain mirror which consider emulsion on films

		if ( $l->{"mirror"} ) {
			$layers{ $l->{"name"} }->{"mirror"} = 0;
		}
		else {
			$layers{ $l->{"name"} }->{"mirror"} = 1;
		}

	}

	$file->SetSignalLayers( \%layers );

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

	foreach my $l ( @{ $self->{"layers"} } ) {

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

sub __GoldFrame {
	my $self      = shift;
	my $isChanged = shift;
	my $itemRes   = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @layers = ();
	push( @layers, "c" ) if ( CamHelper->LayerExists( $inCAM, $jobId, "c" ) );
	push( @layers, "s" ) if ( CamHelper->LayerExists( $inCAM, $jobId, "s" ) );

	my $schema = "gold-2v";

	if ( $self->{"layerCnt"} > 2 ) {
		$schema = 'gold-vv';
	}

	foreach my $l (@layers) {

		my $frameExist = $self->{"layerFrame"}->ExistFrame( $l, Enums->Frame_GOLDFINGER );

		if ( CamGoldArea->GoldFingersExist( $inCAM, $jobId, "panel", $l ) ) {

			# 1) Add frame
			if ($frameExist) {
				$self->{"layerFrame"}->DeleteFrame( $l, Enums->Frame_GOLDFINGER );
			}
			
			$self->{"layerFrame"}->AddFrame( $l, Enums->Frame_GOLDFINGER, $schema );
			$$isChanged = 1;

			# 2) Do check if old gold finger are connected
			my $mess = "";
			my @layers = ($l);
			
			unless ( CamGoldArea->GoldFingersConnected( $inCAM, $jobId, \@layers, \$mess ) ) {

				$itemRes->AddError("Error during insert \"gold connector frame\": $mess");
			}
		}
		else {

			if ($frameExist) {
				$self->{"layerFrame"}->DeleteFrame( $l, Enums->Frame_GOLDFINGER );
				$$isChanged = 1;
			}
		}
	}

}

sub TaskItemsCount {
	my $self = shift;

	my $totalCnt = 0;

	$totalCnt += 2;    # check pattern frames + save job

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

