
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


	CamHelper->SetStep($self->{"inCAM"}, "panel" );

	my $patternSch;

	if ( $self->{"layerCnt"} > 2 ) {
		$patternSch = 'pattern-vv';
	}
	elsif ( $self->{"layerCnt"} == 2 ) {
		$patternSch = 'pattern-2v';
	}

	foreach my $l ( @{ $self->{"layers"} } ) {

		if ( $l->{"etchingType"} eq EnumsGeneral->Etching_TENTING ) {
		
			$self->{"helper"}->DelPatternFrame( $l->{"name"}, $patternSch );
		}
		elsif ( $l->{"etchingType"} eq EnumsGeneral->Etching_PATTERN ) {

			$self->{"helper"}->ChangeMarkPolarity($l->{"name"});

			$self->{"helper"}->AddPatternFrame( $l->{"name"}, $patternSch );

		}
	}
	
	
	my $resultItem = $self->_GetNewItem("Set frames");
	$self->_OnItemResult($resultItem);
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

