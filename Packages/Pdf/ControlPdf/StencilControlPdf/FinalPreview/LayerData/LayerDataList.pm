
#-------------------------------------------------------------------------------------------#
# Description: Prepare special structure "LayerData" for each exported layer.
# This sctructure contain list <LayerData> and operations with this items
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::StencilControlPdf::FinalPreview::LayerData::LayerDataList;
use base ('Packages::Pdf::ControlPdf::Helpers::FinalPreview::LayerData::LayerDataListBase');

#3th party library
use strict;
use warnings;

#local library

use aliased 'Packages::Pdf::ControlPdf::Helpers::FinalPreview::LayerData::LayerData';
use aliased 'Packages::Pdf::ControlPdf::StencilControlPdf::FinalPreview::Enums';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Connectors::HeliosConnector::HegMethods';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	return $self;
}

sub InitLayers {
	my $self = shift;

	my @pdfLayers = $self->__InitLayers(@_);

	$self->__DisableLayer( \@pdfLayers );

	$self->_SetLayers( \@pdfLayers );

}

# Set surfaces + set special surface effect by layer type
sub InitSurfaces {
	my $self   = shift;
	my $colors = shift;

	$self->_SetColors($colors);

}

# Return background color of final image
# if image has white mask, background will be pink
sub GetBackground {
	my $self = shift;

	return "255,255,255";    # white
}

#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

sub __InitLayers {
	my $self      = shift;
	my @boardL = @{ shift(@_) };

	my $jobId = $self->{"jobId"};
	my $inCAM = $self->{"inCAM"};

	# Go through job matrix and prepare job layers by proper direction from TOP to BOT (seen from TOP)
	my @pdfLayers = ();

	# 1) Prepare layers which are visible from both sides TOP and BOT

	my @TOPBOTLayers = ();

	# POS 8: Type_FIDUCPOS from TOP
	my $LFiducPosTOPBOT = LayerData->new( Enums->Type_FIDUCPOS, Enums->Visible_FROMTOPBOT );
	$LFiducPosTOPBOT->AddSingleLayers( grep { $_->{"gROWname"} =~ /^ds$/ || $_->{"gROWname"} =~ /^flc$/ } @boardL );
	push( @TOPBOTLayers, $LFiducPosTOPBOT );

	# POS 7: Type_CODES from TOP
	my $LCodesTOPBOT = LayerData->new( Enums->Type_CODES, Enums->Visible_FROMTOPBOT );
	push( @TOPBOTLayers, $LCodesTOPBOT );

	# POS 6: Type_PROFILE from TOP
	my $LProfileTOPBOT = LayerData->new( Enums->Type_PROFILE, Enums->Visible_FROMTOPBOT );
	push( @TOPBOTLayers, $LProfileTOPBOT );

	# POS 4: Type_DATAPROFILE from TOP
	my $LDataProfileTOPBOT = LayerData->new( Enums->Type_DATAPROFILE, Enums->Visible_FROMTOPBOT );
	push( @TOPBOTLayers, $LDataProfileTOPBOT );

	@TOPBOTLayers = reverse(@TOPBOTLayers) if ( $self->{"viewType"} eq Enums->View_FROMBOT );

	# 2) Prepare layers which are visible either from BOT or from TOP

	# POS 3: Type_HOLES from TOP
	my $LHolesTOP = LayerData->new( Enums->Type_HOLES, Enums->Visible_FROMTOP );
	$LHolesTOP->AddSingleLayers( grep { $_->{"gROWname"} =~ /^ds$/ || $_->{"gROWname"} =~ /^flc$/ } @boardL );
	push( @pdfLayers, $LHolesTOP );

	# POS 5: Type_HALFFIDUC from TOP
	my $LHalfFiducTOP = LayerData->new( Enums->Type_HALFFIDUC, Enums->Visible_FROMTOP );
	$LHalfFiducTOP->AddSingleLayers( grep { $_->{"gROWname"} =~ /^ds$/ || $_->{"gROWname"} =~ /^flc$/ } @boardL );
	push( @pdfLayers, $LHalfFiducTOP );

	# POS 2: Type_COVER from TOP
	my $LCoverTOP = LayerData->new( Enums->Type_COVER, Enums->Visible_FROMTOP );
	push( @pdfLayers, $LCoverTOP );

	# POS 1: Type_STNCLMAT from TOP
	my $LStnclMatTOPBOT = LayerData->new( Enums->Type_STNCLMAT, Enums->Visible_FROMTOPBOT );
	push( @pdfLayers, $LStnclMatTOPBOT );

	# POS 2: Type_COVER from BOT
	my $LCoverBOT = LayerData->new( Enums->Type_COVER, Enums->Visible_FROMBOT );
	push( @pdfLayers, $LCoverBOT );

	# POS 5: Type_HALFFIDUC from TOP
	my $LHalfFiducBOT = LayerData->new( Enums->Type_HALFFIDUC, Enums->Visible_FROMBOT );
	$LHalfFiducBOT->AddSingleLayers( grep { $_->{"gROWname"} =~ /^ds$/ || $_->{"gROWname"} =~ /^flc$/ } @boardL );
	push( @pdfLayers, $LHalfFiducBOT );

	my $LHolesBOT = LayerData->new( Enums->Type_HOLES, Enums->Visible_FROMBOT );
	$LHolesBOT->AddSingleLayers( grep { $_->{"gROWname"} =~ /^ds$/ || $_->{"gROWname"} =~ /^flc$/ } @boardL );
	push( @pdfLayers, $LHolesBOT );

	@pdfLayers = reverse(@pdfLayers) if ( $self->{"viewType"} eq Enums->View_FROMBOT );

	unshift( @pdfLayers, @TOPBOTLayers );

	return @pdfLayers;

	#	# Set layers fro VIEW from TOP
	#
	#	if ( $self->{"viewType"} eq Enums->View_FROMTOP ) {
	#
	#		foreach my $l (@allLayers) {
	#
	#			if ( $l->{"gROWname"} =~ /^ds$/ || $l->{"gROWname"} =~ /^flc$/ ) {
	#
	#				$self->_AddToLayerData( $l, Enums->Type_HOLES );
	#				$self->_AddToLayerData( $l, Enums->Type_HALFFIDUC );
	#				$self->_AddToLayerData( $l, Enums->Type_FIDUCPOS );
	#
	#			}
	#		}
	#
	#	}
}

# Make some layer NON active depends of PCB type and view side
sub __DisableLayer {
	my $self      = shift;
	my $pdfLayers = shift;

	my $jobId = $self->{"jobId"};
	my $inCAM = $self->{"inCAM"};

	if ( $self->{"viewType"} eq Enums->View_FROMTOP ) {

		$_->SetIsActive(0) for ( grep { $_->GetVisibleFrom() eq Enums->Visible_FROMBOT } @{$pdfLayers} );

	}
	elsif ( $self->{"viewType"} eq Enums->View_FROMBOT ) {

		$_->SetIsActive(0) for ( grep { $_->GetVisibleFrom() eq Enums->Visible_FROMTOP } @{$pdfLayers} );
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

