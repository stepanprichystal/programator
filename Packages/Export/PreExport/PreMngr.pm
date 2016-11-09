
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for AOI files creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::PreExport::PreMngr;
use base('Packages::Export::MngrBase');

use Class::Interface;
&implements('Packages::Export::IMngr');

#3th party library
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Export::PreExport::LayerInvert';
use aliased 'CamHelpers::CamHelper';

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

	$self->{"helper"} = LayerInvert->new( $self->{"inCAM"}, $self->{"jobId"} );

	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $self->{"jobId"} );

	return $self;
}

sub Run {
	my $self = shift;

	my $helper = $self->{"helper"};
	my $inCAM  = $self->{"inCAM"};

	my $isChanged = 0;    # tell if something was changed in pcb

	CamHelper->SetStep( $inCAM, "panel" );

	my $patternSch;

	# choose pattern schema. Add pattern frame from surface fill to layer, whci has attribut add_schema = yes
	if ( $self->{"layerCnt"} > 2 ) {
		$patternSch = 'pattern-vv+'; 

	}
	elsif ( $self->{"layerCnt"} == 2 ) {
		$patternSch = 'pattern-2v+';
	}

	foreach my $l ( @{ $self->{"layers"} } ) {

		if ( $l->{"etchingType"} eq EnumsGeneral->Etching_TENTING ) {

			if ( $helper->ExistPatternFrame( $l->{"name"} ) ) {

				$isChanged = 1;

				$helper->ChangeMarkPolarity( $l->{"name"} );

				$helper->DelPatternFrame( $l->{"name"}, $patternSch );
			}

		}
		elsif ( $l->{"etchingType"} eq EnumsGeneral->Etching_PATTERN ) {

			unless ( $helper->ExistPatternFrame( $l->{"name"} ) ) {

				$isChanged = 1;

				$helper->ChangeMarkPolarity( $l->{"name"} );

				$helper->AddPatternFrame( $l->{"name"}, $patternSch );
			}

		}
	}

	my $resultItem = $self->_GetNewItem("Add/del frames");
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

}

sub ExportItemsCount {
	my $self = shift;

	my $totalCnt = 0;

	$totalCnt += scalar( @{ $self->{"layers"} } );    #export each layer

	return $totalCnt;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Packages::Export::PlotExport::PlotMngr';
	#
	#	use aliased 'Packages::InCAM::InCAM';
	#
	#	my $inCAM = InCAM->new();
	#
	#	my $jobId = "f13609";
	#
	#	my @layers = CamJob->GetBoardBaseLayers( $inCAM, $jobId );
	#
	#	foreach my $l (@layers) {
	#
	#		$l->{"polarity"} = "positive";
	#
	#		if ( $l->{"gROWname"} =~ /pc/ ) {
	#			$l->{"polarity"} = "negative";
	#		}
	#
	#		$l->{"mirror"} = 0;
	#		if ( $l->{"gROWname"} =~ /c/ ) {
	#			$l->{"mirror"} = 1;
	#		}
	#
	#		$l->{"compensation"} = 30;
	#		$l->{"name"}         = $l->{"gROWname"};
	#	}
	#
	#	@layers = grep { $_->{"name"} =~ /p[cs]/ } @layers;
	#
	#	my $mngr = PlotMngr->new( $inCAM, $jobId, \@layers );
	#	$mngr->Run();
}

1;

