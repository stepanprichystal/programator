
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
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::Stackup::Enums' => 'EnumsStack';

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
	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_FLEXCORE ) );
	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_VIAFILL ) );
	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_OUTERCU ) );
	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_OUTERSURFACE ) );
	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_PLTDEPTHNC ) );
	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_NPLTDEPTHNC ) );
	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_MASK ) );
	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_FLEXMASK ) );
	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_COVERLAY ) );
	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_SILK ) );
	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_SILK2 ) );
	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_PLTTHROUGHNC ) );
	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_NPLTTHROUGHNC ) );
	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_GOLDFINGER ) );
	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_PEELABLE ) );
	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_GRAFIT ) );
	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_STIFFENER ) );
}

sub InitLayers {
	my $self = shift;

	my @boardL = @{ shift(@_) };

	my $jobId = $self->{"jobId"};
	my $inCAM = $self->{"inCAM"};

	# Go through job matrix and prepare job layers by proper direction from TOP to BOT (seen from TOP)
	# By order is mean physical order of all layers ( plus order of NC operations) on PCB
	my $stackup = Stackup->new($jobId) if ( CamJob->GetSignalLayer( $inCAM, $jobId ) );

	my @l = ();

	# 1) Prepare layers which are visible either from botsh sides TOP and BOT

	# 2) Prepare layers which are visible either from BOT or from TOP

	# POS 1: Type_STIFFENER from TOP
	my $LDStiffenerTOP = LayerData->new( Enums->Type_STIFFENER, Enums->Visible_FROMTOP );
	$LDStiffenerTOP->AddLayers( grep { $_->{"gROWname"} =~ /^fstiffc\d*$/ } @boardL );
	push( @{ $self->{"layers"} }, $LDStiffenerTOP );

	# POS 2: Type_GRAFIT from TOP
	my $LDGraffitTOP = LayerData->new( Enums->Type_GRAFIT, Enums->Visible_FROMTOP );
	$LDGraffitTOP->AddLayers( grep { $_->{"gROWname"} =~ /^gc$/ } @boardL );
	push( @{ $self->{"layers"} }, $LDGraffitTOP );
	
	# POS 3: Type_PEELABLE from TOP
	my $LDPeelableTOP = LayerData->new( Enums->Type_PEELABLE, Enums->Visible_FROMTOP );
	$LDPeelableTOP->AddLayers( grep { $_->{"gROWname"} =~ /^f*lc$/ } @boardL );
	push( @{ $self->{"layers"} }, $LDPeelableTOP );
	
	# POS 4: Type_GOLDFINGER from TOP
	my $LDGoldfingerTOP = LayerData->new( Enums->Type_GOLDFINGER, Enums->Visible_FROMTOP );
	$LDGoldfingerTOP->AddLayers( grep { $_->{"gROWname"} =~ /^goldc$/ } @boardL );
	push( @{ $self->{"layers"} }, $LDGoldfingerTOP );
	
	# POS 5: Type_SILK2 from TOP
	my $LDSilk2TOP = LayerData->new( Enums->Type_SILK2, Enums->Visible_FROMTOP );
	$LDSilk2TOP->AddLayers( grep { $_->{"gROWname"} =~ /^pc2$/ } @boardL );
	push( @{ $self->{"layers"} }, $LDSilk2TOP );
	
	# POS 6: Type_SILK from TOP
	my $LDSilkTOP = LayerData->new( Enums->Type_SILK, Enums->Visible_FROMTOP );
	$LDSilkTOP->AddLayers( grep { $_->{"gROWname"} =~ /^pc$/ } @boardL );
	push( @{ $self->{"layers"} }, $LDSilkTOP );
	
	# POS 7: Type_MASK from TOP
	my $LDMaskTOP = LayerData->new( Enums->Type_MASK, Enums->Visible_FROMTOP );
	$LDMaskTOP->AddLayers( grep { $_->{"gROWname"} =~ /^mc$/ } @boardL );
	push( @{ $self->{"layers"} }, $LDMaskTOP );
 
 
	# POS: Type_OUTERCU, Type_INNERCU, Type_COVERLAY   - auter cu auter  surface ?????????????
	my $consider = 0;
	for ( my $i = scalar(@boardLayers) - 1 ; $i >= 0 ; $i-- ) {

		$consider = 1 if (    $boardLayers[$i]->{"gROWlayer_type"} eq "signal"
						   || $boardLayers[$i]->{"gROWname"} eq "covelrays" );

		if ($consider) {

			if ( $boardLayers[$i]->{"gROWname"} eq "s" ) {

				push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_OUTERCU, Enums->Visible_FROMBOT ) );
			}
			elsif ( $boardLayers[$i]->{"gROWname"} eq "c" ) {

				push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_OUTERCU, Enums->Visible_FROMTOP ) );
			}
			elsif ( $boardLayers[$i]->{"gROWname"} =~ /^v\d+$/ ) {

				my $side = StackupOperation->GetSideByLayer( $jobId, $boardLayers[$i]->{"gROWname"}, $stackup );
				my $visibleFrom = ( $side eq EnumsStack->SignalLayer_TOP ? Enums->Visible_FROMTOP : Enums->Visible_FROMBOT );
				push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_INNERCU, $visibleFrom ) );

				if ( $boardLayers[$i]->{"gROWname"} eq "c" || $boardLayers[$i]->{"gROWname"} eq "covelrayc" ) {
					last;
				}
			}
			elsif ( $boardLayers[$i]->{"gROWname"} =~ /^coverlay(\w+)$/ ) {

				my $side = StackupOperation->GetSideByLayer( $jobId, $1, $stackup );
				my $visibleFrom = ( $side eq EnumsStack->SignalLayer_TOP ? Enums->Visible_FROMTOP : Enums->Visible_FROMBOT );
				push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_COVERLAY, $visibleFrom ) );

			}

			if ( $boardLayers[$i]->{"gROWname"} eq "c" || $boardLayers[$i]->{"gROWname"} eq "covelrayc" ) {
				last;
			}

		}

		if ( $l->{"gROWname"} =~ /^fstiffs\d*$/ ) {

			$self->_AddToLayerData( $l, Enums->Type_STIFFENER );

		}

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

				if ( $l->{"gROWname"} =~ /^pc2$/ ) {

					$self->_AddToLayerData( $l, Enums->Type_SILK2 );
				}

				if ( $l->{"gROWname"} =~ /^goldc$/ ) {

					$self->_AddToLayerData( $l, Enums->Type_GOLDFINGER );

				}

				if ( $l->{"gROWname"} =~ /^f*lc$/ ) {

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

				if ( $l->{"type"} && ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillTop || $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_score ) )
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

				if ( $l->{"gROWname"} =~ /^ps\d?$/ ) {

					$self->_AddToLayerData( $l, Enums->Type_SILK );

				}

				if ( $l->{"gROWname"} =~ /^ps2$/ ) {

					$self->_AddToLayerData( $l, Enums->Type_SILK2 );
				}

				if ( $l->{"gROWname"} =~ /^golds$/ ) {

					$self->_AddToLayerData( $l, Enums->Type_GOLDFINGER );

				}

				if ( $l->{"gROWname"} =~ /^fls$/ ) {

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

				}
				elsif (
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

	sub InitColorsColors {
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

