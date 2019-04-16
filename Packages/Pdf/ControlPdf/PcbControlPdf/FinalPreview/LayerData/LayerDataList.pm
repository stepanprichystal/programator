
#-------------------------------------------------------------------------------------------#
# Description: Prepare special structure "LayerData" for each exported layer.
# This sctructure contain list <LayerData> and operations with this items
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::PcbControlPdf::FinalPreview::LayerData::LayerDataList;
use base ('Packages::Pdf::ControlPdf::Helpers::FinalPreview::LayerData::LayerDataListBase');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Pdf::ControlPdf::Helpers::FinalPreview::LayerData::LayerData';
use aliased 'Packages::Pdf::ControlPdf::PcbControlPdf::FinalPreview::Enums';
use aliased 'Packages::Pdf::ControlPdf::Helpers::FinalPreview::Enums' => 'PrevEnums';
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

	$self->{"viewType"} = shift;

	$self->__InitLayers();

	return $self;
}

sub __InitLayers {
	my $self = shift;

	# layer data are sorted by final order of printing

	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_PCBMAT ) );
	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_VIAFILL ) );
	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_OUTERCU ) );
	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_OUTERSURFACE ) );
	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_PLTDEPTHNC ) );
	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_NPLTDEPTHNC ) );
	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_MASK ) );
	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_SILK ) );
	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_PLTTHROUGHNC ) );
	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_NPLTTHROUGHNC ) );
	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_GOLDFINGER ) );
	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_PEELABLE ) );
	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_GRAFIT ) );
}

sub SetLayers {
	my $self        = shift;
	my @boardLayers = @{ shift(@_) };

	# Set layers fro VIEW from TOP

	if ( $self->{"viewType"} eq Enums->View_FROMTOP ) {

		foreach my $l (@boardLayers) {

			if ( $l->{"gROWname"} =~ /^c$/ ) {

				$self->_AddToLayerData( $l, Enums->Type_OUTERCU );
				$self->_AddToLayerData( $l, Enums->Type_OUTERSURFACE );

			}

			if ( $l->{"gROWname"} =~ /^mc$/ ) {

				$self->_AddToLayerData( $l, Enums->Type_MASK );

			}

			if ( $l->{"gROWname"} =~ /^pc$/ ) {

				$self->_AddToLayerData( $l, Enums->Type_SILK );

			}

			if ( $l->{"gROWname"} =~ /^goldc$/ ) {

				$self->_AddToLayerData( $l, Enums->Type_GOLDFINGER );

			}

			if ( $l->{"gROWname"} =~ /^lc$/ ) {

				$self->_AddToLayerData( $l, Enums->Type_PEELABLE );

			}

			if ( $l->{"gROWname"} =~ /^gc$/ ) {

				$self->_AddToLayerData( $l, Enums->Type_GRAFIT );

			}

			if ( $l->{"type"}
				 && ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillTop || $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillTop ) )
			{

				$self->_AddToLayerData( $l, Enums->Type_PLTDEPTHNC );

			}

			if ( $l->{"type"} && ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillTop || $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_score ) ) {

				$self->_AddToLayerData( $l, Enums->Type_NPLTDEPTHNC );

			}

			if (
				$l->{"type"}
				&& (
					   $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nMill
					|| $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nDrill
					|| $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillTop
					|| $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillBot

				)
			  )
			{

				$self->_AddToLayerData( $l, Enums->Type_PLTTHROUGHNC );

			}

			if (
				 $l->{"type"}
				 && (    $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_nMill
					  || $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_rsMill
					  || $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_kMill
					  || $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillTop
					  || $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillBot )
			  )
			{

				$self->_AddToLayerData( $l, Enums->Type_NPLTTHROUGHNC );

			}
			elsif (
					$l->{"type"}
					&& (    $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nFillDrill
						 || $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bFillDrillTop )
			  )
			{

				$self->_AddToLayerData( $l, Enums->Type_VIAFILL );

			}
		}

	}

	# Set layers fro VIEW from BOT

	if ( $self->{"viewType"} eq Enums->View_FROMBOT ) {

		foreach my $l (@boardLayers) {

			if ( $l->{"gROWname"} =~ /^s$/ ) {

				$self->_AddToLayerData( $l, Enums->Type_OUTERCU );
				$self->_AddToLayerData( $l, Enums->Type_OUTERSURFACE );

			}

			if ( $l->{"gROWname"} =~ /^ms$/ ) {

				$self->_AddToLayerData( $l, Enums->Type_MASK );

			}

			if ( $l->{"gROWname"} =~ /^ps$/ ) {

				$self->_AddToLayerData( $l, Enums->Type_SILK );

			}

			if ( $l->{"gROWname"} =~ /^golds$/ ) {

				$self->_AddToLayerData( $l, Enums->Type_GOLDFINGER );

			}

			if ( $l->{"gROWname"} =~ /^ls$/ ) {

				$self->_AddToLayerData( $l, Enums->Type_PEELABLE );

			}

			if ( $l->{"gROWname"} =~ /^gs$/ ) {

				$self->_AddToLayerData( $l, Enums->Type_GRAFIT );

			}

			if ( $l->{"type"}
				 && ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillBot || $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillBot ) )
			{

				$self->_AddToLayerData( $l, Enums->Type_PLTDEPTHNC );

			}

			if ( $l->{"type"}
				 && ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillBot || $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_score ) )
			{

				$self->_AddToLayerData( $l, Enums->Type_NPLTDEPTHNC );

			}

			if (
				$l->{"type"}
				&& (
					   $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nMill
					|| $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nDrill
					|| $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillTop
					|| $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillBot

				)
			  )
			{

				$self->_AddToLayerData( $l, Enums->Type_PLTTHROUGHNC );

			}

			if (
				 $l->{"type"}
				 && (    $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_nMill
					  || $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_rsMill
					  || $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_kMill
					  || $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillTop
					  || $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillBot )
			  )

			{

				$self->_AddToLayerData( $l, Enums->Type_NPLTTHROUGHNC );

			}elsif (
					$l->{"type"}
					&& (    $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nFillDrill
						 || $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bFillDrillBot )
			  )
			{

				$self->_AddToLayerData( $l, Enums->Type_VIAFILL );

			}
		}
	}
}

sub SetColors {
	my $self   = shift;
	my $colors = shift;

	$self->_SetColors($colors);

	# set color for THROUGH type of layers, according background

	my $background = $self->GetBackground();

	my $plt  = $self->GetLayerByType( Enums->Type_PLTTHROUGHNC );
	my $nplt = $self->GetLayerByType( Enums->Type_NPLTTHROUGHNC );

	$plt->GetSurface()->SetColor($background);
	$nplt->GetSurface()->SetColor($background);
}

# Return background color of final image
# if image has white mask, background will be pink
sub GetBackground {
	my $self = shift;

	my $l    = $self->GetLayerByType( Enums->Type_MASK );
	my $surf = $l->GetSurface();

	if ( $surf->GetType() eq PrevEnums->Surface_COLOR && $surf->GetColor() eq "250,250,250" ) {

		return "153,217,234";    # pink

	}
	else {

		return "255,255,255";    # white
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

