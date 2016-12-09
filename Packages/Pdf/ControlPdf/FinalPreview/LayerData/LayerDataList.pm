
#-------------------------------------------------------------------------------------------#
# Description: Special layer - Copper, contain special propery and operation for this
# type of layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::FinalPreview::LayerData::LayerDataList;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Pdf::ControlPdf::FinalPreview::LayerData::LayerData';
use aliased 'Packages::Pdf::ControlPdf::FinalPreview::Enums';
use aliased 'Enums::EnumsGeneral';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"viewType"} = shift;
	my @l = ();
	$self->{"layers"} = \@l;

	$self->__InitLayers();

	return $self;
}

sub __InitLayers {
	my $self = shift;

	# layer data are sorted by final order of printing

	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_PCBMAT ) );
	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_OUTERCU ) );
	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_MASK ) );
	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_SILK ) );
	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_PLTDEPTHNC ) );
	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_NPLTDEPTHNC ) );
	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_THROUGHNC ) );
}

sub GetLayers {
	my $self = shift;

	return @{ $self->{"layers"} };
}


sub GetLayerByType {
	my $self = shift;
	my $type = shift;

	my $layer = ( grep { $_->GetType() eq $type } @{ $self->{"layers"} } )[0];

	return $layer;

}

sub SetLayers {
	my $self        = shift;
	my @boardLayers = @{ shift(@_) };

	# Set layers fro VIEW from TOP

	if ( $self->{"viewType"} eq Enums->View_FROMTOP ) {

		foreach my $l (@boardLayers) {
			if ( $l->{"gROWname"} =~ /^c$/ ) {

				$self->__AddToLayerData( $l, Enums->Type_OUTERCU );

			}
			elsif ( $l->{"gROWname"} =~ /^mc$/ ) {

				$self->__AddToLayerData( $l, Enums->Type_MASK );

			}
			elsif ( $l->{"gROWname"} =~ /^pc$/ ) {

				$self->__AddToLayerData( $l, Enums->Type_SILK );

			}
			elsif ( $l->{"type"} =~ EnumsGeneral->LAYERTYPE_plt_bDrillTop || $l->{"type"} =~ EnumsGeneral->LAYERTYPE_plt_bMillTop ) {

				$self->__AddToLayerData( $l, Enums->Type_PLTDEPTHNC );

			}
			elsif ( $l->{"type"} =~ EnumsGeneral->LAYERTYPE_nplt_bMillTop || $l->{"type"} =~ EnumsGeneral->LAYERTYPE_nplt_score ) {

				$self->__AddToLayerData( $l, Enums->Type_NPLTDEPTHNC );

			}
			elsif (    $l->{"type"} =~ EnumsGeneral->LAYERTYPE_plt_nMill
					|| $l->{"type"} =~ EnumsGeneral->LAYERTYPE_nplt_nMill
					|| $l->{"type"} =~ EnumsGeneral->LAYERTYPE_plt_nDrill
					|| $l->{"type"} =~ EnumsGeneral->LAYERTYPE_nplt_rsMill
					|| $l->{"type"} =~ EnumsGeneral->LAYERTYPE_nplt_kMill )
			{

				$self->__AddToLayerData( $l, Enums->Type_THROUGHNC );

			}
		}

	}

	# Set layers fro VIEW from BOT

	if ( $self->{"viewType"} eq Enums->View_FROMBOT ) {

		foreach my $l (@boardLayers) {

			if ( $l->{"gROWname"} =~ /^s$/ ) {

				$self->__AddToLayerData( $l, Enums->Type_OUTERCU );

			}
			elsif ( $l->{"gROWname"} =~ /^ms$/ ) {

				$self->__AddToLayerData( $l, Enums->Type_MASK );

			}
			elsif ( $l->{"gROWname"} =~ /^ps$/ ) {

				$self->__AddToLayerData( $l, Enums->Type_SILK );

			}
			elsif ( $l->{"type"} =~ EnumsGeneral->LAYERTYPE_plt_bDrillBot || $l->{"type"} =~ EnumsGeneral->LAYERTYPE_plt_bMillBot ) {

				$self->__AddToLayerData( $l, Enums->Type_PLTDEPTHNC );

			}
			elsif ( $l->{"type"} =~ EnumsGeneral->LAYERTYPE_nplt_bMillBot || $l->{"type"} =~ EnumsGeneral->LAYERTYPE_nplt_score ) {

				$self->__AddToLayerData( $l, Enums->Type_NPLTDEPTHNC );

			}
			elsif (    $l->{"type"} =~ EnumsGeneral->LAYERTYPE_plt_nMill
					|| $l->{"type"} =~ EnumsGeneral->LAYERTYPE_nplt_nMill
					|| $l->{"type"} =~ EnumsGeneral->LAYERTYPE_plt_nDrill
					|| $l->{"type"} =~ EnumsGeneral->LAYERTYPE_nplt_rsMill
					|| $l->{"type"} =~ EnumsGeneral->LAYERTYPE_nplt_kMill )
			{

				$self->__AddToLayerData( $l, Enums->Type_THROUGHNC );

			}
		}

	}

}

sub SetColors {
	my $self   = shift;
	my $colors = shift;

	foreach my $l ( @{ $self->{"layers"} } ) {

		$l->SetColor( $colors->{ $l->GetType() } );
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

