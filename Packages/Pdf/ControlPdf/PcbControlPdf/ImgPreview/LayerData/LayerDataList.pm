
#-------------------------------------------------------------------------------------------#
# Description: Prepare special structure "LayerData" for each exported layer.
# This sctructure contain list <LayerData> and operations with this items
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::PcbControlPdf::ImgPreview::LayerData::LayerDataList;
use base ('Packages::Pdf::ControlPdf::Helpers::ImgPreview::LayerData::LayerDataListBase');

#3th party library
use strict;
use warnings;
use List::MoreUtils qw(first_index last_index);

#local library
use aliased 'Packages::Pdf::ControlPdf::Helpers::ImgPreview::LayerData::LayerData';
use aliased 'Packages::Pdf::ControlPdf::PcbControlPdf::ImgPreview::Enums';
use aliased 'Packages::Pdf::ControlPdf::Helpers::ImgPreview::Enums' => 'PrevEnums';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamHistogram';
use aliased 'CamHelpers::CamJob';
use aliased 'Helpers::JobHelper';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::Stackup::Enums' => 'EnumsStack';
use aliased 'Packages::Stackup::StackupOperation';

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
	my $self   = shift;
	my $inCAM  = shift;
	my $jobId  = shift;
	my $layers = shift;

	my @pdfLayers = $self->__InitLayers( $inCAM, $jobId, $layers );

	$self->__DisableLayer( $inCAM, $jobId, \@pdfLayers );

	$self->_SetLayers( \@pdfLayers );
}

# Set surfaces + set special surface effect by layer type
sub InitSurfaces {
	my $self   = shift;
	my $colors = shift;

	$self->_SetColors($colors);

	# 1) Set color for THROUGH type of layers, according background

	my $background = $self->GetBackground();

	foreach my $l ( $self->GetLayers( Enums->Type_PLTTHROUGHNC ) ) {

		$l->GetSurface()->SetColor( $self->GetBackground() );
		$l->GetSurface()->SetColor( $self->GetBackground() );
	}

	foreach my $l ( $self->GetLayers( Enums->Type_NPLTTHROUGHNC ) ) {

		$l->GetSurface()->SetColor( $self->GetBackground() );
		$l->GetSurface()->SetColor( $self->GetBackground() );
	}

	# 2) Set 3D edge for Cu visible from top side
	my @CuLayers3D = ();

	if ( $self->{"viewType"} eq Enums->View_FROMTOP ) {

		push( @CuLayers3D, $self->GetLayers( Enums->Type_OUTERCU, Enums->Visible_FROMTOP ) );
		push( @CuLayers3D, $self->GetLayers( Enums->Type_INNERCU, Enums->Visible_FROMTOP ) );

	}
	elsif ( $self->{"viewType"} eq Enums->View_FROMBOT ) {

		push( @CuLayers3D, $self->GetLayers( Enums->Type_OUTERCU, Enums->Visible_FROMBOT ) );
		push( @CuLayers3D, $self->GetLayers( Enums->Type_INNERCU, Enums->Visible_FROMBOT ) );
	}

	$_->GetSurface()->Set3DEdges(1) foreach (@CuLayers3D);

	# Set Cu visible through flex core little darker
	my @CuFromBack = ();
	if ( $self->{"viewType"} eq Enums->View_FROMTOP ) {

		push( @CuFromBack, $self->GetLayers( Enums->Type_OUTERCU, Enums->Visible_FROMBOT ) );
		push( @CuFromBack, $self->GetLayers( Enums->Type_INNERCU, Enums->Visible_FROMBOT ) );

	}
	elsif ( $self->{"viewType"} eq Enums->View_FROMBOT ) {

		push( @CuFromBack, $self->GetLayers( Enums->Type_OUTERCU, Enums->Visible_FROMTOP ) );
		push( @CuFromBack, $self->GetLayers( Enums->Type_INNERCU, Enums->Visible_FROMTOP ) );
	}

	$_->GetSurface()->SetBrightness( $_->GetSurface()->GetBrightness() - 40 ) foreach (@CuFromBack);

	# 3)  Set 3D edge for peealble
	$_->GetSurface()->Set3DEdges(5) foreach ( $self->GetLayers( Enums->Type_PEELABLE ) );

	# 4) Set 3d Edges for Flexible mask
	my @flex3D = ();
	if ( $self->{"viewType"} eq Enums->View_FROMTOP ) {

		push( @flex3D, $self->GetLayers( Enums->Type_FLEXMASK, Enums->Visible_FROMTOP ) );

	}
	elsif ( $self->{"viewType"} eq Enums->View_FROMBOT ) {

		push( @flex3D, $self->GetLayers( Enums->Type_FLEXMASK, Enums->Visible_FROMBOT ) );
	}

	$_->GetSurface()->Set3DEdges(4) foreach (@flex3D);

}

# Return background color of final image
# if image has white mask, background will be pink
sub GetBackground {
	my $self = shift;

	my $backg = "255,255,255";    # white

	# 1) If white solder mask, set light blue background
	my @l =
	  $self->GetLayers( Enums->Type_MASK, ( $self->{"viewType"} eq Enums->View_FROMTOP ? Enums->Visible_FROMTOP : Enums->Visible_FROMBOT ) );

	if ( defined $l[0] && $l[0]->HasLayers() ) {
		my $surf = $l[0]->GetSurface();

		if ( $surf->GetType() eq PrevEnums->Surface_COLOR && $surf->GetColor() eq "250,250,250" ) {

			$backg = "153,217,234";    # light blue
		}

	}

	# 1) If Al core or Cu core from TOP set light blue
	my @lMat = $self->GetLayers( Enums->Type_RIGIDMATOUTER, Enums->Visible_FROMTOPBOT );

	if ( defined $lMat[0] ) {
		my $surf = $lMat[0]->GetSurface();

		if ( $surf->GetType() eq PrevEnums->Surface_COLOR && $surf->GetColor() eq "240, 240, 240" ) {

			$backg = "153,217,234";    # light blue
		}

	}

	return $backg;
}

#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

sub __InitLayers {
	my $self   = shift;
	my $inCAM  = shift;
	my $jobId  = shift;
	my $layers = shift;

	my @boardL = @{$layers};

	# Go through job matrix and prepare job layers by proper direction from TOP to BOT (seen from TOP)
	# By order is mean physical order of all layers ( plus order of NC operations) on PCB

	my @pdfLayers = ();
	my $layerCnt  = CamJob->GetSignalLayer( $inCAM, $jobId );
	my $stackup   = Stackup->new( $inCAM, $jobId ) if ( $layerCnt > 2 );
	my $isFlex    = JobHelper->GetIsFlex($jobId);

	# 1) Prepare layers which are visible  from both sides TOP and BOT

	my @NCThroughLayers = ();

	# POS 0.f: Type_NPLTTHROUGHNC from TOP or BOT
	my $LDNPltThrough = LayerData->new( Enums->Type_NPLTTHROUGHNC, Enums->Visible_FROMTOPBOT );
	$LDNPltThrough->AddSingleLayers(
		grep {
			defined $_->{"type"}
			  && (    $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_nMill
				   || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_rsMill
				   || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_kMill
				   || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillTop
				   || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillBot )
		} @boardL
	);

	push( @NCThroughLayers, $LDNPltThrough );

	# POS 0: Type_PLTTHROUGHNC from TOP
	my $LDPltThroughTOPBOT = LayerData->new( Enums->Type_PLTTHROUGHNC, Enums->Visible_FROMTOPBOT );
	$LDPltThroughTOPBOT->AddSingleLayers(
		grep {
			defined $_->{"type"}
			  && (    $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nMill
				   || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nDrill
				   || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillTop
				   || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillBot )
		} @boardL
	);
	push( @pdfLayers, $LDPltThroughTOPBOT );

	@NCThroughLayers = reverse(@NCThroughLayers) if ( $self->{"viewType"} eq Enums->View_FROMBOT );

	# 2) Prepare layers which are visible either from BOT or from TOP

	# POS 1: Type_NPLTDEPTHNC from TOP
	my $LDNPltDepthTOP = LayerData->new( Enums->Type_NPLTDEPTHNC, Enums->Visible_FROMTOP );
	$LDNPltDepthTOP->AddSingleLayers(
		grep {
			$_->{"type"}
			  && (    $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillTop
				   || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bstiffcMill
				   || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_score )
		} @boardL
	);
	push( @pdfLayers, $LDNPltDepthTOP );

	# POS 2: Type_TAPE from TOP
	my $LDTapestiffTOP = LayerData->new( Enums->Type_TAPE, Enums->Visible_FROMTOP );
	$LDTapestiffTOP->AddSingleLayers( grep { $_->{"gROWname"} =~ /^tpstiffc$/ } @boardL );
	push( @pdfLayers, $LDTapestiffTOP );

	# POS 3: Type_STIFFENER from TOP
	my $LDStiffenerTOP = LayerData->new( Enums->Type_STIFFENER, Enums->Visible_FROMTOP );
	$LDStiffenerTOP->AddSingleLayers( grep { $_->{"gROWname"} =~ /^stiffc$/ } @boardL );    #  stiffener
	$LDStiffenerTOP->AddSingleLayers( grep { $_->{"gROWname"} =~ /^tpc$/ } @boardL );    # tape also define stiffener
	$LDStiffenerTOP->AddSingleLayers( grep { defined $_->{"type"} && $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_stiffcMill } @boardL );
	$LDStiffenerTOP->AddSingleLayers( grep { defined $_->{"type"} && $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bStiffcAdhMillTop } @boardL );
	$LDStiffenerTOP->AddSingleLayers( grep { defined $_->{"type"} && $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_tapebrMill } @boardL )
	  ;                                                                                  # tape bridge also define stiffener
	push( @pdfLayers, $LDStiffenerTOP );

	# POS 2: Type_TAPE from TOP
	my $LDTapeTOP = LayerData->new( Enums->Type_TAPE, Enums->Visible_FROMTOP );
	$LDTapeTOP->AddSingleLayers( grep { $_->{"gROWname"} =~ /^tpc$/ } @boardL );
	push( @pdfLayers, $LDTapeTOP );

	# POS 2: Type_TAPEBACK from TOP
	my $LDTapeBackTOP = LayerData->new( Enums->Type_TAPEBACK, Enums->Visible_FROMTOP );
	$LDTapeBackTOP->AddSingleLayers( grep { $_->{"gROWname"} =~ /^tpc$/ } @boardL );
	push( @pdfLayers, $LDTapeBackTOP );

	# POS 4: Type_GRAFIT from TOP
	my $LDGraffitTOP = LayerData->new( Enums->Type_GRAFIT, Enums->Visible_FROMTOP );
	$LDGraffitTOP->AddSingleLayers( grep { $_->{"gROWname"} =~ /^gc$/ } @boardL );
	push( @pdfLayers, $LDGraffitTOP );

	# POS 5: Type_PEELABLE from TOP
	my $LDPeelableTOP = LayerData->new( Enums->Type_PEELABLE, Enums->Visible_FROMTOP );
	$LDPeelableTOP->AddSingleLayers( grep { $_->{"gROWname"} =~ /^lc$/ } @boardL );
	push( @pdfLayers, $LDPeelableTOP );

	# POS 6: Type_GOLDFINGER from TOP
	my $LDGoldfingerTOP = LayerData->new( Enums->Type_GOLDFINGER, Enums->Visible_FROMTOP );
	$LDGoldfingerTOP->AddSingleLayers( grep { $_->{"gROWname"} =~ /^goldc$/ } @boardL );
	push( @pdfLayers, $LDGoldfingerTOP );

	# POS 7: Type_SILK2 from TOP
	my $LDSilk2TOP = LayerData->new( Enums->Type_SILK2, Enums->Visible_FROMTOP );
	$LDSilk2TOP->AddSingleLayers( grep { $_->{"gROWname"} =~ /^pc2$/ } @boardL );
	push( @pdfLayers, $LDSilk2TOP );

	# POS 8: Type_SILK from TOP
	my $LDSilkTOP = LayerData->new( Enums->Type_SILK, Enums->Visible_FROMTOP );
	$LDSilkTOP->AddSingleLayers( grep { $_->{"gROWname"} =~ /^pc$/ } @boardL );
	push( @pdfLayers, $LDSilkTOP );

	# POS 9: Type_FLEXMASK from TOP
	my $LDMaskFlexTOP = LayerData->new( Enums->Type_FLEXMASK, Enums->Visible_FROMTOP );
	$LDMaskFlexTOP->AddSingleLayers( grep { $_->{"gROWname"} =~ /^mcflex$/ } @boardL );
	push( @pdfLayers, $LDMaskFlexTOP );

	# POS 10: Type_MASK2 from TOP
	my $LDMask2TOP = LayerData->new( Enums->Type_MASK2, Enums->Visible_FROMTOP );
	$LDMask2TOP->AddSingleLayers( grep { $_->{"gROWname"} =~ /^mc2$/ } @boardL );
	push( @pdfLayers, $LDMask2TOP );

	# POS 10: Type_MASK from TOP
	my $LDMaskTOP = LayerData->new( Enums->Type_MASK, Enums->Visible_FROMTOP );
	$LDMaskTOP->AddSingleLayers( grep { $_->{"gROWname"} =~ /^mc$/ } @boardL );
	push( @pdfLayers, $LDMaskTOP );

	# POS 11: Type_PLTDEPTHNC from TOP
	my $LDPltDepthTOP = LayerData->new( Enums->Type_PLTDEPTHNC, Enums->Visible_FROMTOP );
	$LDPltDepthTOP->AddSingleLayers(
		grep {
			defined $_->{"type"}
			  && (    $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillTop
				   || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillTop )
		} @boardL
	);
	push( @pdfLayers, $LDPltDepthTOP );

	# POS 12: Type_OUTERSURFACE from TOP
	my $LDOuterSurfaceTOP = LayerData->new( Enums->Type_OUTERSURFACE, Enums->Visible_FROMTOP );
	$LDOuterSurfaceTOP->AddSingleLayers( grep { $_->{"gROWname"} =~ /^c$/ } @boardL );
	push( @pdfLayers, $LDOuterSurfaceTOP );

	# POS 13: Type_OUTERCU from TOP;
	my $LDOuterCuTOP = LayerData->new( Enums->Type_OUTERCU, Enums->Visible_FROMTOP );
	$LDOuterCuTOP->AddSingleLayers( grep { $_->{"gROWname"} =~ /^c$/ } @boardL );
	push( @pdfLayers, $LDOuterCuTOP );

	# POS 14: Type_VIAFILL from TOP
	my $LDViaFillTOP = LayerData->new( Enums->Type_VIAFILL, Enums->Visible_FROMTOP );
	$LDViaFillTOP->AddSingleLayers(
		grep {
			defined $_->{"type"}
			  && (    $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nFillDrill
				   || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bFillDrillTop )
		} @boardL
	);
	push( @pdfLayers, $LDViaFillTOP );

	# POS 15: Type_FLEXMATOUTER; Type_RIGIDMATOUTER;Type_INNERCU from TOP
	if ( $layerCnt <= 2 ) {

		# For 1v + 2v add one pcb material (flex or rigid)

		my $LDMatOuterTOP = LayerData->new( ( $isFlex ? Enums->Type_FLEXMATOUTER : Enums->Type_RIGIDMATOUTER ), Enums->Visible_FROMTOPBOT );
		push( @pdfLayers, $LDMatOuterTOP );

	}
	else {

		# For multilayer, read stackup
		my @stackupL = $stackup->GetAllLayers();
		splice @stackupL, 0, 1 if ( $stackupL[0]->GetType() eq EnumsStack->MaterialType_COVERLAY );    # Remove very top coverlay if exist
		splice @stackupL, scalar(@stackupL) - 1, 1
		  if ( $stackupL[-1]->GetType() eq EnumsStack->MaterialType_COVERLAY );                        # Remove very bot coverlay if exist

		for ( my $i = 0 ; $i < scalar(@stackupL) ; $i++ ) {

			my $l = $stackupL[$i];

			next if ( $l->GetType() eq EnumsStack->MaterialType_COPPER && ( $l->GetCopperName() =~ /^[cs]$/ ) );

			if ( $l->GetType() eq EnumsStack->MaterialType_COPPER ) {
				my $side = StackupOperation->GetSideByLayer( $inCAM, $jobId, $l->GetCopperName(), $stackup );
				my $LDInnerCu = LayerData->new( Enums->Type_INNERCU, ( $side eq "top" ? Enums->Visible_FROMTOP : Enums->Visible_FROMBOT ) );
				$LDInnerCu->AddSingleLayers( grep { $_->{"gROWname"} eq $l->GetCopperName() } @boardL );
				push( @pdfLayers, $LDInnerCu );
			}
			elsif (    $l->GetType() eq EnumsStack->MaterialType_PREPREG
					|| $l->GetType() eq EnumsStack->MaterialType_CORE )
			{

				my $position = $i == 1 || $i == scalar(@stackupL) - 2 ? "out" : "in";
				my $viewType;

				if ( $stackupL[ $i - 1 ]->GetType() eq EnumsStack->MaterialType_COPPER && $stackupL[ $i - 1 ]->GetCopperName() eq "c" ) {
					$viewType = Enums->Visible_FROMTOP;

				}
				elsif ( $stackupL[ $i + 1 ]->GetType() eq EnumsStack->MaterialType_COPPER && $stackupL[ $i + 1 ]->GetCopperName() eq "s" ) {
					$viewType = Enums->Visible_FROMBOT;
				}
				else {

					$viewType = Enums->Visible_FROMTOPBOT;
				}

				my $LDMat;

				if ( $l->GetType() eq EnumsStack->MaterialType_CORE && $l->GetCoreRigidType() eq EnumsStack->CoreType_FLEX ) {
					$LDMat = LayerData->new( $position eq "out" ? Enums->Type_FLEXMATOUTER : Enums->Type_FLEXMATINNER, $viewType );
				}
				else {

					$LDMat = LayerData->new( $position eq "out" ? Enums->Type_RIGIDMATOUTER : Enums->Type_RIGIDMATINNER, $viewType );
				}

				push( @pdfLayers, $LDMat );
			}
		}
	}

	# POS 16: Type_VIAFILL from TOP
	my $LDViaFillBOT = LayerData->new( Enums->Type_VIAFILL, Enums->Visible_FROMBOT );
	$LDViaFillBOT->AddSingleLayers(
		grep {
			defined $_->{"type"}
			  && (    $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nFillDrill
				   || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bFillDrillBot )
		} @boardL
	);
	push( @pdfLayers, $LDViaFillBOT );

	# POS 17: Type_OUTERCU from BOT
	my $LDOuterCuBOT = LayerData->new( Enums->Type_OUTERCU, Enums->Visible_FROMBOT );
	$LDOuterCuBOT->AddSingleLayers( grep { $_->{"gROWname"} eq "s" } @boardL );
	push( @pdfLayers, $LDOuterCuBOT );

	# POS 18: Type_OUTERSURFACE from BOT
	my $LDOuterSurfaceBOT = LayerData->new( Enums->Type_OUTERSURFACE, Enums->Visible_FROMBOT );
	$LDOuterSurfaceBOT->AddSingleLayers( grep { $_->{"gROWname"} eq "s" } @boardL );
	push( @pdfLayers, $LDOuterSurfaceBOT );

	# POS 19: Type_PLTDEPTHNC from BOT
	my $LDPltDepthBOT = LayerData->new( Enums->Type_PLTDEPTHNC, Enums->Visible_FROMBOT );
	$LDPltDepthBOT->AddSingleLayers(
		grep {
			defined $_->{"type"}
			  && (    $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillBot
				   || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillBot )
		} @boardL
	);
	push( @pdfLayers, $LDPltDepthBOT );

	# POS 20: Type_MASK from BOT
	my $LDMaskBOT = LayerData->new( Enums->Type_MASK, Enums->Visible_FROMBOT );
	$LDMaskBOT->AddSingleLayers( grep { $_->{"gROWname"} =~ /^ms$/ } @boardL );
	push( @pdfLayers, $LDMaskBOT );

	# POS 20: Type_MASK2 from BOT
	my $LDMask2BOT = LayerData->new( Enums->Type_MASK2, Enums->Visible_FROMBOT );
	$LDMask2BOT->AddSingleLayers( grep { $_->{"gROWname"} =~ /^ms2$/ } @boardL );
	push( @pdfLayers, $LDMask2BOT );

	# POS 21: Type_FLEXMASK from BOT
	my $LDMaskFlexBOT = LayerData->new( Enums->Type_FLEXMASK, Enums->Visible_FROMBOT );
	$LDMaskFlexBOT->AddSingleLayers( grep { $_->{"gROWname"} =~ /^msflex$/ } @boardL );
	push( @pdfLayers, $LDMaskFlexBOT );

	# POS 22: Type_SILK from BOT
	my $LDSilkBOT = LayerData->new( Enums->Type_SILK, Enums->Visible_FROMBOT );
	$LDSilkBOT->AddSingleLayers( grep { $_->{"gROWname"} =~ /^ps$/ } @boardL );
	push( @pdfLayers, $LDSilkBOT );

	# POS 23: Type_SILK2 from BOT
	my $LDSilk2BOT = LayerData->new( Enums->Type_SILK2, Enums->Visible_FROMBOT );
	$LDSilk2BOT->AddSingleLayers( grep { $_->{"gROWname"} =~ /^ps2$/ } @boardL );
	push( @pdfLayers, $LDSilk2BOT );

	# POS 24: Type_GOLDFINGER from BOT
	my $LDGoldfingerBOT = LayerData->new( Enums->Type_GOLDFINGER, Enums->Visible_FROMBOT );
	$LDGoldfingerBOT->AddSingleLayers( grep { $_->{"gROWname"} =~ /^golds$/ } @boardL );
	push( @pdfLayers, $LDGoldfingerBOT );

	# POS 25: Type_PEELABLE from BOT
	my $LDPeelableBOT = LayerData->new( Enums->Type_PEELABLE, Enums->Visible_FROMBOT );
	$LDPeelableBOT->AddSingleLayers( grep { $_->{"gROWname"} =~ /^ls$/ } @boardL );
	push( @pdfLayers, $LDPeelableBOT );

	# POS 26: Type_GRAFIT from BOT
	my $LDGraffitBOT = LayerData->new( Enums->Type_GRAFIT, Enums->Visible_FROMBOT );
	$LDGraffitBOT->AddSingleLayers( grep { $_->{"gROWname"} =~ /^gs$/ } @boardL );
	push( @pdfLayers, $LDGraffitBOT );

	# POS 28: Type_TAPEBACK from BOT
	my $LDTapeBackBOT = LayerData->new( Enums->Type_TAPEBACK, Enums->Visible_FROMBOT );
	$LDTapeBackBOT->AddSingleLayers( grep { $_->{"gROWname"} =~ /^tps$/ } @boardL );
	push( @pdfLayers, $LDTapeBackBOT );

	# POS 28: Type_TAPE from BOT
	my $LDTapeBOT = LayerData->new( Enums->Type_TAPE, Enums->Visible_FROMBOT );
	$LDTapeBOT->AddSingleLayers( grep { $_->{"gROWname"} =~ /^tps$/ } @boardL );
	push( @pdfLayers, $LDTapeBOT );

	# POS 27: Type_STIFFENER from BOT
	my $LDStiffenerBOT = LayerData->new( Enums->Type_STIFFENER, Enums->Visible_FROMBOT );
	$LDStiffenerBOT->AddSingleLayers( grep { $_->{"gROWname"} =~ /^stiffs$/ } @boardL );    # t stiffener
	$LDStiffenerBOT->AddSingleLayers( grep { $_->{"gROWname"} =~ /^tps$/ } @boardL );    # tape also define stiffener
	$LDStiffenerBOT->AddSingleLayers( grep { defined $_->{"type"} && $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_tapebrMill } @boardL );
	$LDStiffenerBOT->AddSingleLayers( grep { defined $_->{"type"} && $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_stiffsMill } @boardL );
	$LDStiffenerBOT->AddSingleLayers( grep { defined $_->{"type"} && $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bStiffsAdhMillTop } @boardL );
	push( @pdfLayers, $LDStiffenerBOT );

	# POS 2: Type_TAPE from TOP
	my $LDTapestiffBOT = LayerData->new( Enums->Type_TAPE, Enums->Visible_FROMBOT );
	$LDTapestiffBOT->AddSingleLayers( grep { $_->{"gROWname"} =~ /^tpstiffs$/ } @boardL );
	push( @pdfLayers, $LDTapestiffBOT );

	# POS 29: Type_NPLTDEPTHNC from BOT
	my $LDNPltDepthBOT = LayerData->new( Enums->Type_NPLTDEPTHNC, Enums->Visible_FROMBOT );
	$LDNPltDepthBOT->AddSingleLayers(
		grep {
			$_->{"type"}
			  && ( $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillBot || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_score )
		} @boardL
	);
	push( @pdfLayers, $LDNPltDepthBOT );

	# If exist coverlays, insert them next by proper Cu layer

	foreach my $l ( grep { $_->{"gROWlayer_type"} eq "coverlay" } @boardL ) {

		my $sigL = ( $l->{"gROWname"} =~ /^cvrl(\w*)/ )[0];

		# POS 9.f: Type_COVERLAY from TOP or BOT
		my $side;

		if ( $sigL eq "c" ) {

			$side = "top";
		}
		elsif ( $sigL eq "s" ) {

			$side = "bot";
		}
		else {
			$side = StackupOperation->GetSideByLayer( $inCAM, $jobId, $sigL, $stackup );
		}

		my $LDCoverlay = LayerData->new( Enums->Type_COVERLAY, ( $side eq "top" ? Enums->Visible_FROMTOP : Enums->Visible_FROMBOT ) );
		$LDCoverlay->AddSingleLayers($l);
		$LDCoverlay->AddSingleLayers( grep { defined $_->{"type"} && ( $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_nMill ) } @boardL );

		if ( $sigL =~ /^v\d+$/ ) {

			my $idx = first_index {
				( grep { $_->{"gROWname"} eq $sigL } $_->GetSingleLayers() )[0]

				  && (    $_->GetType() eq Enums->Type_INNERCU
					   || $_->GetType() eq Enums->Type_OUTERSURFACE )
			}
			@pdfLayers;
			splice @pdfLayers, ( $side eq "top" ? $idx : $idx + 1 ), 0, $LDCoverlay;
		}
		else {

			if ( $side eq "top" ) {

				my $idx = first_index {
					(
					   $_->GetVisibleFrom() eq Enums->Visible_FROMTOP

						 && (    $_->GetType() eq Enums->Type_PLTTHROUGHNC
							  || $_->GetType() eq Enums->Type_OUTERSURFACE )
					  )
				}
				@pdfLayers;
				splice @pdfLayers, $idx, 0, $LDCoverlay;
			}
			else {
				my $idx = last_index {
					(
					   $_->GetVisibleFrom() eq Enums->Visible_FROMBOT

						 && (    $_->GetType() eq Enums->Type_PLTTHROUGHNC
							  || $_->GetType() eq Enums->Type_OUTERSURFACE )
					  )
				}
				@pdfLayers;
				splice @pdfLayers, $idx + 1, 0, $LDCoverlay;

			}

		}

	}

	@pdfLayers = reverse(@pdfLayers) if ( $self->{"viewType"} eq Enums->View_FROMBOT );

	unshift( @pdfLayers, @NCThroughLayers );

	return @pdfLayers;

}

# Make some layer NON active depends of PCB type and view side
sub __DisableLayer {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $pdfLayers = shift;

	my $pcbType  = JobHelper->GetPcbType($jobId);
	my $isFlex   = JobHelper->GetIsFlex($jobId);
	my $layerCnt = CamJob->GetSignalLayer( $inCAM, $jobId );

	if ( $layerCnt <= 2 && !$isFlex ) {

		if ( $self->{"viewType"} eq Enums->View_FROMTOP ) {

			$_->SetIsActive(0) for ( grep { $_->GetVisibleFrom() eq Enums->Visible_FROMBOT } @{$pdfLayers} );

		}
		elsif ( $self->{"viewType"} eq Enums->View_FROMBOT ) {

			$_->SetIsActive(0) for ( grep { $_->GetVisibleFrom() eq Enums->Visible_FROMTOP } @{$pdfLayers} );
		}

	}
	elsif ( $layerCnt > 2 && !$isFlex ) {

		if ( $self->{"viewType"} eq Enums->View_FROMTOP ) {

			$_->SetIsActive(0) for ( grep { $_->GetVisibleFrom() eq Enums->Visible_FROMBOT } @{$pdfLayers} );

		}
		elsif ( $self->{"viewType"} eq Enums->View_FROMBOT ) {

			$_->SetIsActive(0) for ( grep { $_->GetVisibleFrom() eq Enums->Visible_FROMTOP } @{$pdfLayers} );
		}

		$_->SetIsActive(0) for ( grep { $_->GetType() eq Enums->Type_INNERCU || $_->GetType() eq Enums->Type_RIGIDMATINNER } @{$pdfLayers} );

	}
	elsif (    $pcbType eq EnumsGeneral->PcbType_RIGIDFLEXO
			|| $pcbType eq EnumsGeneral->PcbType_RIGIDFLEXI )
	{

		if ( $self->{"viewType"} eq Enums->View_FROMTOP ) {

			$_->SetIsActive(0) for ( grep { $_->GetVisibleFrom() eq Enums->Visible_FROMBOT } @{$pdfLayers} );

		}
		elsif ( $self->{"viewType"} eq Enums->View_FROMBOT ) {

			$_->SetIsActive(0) for ( grep { $_->GetVisibleFrom() eq Enums->Visible_FROMTOP } @{$pdfLayers} );
		}

		$_->SetIsActive(0) for ( grep { $_->GetType() eq Enums->Type_INNERCU || $_->GetType() eq Enums->Type_RIGIDMATINNER } @{$pdfLayers} );

		# Theses layers can by visible from other side (materials are transparent)

		# Include all coverlays (because it is transparent)
		$_->SetIsActive(1) for ( grep { $_->GetType() eq Enums->Type_COVERLAY } @{$pdfLayers} );

		# Include all flex mask (because it is transparent)
		$_->SetIsActive(1) for ( grep { $_->GetType() eq Enums->Type_FLEXMASK } @{$pdfLayers} );

		# Include all flex core material (because it is transparent)
		$_->SetIsActive(1) for ( grep { $_->GetType() eq Enums->Type_FLEXMATINNER || $_->GetType() eq Enums->Type_FLEXMATOUTER } @{$pdfLayers} );

		# Include all Cu on flex cores (because it is transparent)
		for ( my $i = 0 ; $i < scalar( @{$pdfLayers} ) ; $i++ ) {

			if (    $pdfLayers->[$i]->GetType() eq Enums->Type_FLEXMATINNER
				 || $pdfLayers->[$i]->GetType() eq Enums->Type_FLEXMATOUTER )
			{

				# Look for top cu
				for ( my $j = $i - 1 ; $j >= 0 ; $j-- ) {

					if ( $pdfLayers->[$j]->GetType() eq Enums->Type_OUTERCU || $pdfLayers->[$j]->GetType() eq Enums->Type_INNERCU ) {
						$pdfLayers->[$j]->SetIsActive(1);
						last;
					}
				}

				# Look for bot cu
				for ( my $j = $i + 1 ; $j < scalar( @{$pdfLayers} ) ; $j++ ) {
					if ( $pdfLayers->[$j]->GetType() eq Enums->Type_OUTERCU || $pdfLayers->[$j]->GetType() eq Enums->Type_INNERCU ) {
						$pdfLayers->[$j]->SetIsActive(1);
						last;
					}
				}

			}
		}

		# Include Rigid material from back of view side, because flex material is transparent
		if ( $pcbType eq EnumsGeneral->PcbType_RIGIDFLEXO ) {

			my $outerCore;

			if ( $self->{"viewType"} eq Enums->View_FROMTOP ) {

				$outerCore =
				  ( grep { $_->GetType() eq Enums->Type_RIGIDMATOUTER && $_->GetVisibleFrom() eq Enums->Visible_FROMBOT } @{$pdfLayers} )[0];

			}
			elsif ( $self->{"viewType"} eq Enums->View_FROMBOT ) {

				$outerCore =
				  ( grep { $_->GetType() eq Enums->Type_RIGIDMATOUTER && $_->GetVisibleFrom() eq Enums->Visible_FROMTOP } @{$pdfLayers} )[0];
			}

			$outerCore->SetIsActive(1) if ($outerCore);
		}
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

