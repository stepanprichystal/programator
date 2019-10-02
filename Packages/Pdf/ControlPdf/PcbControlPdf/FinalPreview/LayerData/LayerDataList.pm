
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
use List::MoreUtils qw(first_index);

#local library
use aliased 'Packages::Pdf::ControlPdf::Helpers::FinalPreview::LayerData::LayerData';
use aliased 'Packages::Pdf::ControlPdf::PcbControlPdf::FinalPreview::Enums';
use aliased 'Packages::Pdf::ControlPdf::Helpers::FinalPreview::Enums' => 'PrevEnums';
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
	my $self = shift;

	my @pdfLayers = $self->__InitLayers(@_);
	
	$self->__DisableLayer( \@pdfLayers );
	
	@pdfLayers = reverse(@pdfLayers);

	$self->{"layers"} = \@pdfLayers;

}

# Set surfaces + set special surface effect by layer type
sub InitSurfaces {
	my $self   = shift;
	my $colors = shift;

	$self->_SetColors($colors);

	# 1) Set color for THROUGH type of layers, according background

	my $background = $self->GetBackground();

	my $plt  = ( $self->GetLayers( Enums->Type_PLTTHROUGHNC ) )[0];
	my $nplt = ( $self->GetLayers( Enums->Type_NPLTTHROUGHNC ) )[0];

	$plt->GetSurface()->SetColor( $self->GetBackground() );
	$nplt->GetSurface()->SetColor( $self->GetBackground() );

	# 2) Set 3D edge for Cu visible from top side
	my @CuLayers3D = ();
	
	if ( $self->{"viewType"} eq Enums->View_FROMTOP ) {
		
		push(@CuLayers3D, $self->GetLayers( Enums->Type_OUTERCU, Enums->Visible_FROMTOP ));
		push(@CuLayers3D, $self->GetLayers( Enums->Type_INNERCU, Enums->Visible_FROMTOP ));
  
	}
	elsif ( $self->{"viewType"} eq Enums->View_FROMBOT ) {
		
		push(@CuLayers3D, $self->GetLayers( Enums->Type_OUTERCU, Enums->Visible_FROMBOT ));
		push(@CuLayers3D, $self->GetLayers( Enums->Type_INNERCU, Enums->Visible_FROMBOT ));
	}

	$_->GetSurface()->Set3DEdges(1) foreach (@CuLayers3D);
	
	
	# 3)  Set 3D edge for peealble
	$_->GetSurface()->Set3DEdges(5)	foreach ($self->GetLayers( Enums->Type_PEELABLE));
}




# Return background color of final image
# if image has white mask, background will be pink
sub GetBackground {
	my $self = shift;

	my $backg = "255,255,255";    # white

	my @l =
	  $self->GetLayers( Enums->Type_MASK, ( $self->{"viewType"} eq Enums->View_FROMTOP ? Enums->Visible_FROMTOP : Enums->Visible_FROMBOT ) );

	if ( defined $l[0] ) {
		my $surf = $l[0]->GetSurface();

		if ( $surf->GetType() eq PrevEnums->Surface_COLOR && $surf->GetColor() eq "250,250,250" ) {

			$backg = "153,217,234";    # pink
		}

	}

	return $backg;
}

#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

sub __InitLayers {
	my $self = shift;

	my @boardL = @{ shift(@_) };

	my $jobId = $self->{"jobId"};
	my $inCAM = $self->{"inCAM"};

	# Go through job matrix and prepare job layers by proper direction from TOP to BOT (seen from TOP)
	# By order is mean physical order of all layers ( plus order of NC operations) on PCB

	my @pdfLayers = ();
	my $layerCnt  = CamJob->GetSignalLayer( $inCAM, $jobId );
	my $stackup   = Stackup->new($jobId) if ( $layerCnt > 2 );
	my $isFlex    = JobHelper->GetIsFlex($jobId);

	# 1) Prepare layers which are visible either from botsh sides TOP and BOT

	my @NCThroughLayers = ();

	# POS 9.f: Type_PLTTHROUGHNC from TOP or BOT
	my $LDNPltThrough = LayerData->new( Enums->Type_NPLTTHROUGHNC, Enums->Visible_FROMTOPBOT );
	$LDNPltThrough->AddSingleLayers(
		grep {
			     $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_nMill
			  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_rsMill
			  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_kMill
			  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillTop
			  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillBot
		} @boardL
	);
	push( @NCThroughLayers, $LDNPltThrough );

	# POS 9.f: Type_PLTTHROUGHNC from TOP or BOT
	my $LDPltThrough = LayerData->new( Enums->Type_PLTTHROUGHNC, Enums->Visible_FROMTOPBOT );
	$LDPltThrough->AddSingleLayers(
		grep {
			     $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nMill
			  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nDrill
			  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillTop
			  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillBot
		} @boardL
	);
	push( @NCThroughLayers, $LDPltThrough );

	@NCThroughLayers = reverse(@NCThroughLayers) if ( $self->{"viewType"} eq Enums->View_FROMBOT );

	# 2) Prepare layers which are visible either from BOT or from TOP

	# POS 1: Type_STIFFENER from TOP
	my $LDStiffenerTOP = LayerData->new( Enums->Type_STIFFENER, Enums->Visible_FROMTOP );
	$LDStiffenerTOP->AddSingleLayers( grep { $_->{"gROWname"} =~ /^stiffc\d*$/ } @boardL );
	push( @pdfLayers, $LDStiffenerTOP );

	# POS 2: Type_GRAFIT from TOP
	my $LDGraffitTOP = LayerData->new( Enums->Type_GRAFIT, Enums->Visible_FROMTOP );
	$LDGraffitTOP->AddSingleLayers( grep { $_->{"gROWname"} =~ /^gc$/ } @boardL );
	push( @pdfLayers, $LDGraffitTOP );

	# POS 3: Type_PEELABLE from TOP
	my $LDPeelableTOP = LayerData->new( Enums->Type_PEELABLE, Enums->Visible_FROMTOP );
	$LDPeelableTOP->AddSingleLayers( grep { $_->{"gROWname"} =~ /^lc$/ } @boardL );
	push( @pdfLayers, $LDPeelableTOP );

	# POS 4: Type_GOLDFINGER from TOP
	my $LDGoldfingerTOP = LayerData->new( Enums->Type_GOLDFINGER, Enums->Visible_FROMTOP );
	$LDGoldfingerTOP->AddSingleLayers( grep { $_->{"gROWname"} =~ /^goldc$/ } @boardL );
	push( @pdfLayers, $LDGoldfingerTOP );

	# POS 5: Type_SILK2 from TOP
	my $LDSilk2TOP = LayerData->new( Enums->Type_SILK2, Enums->Visible_FROMTOP );
	$LDSilk2TOP->AddSingleLayers( grep { $_->{"gROWname"} =~ /^pc2$/ } @boardL );
	push( @pdfLayers, $LDSilk2TOP );

	# POS 6: Type_SILK from TOP
	my $LDSilkTOP = LayerData->new( Enums->Type_SILK, Enums->Visible_FROMTOP );
	$LDSilkTOP->AddSingleLayers( grep { $_->{"gROWname"} =~ /^pc$/ } @boardL );
	push( @pdfLayers, $LDSilkTOP );

	# POS 7: Type_FLEXMASK from TOP
	my $LDMaskFlexTOP = LayerData->new( Enums->Type_FLEXMASK, Enums->Visible_FROMTOP );
	$LDMaskFlexTOP->AddSingleLayers( grep { $_->{"gROWname"} =~ /^mcflex$/ } @boardL );
	push( @pdfLayers, $LDMaskFlexTOP );

	# POS 8: Type_MASK from TOP
	my $LDMaskTOP = LayerData->new( Enums->Type_MASK, Enums->Visible_FROMTOP );
	$LDMaskTOP->AddSingleLayers( grep { $_->{"gROWname"} =~ /^mc$/ } @boardL );
	push( @pdfLayers, $LDMaskTOP );

	# POS 8: Type_NPLTDEPTHNC from TOP
	my $LDNPltDepthTOP = LayerData->new( Enums->Type_NPLTDEPTHNC, Enums->Visible_FROMTOP );
	$LDNPltDepthTOP->AddSingleLayers(
		grep {
			$_->{"type"}
			  && ( $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillTop || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_score )
		} @boardL
	);
	push( @pdfLayers, $LDNPltDepthTOP );

	# POS 8: Type_PLTDEPTHNC from TOP
	my $LDPltDepthTOP = LayerData->new( Enums->Type_PLTDEPTHNC, Enums->Visible_FROMTOP );
	$LDPltDepthTOP->AddSingleLayers(
		grep {
			     $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillTop
			  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillTop
		} @boardL
	);
	push( @pdfLayers, $LDPltDepthTOP );

	# POS 17: Type_VIAFILL from TOP
	my $LDViaFillTOP = LayerData->new( Enums->Type_VIAFILL, Enums->Visible_FROMTOP );
	$LDViaFillTOP->AddSingleLayers(
		grep {
			     $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nFillDrill
			  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bFillDrillTop
		} @boardL
	);
	push( @pdfLayers, $LDViaFillTOP );

	# POS 9.b: Type_OUTERSURFACE from TOP
	my $LDOuterSurfaceTOP = LayerData->new( Enums->Type_OUTERSURFACE, Enums->Visible_FROMTOP );
	$LDOuterSurfaceTOP->AddSingleLayers( grep { $_->{"gROWname"} =~ /^c$/ } @boardL );
	push( @pdfLayers, $LDOuterSurfaceTOP );

	# POS 9: Type_OUTERCU; Type_OUTERSURFACE; Type_INNERCU; Type_COVERLAY;
	# POS 9.a: Type_OUTERCU from TOP
	my $LDOuterCuTOP = LayerData->new( Enums->Type_OUTERCU, Enums->Visible_FROMTOP );
	$LDOuterCuTOP->AddSingleLayers( grep { $_->{"gROWname"} =~ /^c$/ } @boardL );
	push( @pdfLayers, $LDOuterCuTOP );

	if ( $layerCnt <= 2 ) {

		# For 1v + 2v add one pcb material (flex or rigid)

		my $LDMatOuterTOP = LayerData->new( ( $isFlex ? Enums->Type_RIGIDMATOUTER : Enums->Type_FLEXMATOUTER ), Enums->Visible_FROMTOPBOT );
		push( @pdfLayers, $LDMatOuterTOP );

	}
	else {

		# For multilayer, read stackup
		my @stackupL = $stackup->GetAllLayers();
		for ( my $i = 0 ; $i < scalar(@stackupL) ; $i++ ) {

			my $l = $stackupL[$i];

			next if ( $l->GetType() eq EnumsStack->MaterialType_COPPER && ( $l->GetCopperName() =~ /^[cs]$/ ) );

			if ( $l->GetType() eq EnumsStack->MaterialType_COPPER ) {
				my $side = StackupOperation->GetSideByLayer( $jobId, $l->GetCopperName(), $stackup );
				my $LDInnerCu = LayerData->new( Enums->Type_INNERCU, ( $side eq "top" ? Enums->Visible_FROMTOP : Enums->Visible_FROMBOT ) );
				$LDInnerCu->AddSingleLayers( grep { $_->{"gROWname"} eq $l->GetCopperName() } @boardL );
				push( @pdfLayers, $LDInnerCu );
			}
			elsif (    $l->GetType() eq EnumsStack->MaterialType_PREPREG
					|| $l->GetType() eq EnumsStack->MaterialType_CORE )
			{

				my $position = $i == 1 || $i == scalar(@stackupL) - 2 ? "out" : "in";
				my $viewType;

				if ( $stackupL[ $i - 1 ]->GetCopperName() eq "c" ) {
					$viewType = Enums->Visible_FROMTOP;

				}
				elsif ( $stackupL[ $i + 1 ]->GetCopperName() eq "s" ) {
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

	# POS 9.c: Type_OUTERCU from BOT
	my $LDOuterCuBOT = LayerData->new( Enums->Type_OUTERCU, Enums->Visible_FROMBOT );
	$LDOuterCuBOT->AddSingleLayers( grep { $_->{"gROWname"} eq "s" } @boardL );
	push( @pdfLayers, $LDOuterCuBOT );

	# POS 9.d: Type_OUTERSURFACE from BOT
	my $LDOuterSurfaceBOT = LayerData->new( Enums->Type_OUTERSURFACE, Enums->Visible_FROMBOT );
	$LDOuterSurfaceBOT->AddSingleLayers( grep { $_->{"gROWname"} eq "s" } @boardL );
	push( @pdfLayers, $LDOuterSurfaceBOT );

	# POS 17: Type_VIAFILL from TOP
	my $LDViaFillBOT = LayerData->new( Enums->Type_VIAFILL, Enums->Visible_FROMBOT );
	$LDViaFillBOT->AddSingleLayers(
		grep {
			     $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nFillDrill
			  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bFillDrillBot
		} @boardL
	);
	push( @pdfLayers, $LDViaFillBOT );

	# POS 8: Type_PLTDEPTHNC from BOT
	my $LDPltDepthBOT = LayerData->new( Enums->Type_PLTDEPTHNC, Enums->Visible_FROMBOT );
	$LDPltDepthBOT->AddSingleLayers(
		grep {
			     $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillBot
			  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillBot
		} @boardL
	);
	push( @pdfLayers, $LDPltDepthBOT );

	# POS 8: Type_NPLTDEPTHNC from BOT
	my $LDNPltDepthBOT = LayerData->new( Enums->Type_NPLTDEPTHNC, Enums->Visible_FROMBOT );
	$LDNPltDepthBOT->AddSingleLayers(
		grep {
			$_->{"type"}
			  && ( $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillBot || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_score )
		} @boardL
	);
	push( @pdfLayers, $LDNPltDepthBOT );

	# POS 10: Type_MASK from BOT
	my $LDMaskBOT = LayerData->new( Enums->Type_MASK, Enums->Visible_FROMBOT );
	$LDMaskBOT->AddSingleLayers( grep { $_->{"gROWname"} =~ /^ms$/ } @boardL );
	push( @pdfLayers, $LDMaskBOT );

	# POS 11: Type_FLEXMASK from BOT
	my $LDMaskFlexBOT = LayerData->new( Enums->Type_FLEXMASK, Enums->Visible_FROMBOT );
	$LDMaskFlexBOT->AddSingleLayers( grep { $_->{"gROWname"} =~ /^msflex$/ } @boardL );
	push( @pdfLayers, $LDMaskFlexBOT );

	# POS 12: Type_SILK from BOT
	my $LDSilkBOT = LayerData->new( Enums->Type_SILK, Enums->Visible_FROMBOT );
	$LDSilkBOT->AddSingleLayers( grep { $_->{"gROWname"} =~ /^ps$/ } @boardL );
	push( @pdfLayers, $LDSilkBOT );

	# POS 13: Type_SILK2 from BOT
	my $LDSilk2BOT = LayerData->new( Enums->Type_SILK2, Enums->Visible_FROMBOT );
	$LDSilk2BOT->AddSingleLayers( grep { $_->{"gROWname"} =~ /^ps2$/ } @boardL );
	push( @pdfLayers, $LDSilk2BOT );

	# POS 14: Type_GOLDFINGER from BOT
	my $LDGoldfingerBOT = LayerData->new( Enums->Type_GOLDFINGER, Enums->Visible_FROMBOT );
	$LDGoldfingerBOT->AddSingleLayers( grep { $_->{"gROWname"} =~ /^golds$/ } @boardL );
	push( @pdfLayers, $LDGoldfingerBOT );

	# POS 15: Type_PEELABLE from BOT
	my $LDPeelableBOT = LayerData->new( Enums->Type_PEELABLE, Enums->Visible_FROMBOT );
	$LDPeelableBOT->AddSingleLayers( grep { $_->{"gROWname"} =~ /^ls$/ } @boardL );
	push( @pdfLayers, $LDPeelableBOT );

	# POS 16: Type_GRAFIT from BOT
	my $LDGraffitBOT = LayerData->new( Enums->Type_GRAFIT, Enums->Visible_FROMBOT );
	$LDGraffitBOT->AddSingleLayers( grep { $_->{"gROWname"} =~ /^gs$/ } @boardL );
	push( @pdfLayers, $LDGraffitBOT );

	# POS 17: Type_STIFFENER from BOT
	my $LDStiffenerBOT = LayerData->new( Enums->Type_STIFFENER, Enums->Visible_FROMBOT );
	$LDStiffenerBOT->AddSingleLayers( grep { $_->{"gROWname"} =~ /^stiffs\d*$/ } @boardL );
	push( @pdfLayers, $LDStiffenerBOT );

	# If exist coverlays, insert them next by proper Cu layer

	foreach my $l ( grep { $_->{"gROWname"} =~ /^coverlay(\w*)/ } @boardL ) {

		my $sigL = ( $l->{"gROWname"} =~ /^coverlay(\w*)/ )[0];

		# POS 9.f: Type_COVERLAY from TOP or BOT
		my $side = StackupOperation->GetSideByLayer( $jobId, $sigL, $stackup );
		my $LDCoverlay = LayerData->new( Enums->Type_COVERLAY, ( $side eq "top" ? Enums->Visible_FROMTOP : Enums->Visible_FROMBOT ) );
		$LDCoverlay->AddSingleLayers($l);

		my $idx = first_index {
			( grep { $_->{"gROWname"} eq $sigL } $_->GetLayers() )[0]

			  && (    $_->GetType() eq Enums->Type_OUTERCU
				   || $_->GetType() eq Enums->Type_OUTERCU )
		}
		@pdfLayers;
		splice @pdfLayers, ( $side eq "top" ? $idx : $idx + 1 ), 0, $LDCoverlay;
	}

	@pdfLayers = reverse(@pdfLayers) if ( $self->{"viewType"} eq Enums->View_FROMBOT );

	unshift( @pdfLayers, @NCThroughLayers );

	return @pdfLayers;

}

sub __DisableLayer {
	my $self      = shift;
	my $pdfLayers = shift;

	my $jobId = $self->{"jobId"};
	my $inCAM = $self->{"inCAM"};

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

		# Theses layers can by visible from other side (materials are transparent)

		# Include all coverlays
		$_->SetIsActive(1) for ( grep { $_->GetType() eq Enums->Type_COVERLAY } @{$pdfLayers} );

		# Include all flex mask
		$_->SetIsActive(1) for ( grep { $_->GetType() eq Enums->Type_FLEXMASK } @{$pdfLayers} );

		# Include all flex mask
		$_->SetIsActive(1) for ( grep { $_->GetType() eq Enums->Type_FLEXMATINNER || $_->GetType() eq Enums->Type_FLEXMATOUTER } @{$pdfLayers} );

		# Include all Cu on flex cores
		for ( my $i = 0 ; $i < scalar( @{$pdfLayers} ) ; $i++ ) {

			if (    $pdfLayers->[$i]->GetType() eq Enums->Type_FLEXMATINNER
				 || $pdfLayers->[$i]->GetType() eq Enums->Type_FLEXMATOUTER )
			{

				if ( $pdfLayers->[ $i - 1 ]->GetType() eq Enums->Type_OUTERCU || $pdfLayers->[ $i - 1 ]->GetType() eq Enums->Type_INNERCU ) {
					$pdfLayers->[ $i - 1 ]->SetIsActive(1);
				}

				if ( $pdfLayers->[ $i + 1 ]->GetType() eq Enums->Type_OUTERCU || $pdfLayers->[ $i + 1 ]->GetType() eq Enums->Type_INNERCU ) {
					$pdfLayers->[ $i + 1 ]->SetIsActive(1);
				}
			}
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

