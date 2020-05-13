#-------------------------------------------------------------------------------------------#
# Description: Nif Builder is responsible for creation nif file depend on pcb type
# Builder for pcb no copper
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::CustStackup::BlockBuilders::BuilderBody;
use base('Packages::CAMJob::Stackup::CustStackup::BlockBuilders::BlockBuilderBase');

use Class::Interface;
&implements('Packages::CAMJob::Stackup::CustStackup::BlockBuilders::IBlockBuilder');

#3th party library
use strict;
use warnings;
use Time::localtime;
use Storable qw(dclone);
use List::Util qw(first);

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAMJob::Stackup::CustStackup::Enums';
use aliased 'Packages::CAMJob::Stackup::CustStackup::EnumsStyle';
use aliased 'Packages::Other::TableDrawing::TableLayout::StyleLayout::TextStyle';
use aliased 'Packages::Other::TableDrawing::TableLayout::StyleLayout::Color';
use aliased 'Packages::Other::TableDrawing::TableLayout::StyleLayout::BackgStyle';
use aliased 'Packages::Other::TableDrawing::Enums' => 'TblDrawEnums';
use aliased 'Packages::CAMJob::Stackup::CustStackup::BlockBuilders::BuilderBodyHelper';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';
use aliased 'Helpers::JobHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	$self->{"stckpBody"} = BuilderBodyHelper->new( $self->{"tblMain"}, $self->{"stackupMngr"}, $self->{"sectionMngr"} );

	return $self;
}

sub Build {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	$self->__BuildHeadRow();

	$self->__BuildStackupRows();

}

sub __BuildHeadRow {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $tblMain   = $self->{"tblMain"};
	my $stckpMngr = $self->{"stackupMngr"};
	my $secMngr   = $self->{"sectionMngr"};

	# Define first title row
	my $rowBackgStyle = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( EnumsStyle->Clr_HEADSUBBACK ) );
	my $row = $tblMain->AddRowDef( "body_head", EnumsStyle->RowHeight_STANDARD, $rowBackgStyle );

	my $txtStyle = TextStyle->new( TblDrawEnums->TextStyle_LINE,
								   EnumsStyle->TxtSize_TITLE, Color->new( 0, 0, 0 ),
								   undef, undef,
								   TblDrawEnums->TextHAlign_LEFT,
								   TblDrawEnums->TextVAlign_CENTER, 1 );

	my $borderStyle = $self->{"secBorderStyle"};

	# Sec_BEGIN ---------------------------------------------
	my $sec_BEGIN = $secMngr->GetSection( Enums->Sec_BEGIN );
	if ( $sec_BEGIN->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "matTitle" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, "Material text", $txtStyle );

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "cuUsage" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, ( $stckpMngr->GetLayerCnt() > 2 ? "Cu usage" : "Cu layer" ), $txtStyle );
	}

	# Sec_A_MAIN ---------------------------------------------
	my $sec_A_MAIN = $secMngr->GetSection( Enums->Sec_A_MAIN );
	if ( $sec_A_MAIN->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "leftEdge" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, undef, undef, undef, $borderStyle );

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matType" ), $tblMain->GetRowDefPos($row), undef, undef, "Material",
						   $txtStyle );
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matThick" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, "Thick [µm]", $txtStyle );

		if ( scalar( $stckpMngr->GetPlatedNC() ) ) {
			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "NCStartCol" ),
							   $tblMain->GetRowDefPos($row),
							   undef, undef, "Plt drill", $txtStyle );
		}
	}

	# Sec_B_FLEX ---------------------------------------------
	my $sec_B_FLEX = $secMngr->GetSection( Enums->Sec_B_FLEX );
	if ( $sec_B_FLEX->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_B_FLEX, "matType" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, "Material", $txtStyle, undef, $borderStyle );
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_B_FLEX, "matThick" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, "Thick [µm]", $txtStyle );
	}

	# Sec_C_RIGIDFLEX ---------------------------------------------
	my $sec_C_RIGIDFLEX = $secMngr->GetSection( Enums->Sec_C_RIGIDFLEX );
	if ( $sec_C_RIGIDFLEX->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_C_RIGIDFLEX, "leftEdge" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, undef, undef, undef, $borderStyle );

	}

	# Sec_D_FLEXTAIL ---------------------------------------------
	my $sec_D_FLEXTAIL = $secMngr->GetSection( Enums->Sec_D_FLEXTAIL );
	if ( $sec_D_FLEXTAIL->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_D_FLEXTAIL, "matType" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, "Material", $txtStyle, undef, $borderStyle );
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_D_FLEXTAIL, "matThick" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, "Thick [µm]", $txtStyle );
	}

	# Sec_E_STIFFENER ---------------------------------------------
	my $sec_E_STIFFENER = $secMngr->GetSection( Enums->Sec_E_STIFFENER );

	if ( $sec_E_STIFFENER->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_E_STIFFENER, "matType" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, "Material", $txtStyle, undef, $borderStyle );
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_E_STIFFENER, "matThick" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, "Thick [µm]", $txtStyle );
	}

	# Sec_F_STIFFENER ---------------------------------------------
	my $sec_F_STIFFENER = $secMngr->GetSection( Enums->Sec_F_STIFFENER );

	if ( $sec_F_STIFFENER->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_F_STIFFENER, "matType" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, "Material", $txtStyle, undef, $borderStyle );
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_F_STIFFENER, "matThick" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, "Thick [µm]", $txtStyle );
	}

	# Sec_END
	my $sec_END = $secMngr->GetSection( Enums->Sec_END );

	if ( $sec_END->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_END, "end" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, undef, $txtStyle, undef, $borderStyle );

	}

}

sub __BuildStackupRows {
	my $self  = shift;
	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $tblMain   = $self->{"tblMain"};
	my $stckpMngr = $self->{"stackupMngr"};
	my $secMngr   = $self->{"sectionMngr"};

	# 1) Add gap row above stackup
	my $topGap = $tblMain->AddRowDef( "bodyTopGap", EnumsStyle->RowHeight_STANDARD * 1.2 );

	# 2) Build stackup layers
	$self->__BuildStackupLayers();

	# 4) Add gap row below stackup
	my $botGap = $tblMain->AddRowDef( "bodyBotGap", EnumsStyle->RowHeight_STANDARD * 1.2 );

	# 3) Add gaps bewtwwen layers
	$self->{"stckpBody"}->AddMaterialLayerGaps( $topGap, $botGap );

	# 4) Add plating drills
	$self->{"stckpBody"}->AddPlatedDrilling();

}

sub __BuildStackupLayers {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $tblMain   = $self->{"tblMain"};
	my $stckpMngr = $self->{"stackupMngr"};
	my $secMngr   = $self->{"sectionMngr"};

	# Define general styles

	my $txtTitleStyle = TextStyle->new( TblDrawEnums->TextStyle_LINE,
										EnumsStyle->TxtSize_STANDARD,
										Color->new( 0, 0, 0 ),
										undef, undef,
										TblDrawEnums->TextHAlign_LEFT,
										TblDrawEnums->TextVAlign_CENTER, 0.5 );
	my $txtCuStyle = TextStyle->new( TblDrawEnums->TextStyle_LINE,
									 EnumsStyle->TxtSize_STANDARD,
									 Color->new( 0, 0, 0 ),
									 TblDrawEnums->Font_BOLD, undef,
									 TblDrawEnums->TextHAlign_LEFT,
									 TblDrawEnums->TextVAlign_CENTER, 1 );
	my $txtStandardStyle = TextStyle->new( TblDrawEnums->TextStyle_LINE,
										   EnumsStyle->TxtSize_STANDARD,
										   Color->new( 255, 255, 255 ),
										   undef, undef,
										   TblDrawEnums->TextHAlign_LEFT,
										   TblDrawEnums->TextVAlign_CENTER, 1.5 );

	# 1) Prepare special outer layers
	# Merge slecial outer layers to same row is it is needed
	my %topOuterRows = $self->{"stckpBody"}->BuildRowsStackupOuter("top");

	# LAYER: Top SM
	my $maskTopInfo = {};
	if ( $stckpMngr->GetExistSM( "top", $maskTopInfo ) ) {

		my $coverFlexCore = 0;

		my $pcbType = $stckpMngr->GetPcbType();

		if (    $pcbType eq EnumsGeneral->PcbType_1VFLEX
			 || $pcbType eq EnumsGeneral->PcbType_2VFLEX
			 || $pcbType eq EnumsGeneral->PcbType_MULTIFLEX )
		{
			$coverFlexCore = 1;
		}
		elsif (

			$pcbType eq EnumsGeneral->PcbType_RIGIDFLEXO && JobHelper->GetORigidFlexType( $self->{"jobId"}, $stckpMngr->GetStackup() ) eq "flextop"
		  )
		{
			$coverFlexCore = 1;
		}

		$self->__DrawMatSM( $topOuterRows{ BuilderBodyHelper->sm },
							$maskTopInfo->{"color"},
							$maskTopInfo->{"thick"},
							$coverFlexCore, dclone($txtTitleStyle), dclone($txtStandardStyle) );
	}

	# LAYER: TOP FLEX MASK UV
	my $maskFlexTopInfo = {};
	if ( $stckpMngr->GetExistSMFlex( "top", $maskFlexTopInfo ) ) {

		$self->__DrawMatSMFlex( $topOuterRows{ BuilderBodyHelper->smFlex },
								$maskFlexTopInfo->{"text"},
								$maskFlexTopInfo->{"thick"},
								dclone($txtTitleStyle), dclone($txtStandardStyle) );
	}

	# LAYER: TOP stiffener adhesive
	my $stiffTopInfo = {};
	if ( $stckpMngr->GetExistStiff( "top", $stiffTopInfo ) ) {

		$self->__DrawMatStiffAdh( $topOuterRows{ BuilderBodyHelper->stiffAdh },
								  $stiffTopInfo->{"adhesiveText"},
								  $stiffTopInfo->{"adhesiveThick"},
								  "top", dclone($txtTitleStyle), dclone($txtStandardStyle) );
	}

	# LAYER: TOP stiffener
	if ( $stckpMngr->GetExistStiff("top") ) {

		$self->__DrawMatStiff( $topOuterRows{ BuilderBodyHelper->stiff },
							   $stiffTopInfo->{"stiffText"},
							   $stiffTopInfo->{"stiffThick"},
							   "top", dclone($txtTitleStyle), dclone($txtStandardStyle) );
	}

	# LAYER: TOP coverlay adhesive
	my $cvrlOuterTopInfo = {};
	if ( $stckpMngr->GetExistCvrl( "top", $cvrlOuterTopInfo ) ) {

		$self->__DrawMatCoverlayAdhOuter( $topOuterRows{ BuilderBodyHelper->cvrlAdh },
										  $cvrlOuterTopInfo->{"adhesiveText"},
										  $cvrlOuterTopInfo->{"adhesiveThick"},
										  $cvrlOuterTopInfo->{"selective"},
										  dclone($txtTitleStyle), dclone($txtStandardStyle) );
	}

	# LAYER: TOP coverlay
	if ( $stckpMngr->GetExistCvrl("top") ) {

		$self->__DrawMatCoverlayOuter(
									   $topOuterRows{ BuilderBodyHelper->cvrl }, $cvrlOuterTopInfo->{"cvrlText"},
									   $cvrlOuterTopInfo->{"cvrlThick"},         $cvrlOuterTopInfo->{"selective"},
									   dclone($txtTitleStyle),                   dclone($txtStandardStyle)
		);
	}

	# 2) Prepare signal layers
	if ( $stckpMngr->GetLayerCnt() <= 2 ) {

		my @layers = $stckpMngr->GetStackupLayers();
		my %matInf = $stckpMngr->GetBaseMatInfo();

		# Draw copper layers
		for ( my $i = 0 ; $i < scalar(@layers) ; $i++ ) {

			my $l = $layers[$i];

			my $row = $tblMain->AddRowDef( "copper_" . ( $i + 1 ), EnumsStyle->RowHeight_STANDARD );

			my $text = "Standard";

			if ( defined $matInf{"cuType"} ) {
				$text .= " (" . $matInf{"cuType"} . ")";
			}

			$self->__DrawMatCopper( $row, $text,
									$stckpMngr->GetCuThickness( $l->{"gROWname"} ),
									$stckpMngr->GetIsPlated($l),
									$i + 1, undef, 0, $stckpMngr->GetIsFlex(),
									dclone($txtTitleStyle), dclone($txtCuStyle), dclone($txtStandardStyle) );
		}

		# Draw core
		my $rowPos = $tblMain->GetRowCnt();
		$rowPos -= 1 if ( scalar(@layers) == 2 );
		my $row = $tblMain->InsertRowDef( "core_1", $rowPos, EnumsStyle->RowHeight_STANDARD );

		$self->__DrawMatCore(
			$row, $matInf{"matText"}, $matInf{"baseMatThick"}, $stckpMngr->GetIsFlex(), 0,

			dclone($txtTitleStyle), dclone($txtStandardStyle)
		);

	}
	else {

		my $stackup = $stckpMngr->GetStackup();
		my @layers  = $stackup->GetAllLayers();
		for ( my $i = 0 ; $i < scalar(@layers) ; $i++ ) {

			my $l = $layers[$i];

			if ( $l->GetType() eq StackEnums->MaterialType_COPPER ) {

				my $row = $tblMain->AddRowDef( "copper_" . $l->GetCopperNumber(), EnumsStyle->RowHeight_STANDARD );

				my $isFlex = 0;
				my $c = !$l->GetIsFoil() ? $stackup->GetCoreByCuLayer( $l->GetCopperName ) : undef;
				if ( defined $c && $c->GetCoreRigidType() eq StackEnums->CoreType_FLEX ) {
					$isFlex = 1;
				}

				my $text = "Standard";
				if ($isFlex) {

					$text .= $c->GetText() =~ m/(r)\s+\d+\/\d+/i ? " (RA)" : " (ED)";

				}

				my $lInfo = first { $_->{"gROWname"} eq $l->GetCopperName() } $stckpMngr->GetBoardBaseLayers();

				my $ussage = undef;    # if outer layers, ussage is not set
				if ( $l->GetCopperName() =~ /^v\d+$/ ) {

					if ( $stckpMngr->GetIsInnerLayerEmpty( $l->GetCopperName() ) ) {
						$ussage = 0;

					}
					else {
						$ussage = $l->GetUssage() * 100;
					}
				}

				$self->__DrawMatCopper( $row, $text, $l->GetThick(), $stckpMngr->GetIsPlated($lInfo),
										$l->GetCopperNumber(), $ussage, $l->GetIsFoil(), $isFlex, dclone($txtTitleStyle), dclone($txtCuStyle),
										dclone($txtStandardStyle) );

			}
			elsif ( $l->GetType() eq StackEnums->MaterialType_PREPREG ) {

				my @types = ();
				my $quality = $stckpMngr->GetPrepregTitle( $l, \@types );

				#if ( scalar(@types) > 1 ) {
				my $prpgTxtTitleStyle = TextStyle->new( TblDrawEnums->TextStyle_MULTILINE,
														EnumsStyle->TxtSize_STANDARD,
														Color->new( 0, 0, 0 ),
														undef, undef,
														TblDrawEnums->TextHAlign_LEFT,
														TblDrawEnums->TextVAlign_CENTER, 0.5 );

				my $text = "";
				foreach my $t (@types) {

					$text .= $quality . " $t\n";
				}

				#}

				# Do distinguish between Noflow Prepreg 1 which insluding coverlay and others prepregs
				if ( $l->GetIsNoFlow() && $l->GetNoFlowType() eq StackEnums->NoFlowPrepreg_P1 && $l->GetIsCoverlayIncl() ) {

					# find copper layer which is coverlaysticked to
					# Add coverlay + adhesive
					my $cuLayerSide = undef;

					if ( $i - 1 >= 0 && $layers[ $i - 1 ]->GetType() eq StackEnums->MaterialType_COPPER ) {
						$cuLayerSide = $stackup->GetSideByCuLayer( $layers[ $i - 1 ]->GetCopperName() );
					}
					elsif ( $i + 1 < scalar(@layers) && $layers[ $i + 1 ]->GetType() eq StackEnums->MaterialType_COPPER ) {
						$cuLayerSide = $stackup->GetSideByCuLayer( $layers[ $i + 1 ]->GetCopperName() );
					}
					else {
						die "No coverlay copper layer was found";
					}

					my $rowCvrl    = $tblMain->AddRowDef( "prepreg_cvrl_$i",     scalar(@types) * EnumsStyle->RowHeight_STANDARD );
					my $rowCvrlAdh = $tblMain->AddRowDef( "prepreg_cvrl_adh_$i", scalar(@types) * EnumsStyle->RowHeight_STANDARD );

					$self->__DrawMatPrepreg( ( $cuLayerSide eq "top" ? $rowCvrlAdh : $rowCvrl ),
											 $text, $l->GetThick(), 1, StackEnums->NoFlowPrepreg_P1,
											 1, $prpgTxtTitleStyle, dclone($txtStandardStyle) );
					$self->__DrawMatPrepreg( ( $cuLayerSide eq "top" ? $rowCvrl : $rowCvrlAdh ),
											 $text, $l->GetThick(), 1, StackEnums->NoFlowPrepreg_P1,
											 0, $prpgTxtTitleStyle, dclone($txtStandardStyle) );

					my $cvrlInInfo = $stckpMngr->GetCvrlInfo( $l->GetCoverlay() );

					# coverlay adhesive incl

					$self->__DrawMatCoverlayAdhOuter(
													  $cuLayerSide eq "top" ? $rowCvrlAdh : $rowCvrl, $cvrlInInfo->{"adhesiveText"},
													  $cvrlInInfo->{"adhesiveThick"}, $cvrlInInfo->{"selective"},
													  dclone($txtTitleStyle),         dclone($txtStandardStyle)
					);

					# Coverlay included in noflow prepreg

					$self->__DrawMatCoverlayOuter( $cuLayerSide eq "top" ? $rowCvrl : $rowCvrlAdh,
												   $cvrlInInfo->{"cvrlText"},
												   $cvrlInInfo->{"cvrlThick"},
												   $cvrlInInfo->{"selective"},
												   dclone($txtTitleStyle), dclone($txtStandardStyle) );
				}
				else {

					my $rowPrpg = $tblMain->AddRowDef( "prepreg_$i", scalar(@types) * EnumsStyle->RowHeight_STANDARD );
					$self->__DrawMatPrepreg( $rowPrpg, $text, $l->GetThick(), $l->GetIsNoFlow(), ( $l->GetIsNoFlow() ? $l->GetNoFlowType() : undef ),
											 1, $prpgTxtTitleStyle, dclone($txtStandardStyle) );
				}

			}
			elsif ( $l->GetType() eq StackEnums->MaterialType_CORE ) {

				my $rowHeight = undef;

				if ( $l->GetCoreRigidType() eq StackEnums->CoreType_RIGID ) {
					$rowHeight = EnumsStyle->RowHeight_CORERIGID;
				}
				elsif ( $l->GetCoreRigidType() eq StackEnums->CoreType_FLEX ) {
					$rowHeight = EnumsStyle->RowHeight_COREFLEX;
				}

				my $row = $tblMain->AddRowDef( "core_" . $l->GetCoreNumber(), $rowHeight );

				$self->__DrawMatCore(
					$row, $l->GetTextType(), $l->GetThick(), ( $l->GetCoreRigidType() eq StackEnums->CoreType_FLEX ? 1 : 0 ), 1,

					dclone($txtTitleStyle), dclone($txtStandardStyle)
				);

			}

		}

	}

	# Prepare special bottom outer layers
	# Merge slecial outer layers to same row is it is needed
	my %botOuterRows = $self->{"stckpBody"}->BuildRowsStackupOuter("bot");

	# LAYER: BOT SM
	my $maskBotInfo = {};
	if ( $stckpMngr->GetExistSM( "bot", $maskBotInfo ) ) {

		my $coverFlexCore = 0;

		my $pcbType = $stckpMngr->GetPcbType();

		if (    $pcbType eq EnumsGeneral->PcbType_1VFLEX
			 || $pcbType eq EnumsGeneral->PcbType_2VFLEX
			 || $pcbType eq EnumsGeneral->PcbType_MULTIFLEX )
		{
			$coverFlexCore = 1;
		}
		elsif (

			$pcbType eq EnumsGeneral->PcbType_RIGIDFLEXO && JobHelper->GetORigidFlexType( $self->{"jobId"}, $stckpMngr->GetStackup() ) eq "flexbot"
		  )
		{
			$coverFlexCore = 1;
		}

		$self->__DrawMatSM( $botOuterRows{ BuilderBodyHelper->sm },
							$maskBotInfo->{"color"},
							$maskBotInfo->{"thick"},
							$coverFlexCore, dclone($txtTitleStyle), dclone($txtStandardStyle) );
	}

	# LAYER: BOT FLEX MASK UV
	my $maskFlexBotInfo = {};
	if ( $stckpMngr->GetExistSMFlex( "bot", $maskFlexBotInfo ) ) {

		$self->__DrawMatSMFlex( $botOuterRows{ BuilderBodyHelper->smFlex },
								$maskFlexBotInfo->{"text"},
								$maskFlexBotInfo->{"thick"},
								dclone($txtTitleStyle), dclone($txtStandardStyle) );
	}

	# LAYER: BOT stiffener adhesive
	my $stiffBotInfo = {};
	if ( $stckpMngr->GetExistStiff( "bot", $stiffBotInfo ) ) {

		$self->__DrawMatStiffAdh( $botOuterRows{ BuilderBodyHelper->stiffAdh },
								  $stiffBotInfo->{"adhesiveText"},
								  $stiffBotInfo->{"adhesiveThick"},
								  "bot", dclone($txtTitleStyle), dclone($txtStandardStyle) );
	}

	# 2) Add material rows

	# LAYER: BOT stiffener
	if ( $stckpMngr->GetExistStiff("bot") ) {

		$self->__DrawMatStiff( $botOuterRows{ BuilderBodyHelper->stiff },
							   $stiffBotInfo->{"stiffText"},
							   $stiffBotInfo->{"stiffThick"},
							   "bot", dclone($txtTitleStyle), dclone($txtStandardStyle) );
	}

	# LAYER: BOT coverlay adhesive
	my $cvrlOuterBotInfo = {};
	if ( $stckpMngr->GetExistCvrl( "bot", $cvrlOuterBotInfo ) ) {

		$self->__DrawMatCoverlayAdhOuter( $botOuterRows{ BuilderBodyHelper->cvrlAdh },
										  $cvrlOuterBotInfo->{"adhesiveText"},
										  $cvrlOuterBotInfo->{"adhesiveThick"},
										  $cvrlOuterBotInfo->{"selective"},
										  dclone($txtTitleStyle), dclone($txtStandardStyle) );
	}

	# LAYER: Top coverlay
	if ( $stckpMngr->GetExistCvrl("bot") ) {

		$self->__DrawMatCoverlayOuter(
									   $botOuterRows{ BuilderBodyHelper->cvrl }, $cvrlOuterBotInfo->{"cvrlText"},
									   $cvrlOuterBotInfo->{"cvrlThick"},         $cvrlOuterBotInfo->{"selective"},
									   dclone($txtTitleStyle),                   dclone($txtStandardStyle)
		);
	}

}

sub __DrawMatStiff {
	my $self             = shift;
	my $row              = shift;
	my $matText          = shift;
	my $matThick         = shift;
	my $stiffSide        = shift;
	my $txtTitleStyle    = shift;
	my $txtStandardStyle = shift;

	my $tblMain   = $self->{"tblMain"};
	my $stckpMngr = $self->{"stackupMngr"};
	my $secMngr   = $self->{"sectionMngr"};

	# 1) Define styles
	$txtStandardStyle->SetColor( Color->new( 0, 0, 0 ) );

	my $stiffBackgStyle    = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( EnumsStyle->Clr_STIFFENER ) );
	my $adhesiveBackgStyle = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( EnumsStyle->Clr_ADHESIVE ) );

	# Sec_BEGIN ---------------------------------------------
	my $sec_BEGIN = $secMngr->GetSection( Enums->Sec_BEGIN );
	if ( $sec_BEGIN->GetIsActive() ) {

		# stiffener
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "matTitle" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, $matText, $txtTitleStyle );
	}

	if ( $stiffSide eq "top" ) {

		# Sec_E_STIFFENER ---------------------------------------------
		my $sec_E_STIFFENER = $secMngr->GetSection( Enums->Sec_E_STIFFENER );

		if ( $sec_E_STIFFENER->GetIsActive() ) {

			# stiffener
			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_E_STIFFENER, "matType" ),
							   $tblMain->GetRowDefPos($row),
							   undef, undef, "Stiffener", $txtStandardStyle, $stiffBackgStyle );
			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_E_STIFFENER, "matThick" ),
							   $tblMain->GetRowDefPos($row),
							   undef, undef, int($matThick), $txtStandardStyle, $stiffBackgStyle );

		}
	}
	elsif ( $stiffSide eq "bot" ) {

		# Sec_F_STIFFENER ---------------------------------------------
		my $sec_F_STIFFENER = $secMngr->GetSection( Enums->Sec_F_STIFFENER );

		if ( $sec_F_STIFFENER->GetIsActive() ) {

			# stiffener
			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_F_STIFFENER, "matType" ),
							   $tblMain->GetRowDefPos($row),
							   undef, undef, "Stiffener", $txtStandardStyle, $stiffBackgStyle );
			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_F_STIFFENER, "matThick" ),
							   $tblMain->GetRowDefPos($row),
							   undef, undef, int($matThick), $txtStandardStyle, $stiffBackgStyle );

		}
	}

}

sub __DrawMatStiffAdh {
	my $self             = shift;
	my $row              = shift;
	my $matText          = shift;
	my $matThick         = shift;
	my $stiffSide        = shift;
	my $txtTitleStyle    = shift;
	my $txtStandardStyle = shift;

	my $tblMain   = $self->{"tblMain"};
	my $stckpMngr = $self->{"stackupMngr"};
	my $secMngr   = $self->{"sectionMngr"};

	# 1) Define styles
	$txtStandardStyle->SetColor( Color->new( 0, 0, 0 ) );

	my $stiffBackgStyle    = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( EnumsStyle->Clr_STIFFENER ) );
	my $adhesiveBackgStyle = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( EnumsStyle->Clr_ADHESIVE ) );

	# Sec_BEGIN ---------------------------------------------
	my $sec_BEGIN = $secMngr->GetSection( Enums->Sec_BEGIN );
	if ( $sec_BEGIN->GetIsActive() ) {

		# Check if there isn't already some material title (mask/flexmask)
		unless ( defined $tblMain->GetCellByPos( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "matTitle" ), $tblMain->GetRowDefPos($row) ) ) {

			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "matTitle" ),
							   $tblMain->GetRowDefPos($row),
							   undef, undef, $matText, $txtTitleStyle );
		}

	}
	if ( $stiffSide eq "top" ) {

		# Sec_E_STIFFENER ---------------------------------------------
		my $sec_E_STIFFENER = $secMngr->GetSection( Enums->Sec_E_STIFFENER );

		if ( $sec_E_STIFFENER->GetIsActive() ) {

			# adhesive
			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_E_STIFFENER, "matType" ),
							   $tblMain->GetRowDefPos($row),
							   undef, undef, "Adhesive", $txtStandardStyle, $adhesiveBackgStyle );
			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_E_STIFFENER, "matThick" ),
							   $tblMain->GetRowDefPos($row),
							   undef, undef, int($matThick), $txtStandardStyle, $adhesiveBackgStyle );
		}

	}
	elsif ( $stiffSide eq "bot" ) {

		# Sec_F_STIFFENER ---------------------------------------------
		my $sec_F_STIFFENER = $secMngr->GetSection( Enums->Sec_F_STIFFENER );

		if ( $sec_F_STIFFENER->GetIsActive() ) {

			# adhesive
			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_F_STIFFENER, "matType" ),
							   $tblMain->GetRowDefPos($row),
							   undef, undef, "Adhesive", $txtStandardStyle, $adhesiveBackgStyle );
			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_F_STIFFENER, "matThick" ),
							   $tblMain->GetRowDefPos($row),
							   undef, undef, int($matThick), $txtStandardStyle, $adhesiveBackgStyle );
		}
	}

}

sub __DrawMatSMFlex {
	my $self             = shift;
	my $row              = shift;
	my $matText          = shift;
	my $matThick         = shift;
	my $txtTitleStyle    = shift;
	my $txtStandardStyle = shift;

	my $tblMain   = $self->{"tblMain"};
	my $stckpMngr = $self->{"stackupMngr"};
	my $secMngr   = $self->{"sectionMngr"};

	# 1) Define styles
	$txtStandardStyle->SetColor( Color->new( 255, 255, 255 ) );

	my $matBackgStyle = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( EnumsStyle->Clr_SOLDERMASKFLEX ) );

	# Sec_B_FLEX ---------------------------------------------
	my $sec_B_FLEX = $secMngr->GetSection( Enums->Sec_B_FLEX );
	if ( $sec_B_FLEX->GetIsActive() ) {

		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_B_FLEX, -1, 1 );

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_B_FLEX, "matType" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, "Flexible SM", $txtStandardStyle, $matBackgStyle );
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_B_FLEX, "matThick" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, int($matThick), $txtStandardStyle, $matBackgStyle );
	}

	# Sec_D_FLEXTAIL ---------------------------------------------
	my $sec_D_FLEXTAIL = $secMngr->GetSection( Enums->Sec_D_FLEXTAIL );
	if ( $sec_D_FLEXTAIL->GetIsActive() ) {

		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_D_FLEXTAIL, -1, 0 );

	}
}

sub __DrawMatCoverlayAdhOuter {
	my $self             = shift;
	my $row              = shift;
	my $matText          = shift;
	my $matThick         = shift;
	my $selective        = shift;
	my $txtTitleStyle    = shift;
	my $txtStandardStyle = shift;

	my $tblMain   = $self->{"tblMain"};
	my $stckpMngr = $self->{"stackupMngr"};
	my $secMngr   = $self->{"sectionMngr"};

	# 1) Define styles
	$txtStandardStyle->SetColor( Color->new( 0, 0, 0 ) );

	my $matBackgStyle = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( EnumsStyle->Clr_ADHESIVE ) );

	# Sec_BEGIN ---------------------------------------------
	my $sec_BEGIN = $secMngr->GetSection( Enums->Sec_BEGIN );
	if ( $sec_BEGIN->GetIsActive() ) {

   #$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "matTitle" ), $tblMain->GetRowDefPos($row), undef, undef, $matText, $txtTitleStyle );
	}

	# Sec_A_MAIN ---------------------------------------------
	my $sec_A_MAIN = $secMngr->GetSection( Enums->Sec_A_MAIN );
	if ( $sec_A_MAIN->GetIsActive() && !$selective ) {

		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_A_MAIN, 0, 0 );

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matType" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, "Adhesive", $txtStandardStyle, $matBackgStyle );
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matThick" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, int($matThick), $txtStandardStyle, $matBackgStyle );
	}

	# $sec_B_FLEX ---------------------------------------------
	my $sec_B_FLEX = $secMngr->GetSection( Enums->Sec_B_FLEX );
	if ( $sec_B_FLEX->GetIsActive() ) {

		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_B_FLEX, -1, 1 );
		if ($selective) {
			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_B_FLEX, "matType" ),
							   $tblMain->GetRowDefPos($row),
							   undef, undef, "Adhesive", $txtStandardStyle, $matBackgStyle );
			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_B_FLEX, "matThick" ),
							   $tblMain->GetRowDefPos($row),
							   undef, undef, int($matThick), $txtStandardStyle, $matBackgStyle );
		}

	}

	# Sec_C_RIGIDFLEX ---------------------------------------------
	my $sec_C_RIGIDFLEX = $secMngr->GetSection( Enums->Sec_C_RIGIDFLEX );
	if ( $sec_C_RIGIDFLEX->GetIsActive() && !$selective ) {

		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_C_RIGIDFLEX, 0, 0 );

	}

	# Sec_D_FLEXTAIL ---------------------------------------------
	my $sec_D_FLEXTAIL = $secMngr->GetSection( Enums->Sec_D_FLEXTAIL );
	if ( $sec_D_FLEXTAIL->GetIsActive() ) {

		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_D_FLEXTAIL, -1, 0 );
		if ($selective) {
			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_D_FLEXTAIL, "matType" ),
							   $tblMain->GetRowDefPos($row),
							   undef, undef, "Adhesive", $txtStandardStyle, $matBackgStyle );
			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_D_FLEXTAIL, "matThick" ),
							   $tblMain->GetRowDefPos($row),
							   undef, undef, int($matThick), $txtStandardStyle, $matBackgStyle );
		}
	}

	# Sec_E_STIFFENER ---------------------------------------------
	my $sec_E_STIFFENER = $secMngr->GetSection( Enums->Sec_E_STIFFENER );

	if ( $sec_E_STIFFENER->GetIsActive() ) {

		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_E_STIFFENER, 0, 0 );
	}

	# Sec_F_STIFFENER ---------------------------------------------
	my $sec_F_STIFFENER = $secMngr->GetSection( Enums->Sec_F_STIFFENER );

	if ( $sec_F_STIFFENER->GetIsActive() ) {

		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_F_STIFFENER, 0, 0 );
	}

}

sub __DrawMatCoverlayOuter {
	my $self             = shift;
	my $row              = shift;
	my $matText          = shift;
	my $matThick         = shift;
	my $selective        = shift;
	my $txtTitleStyle    = shift;
	my $txtStandardStyle = shift;

	my $tblMain   = $self->{"tblMain"};
	my $stckpMngr = $self->{"stackupMngr"};
	my $secMngr   = $self->{"sectionMngr"};

	# 1) Define styles
	$txtStandardStyle->SetColor( Color->new( 0, 0, 0 ) );

	my $matBackgStyle = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( EnumsStyle->Clr_COVERLAY ) );

	# Sec_BEGIN ---------------------------------------------
	my $sec_BEGIN = $secMngr->GetSection( Enums->Sec_BEGIN );
	if ( $sec_BEGIN->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "matTitle" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, $matText, $txtTitleStyle );
	}

	# Sec_A_MAIN ---------------------------------------------
	my $sec_A_MAIN = $secMngr->GetSection( Enums->Sec_A_MAIN );
	if ( $sec_A_MAIN->GetIsActive() && !$selective ) {

		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_A_MAIN, 0, 0 );

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matType" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, "Coverlay", $txtStandardStyle, $matBackgStyle );
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matThick" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, int($matThick), $txtStandardStyle, $matBackgStyle );
	}

	# $sec_B_FLEX ---------------------------------------------
	my $sec_B_FLEX = $secMngr->GetSection( Enums->Sec_B_FLEX );
	if ( $sec_B_FLEX->GetIsActive() ) {

		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_B_FLEX, -1, 1 );
		if ($selective) {
			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_B_FLEX, "matType" ),
							   $tblMain->GetRowDefPos($row),
							   undef, undef, "Coverlay", $txtStandardStyle, $matBackgStyle );
			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_B_FLEX, "matThick" ),
							   $tblMain->GetRowDefPos($row),
							   undef, undef, int($matThick), $txtStandardStyle, $matBackgStyle );
		}

	}

	# Sec_C_RIGIDFLEX ---------------------------------------------
	my $sec_C_RIGIDFLEX = $secMngr->GetSection( Enums->Sec_C_RIGIDFLEX );
	if ( $sec_C_RIGIDFLEX->GetIsActive() && !$selective ) {

		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_C_RIGIDFLEX, 0, 0 );

	}

	# Sec_D_FLEXTAIL ---------------------------------------------
	my $sec_D_FLEXTAIL = $secMngr->GetSection( Enums->Sec_D_FLEXTAIL );
	if ( $sec_D_FLEXTAIL->GetIsActive() ) {

		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_D_FLEXTAIL, -1, 0 );
		if ($selective) {
			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_D_FLEXTAIL, "matType" ),
							   $tblMain->GetRowDefPos($row),
							   undef, undef, "Coverlay", $txtStandardStyle, $matBackgStyle );
			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_D_FLEXTAIL, "matThick" ),
							   $tblMain->GetRowDefPos($row),
							   undef, undef, int($matThick), $txtStandardStyle, $matBackgStyle );
		}
	}

	# Sec_E_STIFFENER ---------------------------------------------
	my $sec_E_STIFFENER = $secMngr->GetSection( Enums->Sec_E_STIFFENER );

	if ( $sec_E_STIFFENER->GetIsActive() ) {

		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_E_STIFFENER, 0, 0 );
	}

	# Sec_F_STIFFENER ---------------------------------------------
	my $sec_F_STIFFENER = $secMngr->GetSection( Enums->Sec_F_STIFFENER );

	if ( $sec_F_STIFFENER->GetIsActive() ) {

		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_F_STIFFENER, 0, 0 );
	}

}

sub __DrawMatSM {
	my $self             = shift;
	my $row              = shift;
	my $matText          = shift;
	my $matThick         = shift;
	my $coverFlexCore    = shift;    # indicate if solder mask is directly on flex core
	my $txtTitleStyle    = shift;
	my $txtStandardStyle = shift;

	my $tblMain   = $self->{"tblMain"};
	my $stckpMngr = $self->{"stackupMngr"};
	my $secMngr   = $self->{"sectionMngr"};

	# 1) Define styles
	$txtStandardStyle->SetColor( Color->new( 255, 255, 255 ) );

	my $matBackgStyle = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( EnumsStyle->Clr_SOLDERMASK ) );

	# Sec_BEGIN ---------------------------------------------
	my $sec_BEGIN = $secMngr->GetSection( Enums->Sec_BEGIN );
	if ( $sec_BEGIN->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "matTitle" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, $matText, $txtTitleStyle );
	}

	# Sec_A_MAIN ---------------------------------------------
	my $sec_A_MAIN = $secMngr->GetSection( Enums->Sec_A_MAIN );
	if ( $sec_A_MAIN->GetIsActive() ) {

		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_A_MAIN, 0, 0 );

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matType" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, "Solder mask", $txtStandardStyle, $matBackgStyle );
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matThick" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, $matThick, $txtStandardStyle, $matBackgStyle );
	}

	# $sec_B_FLEX ---------------------------------------------
	my $sec_B_FLEX = $secMngr->GetSection( Enums->Sec_B_FLEX );
	if ( $sec_B_FLEX->GetIsActive() ) {
		if ($coverFlexCore) {
			$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_B_FLEX, 0, 0 );
		}

	}

	# Sec_C_RIGIDFLEX ---------------------------------------------
	my $sec_C_RIGIDFLEX = $secMngr->GetSection( Enums->Sec_C_RIGIDFLEX );
	if ( $sec_C_RIGIDFLEX->GetIsActive() ) {

		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_C_RIGIDFLEX, 0, 0 );

	}

	# Sec_D_FLEXTAIL ---------------------------------------------
	my $sec_D_FLEXTAIL = $secMngr->GetSection( Enums->Sec_D_FLEXTAIL );
	if ( $sec_D_FLEXTAIL->GetIsActive() ) {

		if ($coverFlexCore) {
			$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_D_FLEXTAIL, 0, 0 );
		}
	}

	# Sec_E_STIFFENER ---------------------------------------------
	my $sec_E_STIFFENER = $secMngr->GetSection( Enums->Sec_E_STIFFENER );

	if ( $sec_E_STIFFENER->GetIsActive() ) {

		if ($coverFlexCore) {
			$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_E_STIFFENER, 0, 0 );
		}
	}

	# Sec_F_STIFFENER ---------------------------------------------
	my $sec_F_STIFFENER = $secMngr->GetSection( Enums->Sec_F_STIFFENER );

	if ( $sec_F_STIFFENER->GetIsActive() ) {

		if ($coverFlexCore) {
			$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_F_STIFFENER, 0, 0 );
		}
	}

}

sub __DrawMatCopper {
	my $self             = shift;
	my $row              = shift;
	my $matText          = shift;
	my $matThick         = shift;
	my $isPlated         = shift;
	my $lNumber          = shift;
	my $cuUssage         = shift;
	my $foil             = shift;
	my $flex             = shift;
	my $txtTitleStyle    = shift;
	my $txtCuStyle       = shift;
	my $txtStandardStyle = shift;

	my $tblMain   = $self->{"tblMain"};
	my $stckpMngr = $self->{"stackupMngr"};
	my $secMngr   = $self->{"sectionMngr"};

	# 1) Define styles
	$txtStandardStyle->SetColor( Color->new( 255, 255, 255 ) );

	my $matBackgStyle = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( EnumsStyle->Clr_COPPER ) );
	my $matCoreBackgStyle =
	  BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( $flex ? EnumsStyle->Clr_COREFLEX : EnumsStyle->Clr_CORERIGID ) );

	# Sec_BEGIN ---------------------------------------------
	my $sec_BEGIN = $secMngr->GetSection( Enums->Sec_BEGIN );
	if ( $sec_BEGIN->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "matTitle" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, $matText, $txtTitleStyle );

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "cuUsage" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, "L" . $lNumber . ( defined $cuUssage ? " (" . int($cuUssage) . "%)" : "" ), $txtCuStyle );
	}

	# Sec_A_MAIN ---------------------------------------------
	my $sec_A_MAIN = $secMngr->GetSection( Enums->Sec_A_MAIN );
	if ( $sec_A_MAIN->GetIsActive() ) {

		if ( !defined $cuUssage || $cuUssage > 0 ) {

			$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_A_MAIN, 0, 0 );

			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matType" ),
							   $tblMain->GetRowDefPos($row),
							   undef, undef, "Copper" . ( $foil ? " foil" : "" ),
							   $txtStandardStyle, $matBackgStyle );
			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matThick" ),
							   $tblMain->GetRowDefPos($row),
							   undef, undef, $matThick . ( $isPlated ? "+25 Plt" : "" ),
							   $txtStandardStyle, $matBackgStyle );

		}
		else {
			$self->__FillRowBackg( $row, $matBackgStyle,     Enums->Sec_A_MAIN, 0,  0 );
			$self->__FillRowBackg( $row, $matCoreBackgStyle, Enums->Sec_A_MAIN, +1, -1 );
		}
	}

	# $sec_B_FLEX ---------------------------------------------
	my $sec_B_FLEX = $secMngr->GetSection( Enums->Sec_B_FLEX );
	if ( $sec_B_FLEX->GetIsActive() ) {

		if ( !defined $cuUssage || $cuUssage > 0 ) {
			if ($flex) {
				$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_B_FLEX, 0, 0 );
			}
		}
	}

	# Sec_C_RIGIDFLEX ---------------------------------------------
	my $sec_C_RIGIDFLEX = $secMngr->GetSection( Enums->Sec_C_RIGIDFLEX );
	if ( $sec_C_RIGIDFLEX->GetIsActive() ) {

		if ( !defined $cuUssage || $cuUssage > 0 ) {
			$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_C_RIGIDFLEX, 0, 0 );
		}
		else {
			$self->__FillRowBackg( $row, $matBackgStyle,     Enums->Sec_C_RIGIDFLEX, 0,  0 );
			$self->__FillRowBackg( $row, $matCoreBackgStyle, Enums->Sec_C_RIGIDFLEX, +1, -1 );
		}

	}

	# Sec_D_FLEXTAIL ---------------------------------------------
	my $sec_D_FLEXTAIL = $secMngr->GetSection( Enums->Sec_D_FLEXTAIL );
	if ( $sec_D_FLEXTAIL->GetIsActive() ) {

		if ( !defined $cuUssage || $cuUssage > 0 ) {

			if ($flex) {
				$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_D_FLEXTAIL, 0, 0 );
			}

		}
	}

	# Sec_E_STIFFENER ---------------------------------------------
	my $sec_E_STIFFENER = $secMngr->GetSection( Enums->Sec_E_STIFFENER );

	if ( $sec_E_STIFFENER->GetIsActive() ) {

		if ( !defined $cuUssage || $cuUssage > 0 ) {
			if ($flex) {
				$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_E_STIFFENER, 0, 0 );
			}
		}
	}

	# Sec_F_STIFFENER ---------------------------------------------
	my $sec_F_STIFFENER = $secMngr->GetSection( Enums->Sec_F_STIFFENER );

	if ( $sec_F_STIFFENER->GetIsActive() ) {

		if ( !defined $cuUssage || $cuUssage > 0 ) {
			if ($flex) {
				$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_F_STIFFENER, 0, 0 );
			}
		}
	}
}

sub __DrawMatPrepreg {
	my $self             = shift;
	my $row              = shift;
	my $matText          = shift;
	my $matThick         = shift;
	my $isNoFLow         = shift;
	my $noFlowType       = shift;
	my $displayType      = shift;
	my $txtTitleStyle    = shift;
	my $txtStandardStyle = shift;

	my $tblMain   = $self->{"tblMain"};
	my $stckpMngr = $self->{"stackupMngr"};
	my $secMngr   = $self->{"sectionMngr"};

	# 1) Define styles
	$txtStandardStyle->SetColor( Color->new( 255, 255, 255 ) );

	my $matBackgStyle = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( EnumsStyle->Clr_PREPREG ) );

	# Sec_BEGIN ---------------------------------------------
	my $sec_BEGIN = $secMngr->GetSection( Enums->Sec_BEGIN );
	if ( $sec_BEGIN->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "matTitle" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, $matText, $txtTitleStyle );
	}

	# Sec_A_MAIN ---------------------------------------------
	my $sec_A_MAIN = $secMngr->GetSection( Enums->Sec_A_MAIN );
	if ( $sec_A_MAIN->GetIsActive() ) {

		my $stdVV = $stckpMngr->GetPcbType() eq EnumsGeneral->PcbType_MULTI || $stckpMngr->GetPcbType() eq EnumsGeneral->PcbType_MULTIFLEX ? 1 : 0;

		# clear marigns of prepreg when standard multilayer
		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_A_MAIN, $stdVV ? 1 : 0, $stdVV ? -1 : 0 );
		my $typeTxt = ( $isNoFLow ? "NoFlow prepreg " . ( $noFlowType eq StackEnums->NoFlowPrepreg_P1 ? "1" : "2" ) : "Prepreg" );

		if ($displayType) {

			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matType" ),
							   $tblMain->GetRowDefPos($row),
							   undef, undef, $typeTxt, $txtStandardStyle, $matBackgStyle );
			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matThick" ),
							   $tblMain->GetRowDefPos($row),
							   undef, undef, int($matThick), $txtStandardStyle, $matBackgStyle );

		}
	}

	# Sec_C_RIGIDFLEX ---------------------------------------------
	my $sec_C_RIGIDFLEX = $secMngr->GetSection( Enums->Sec_C_RIGIDFLEX );
	if ( $sec_C_RIGIDFLEX->GetIsActive() ) {

		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_C_RIGIDFLEX, 0, 0 );

	}

}

sub __DrawMatCore {
	my $self             = shift;
	my $row              = shift;
	my $matText          = shift;
	my $matThick         = shift;
	my $isFlex           = shift;
	my $core             = shift;
	my $txtTitleStyle    = shift;
	my $txtStandardStyle = shift;

	my $tblMain   = $self->{"tblMain"};
	my $stckpMngr = $self->{"stackupMngr"};
	my $secMngr   = $self->{"sectionMngr"};

	# 1) Define styles
	$txtStandardStyle->SetColor( $isFlex ? Color->new( 0, 0, 0 ) : Color->new( 255, 255, 255 ) );

	my $matBackgStyle =
	  BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( $isFlex ? EnumsStyle->Clr_COREFLEX : EnumsStyle->Clr_CORERIGID ) );

	# Sec_BEGIN ---------------------------------------------
	my $sec_BEGIN = $secMngr->GetSection( Enums->Sec_BEGIN );
	if ( $sec_BEGIN->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "matTitle" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, $matText, $txtTitleStyle );
	}

	# Sec_A_MAIN ---------------------------------------------
	my $sec_A_MAIN = $secMngr->GetSection( Enums->Sec_A_MAIN );
	if ( $sec_A_MAIN->GetIsActive() ) {

		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_A_MAIN, 0, 0 );

		my $text = ( $isFlex ? "Flex" : "Rigid" );
		$text .= ( $core ? " core" : " laminate" );

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matType" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, $text, $txtStandardStyle, $matBackgStyle );
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matThick" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, $matThick, $txtStandardStyle, $matBackgStyle );
	}

	# $sec_B_FLEX ---------------------------------------------
	my $sec_B_FLEX = $secMngr->GetSection( Enums->Sec_B_FLEX );
	if ( $sec_B_FLEX->GetIsActive() ) {

		if ($isFlex) {
			$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_B_FLEX, 0, 0 );
		}

	}

	# Sec_C_RIGIDFLEX ---------------------------------------------
	my $sec_C_RIGIDFLEX = $secMngr->GetSection( Enums->Sec_C_RIGIDFLEX );
	if ( $sec_C_RIGIDFLEX->GetIsActive() ) {

		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_C_RIGIDFLEX, 0, 0 );

	}

	# Sec_D_FLEXTAIL ---------------------------------------------
	my $sec_D_FLEXTAIL = $secMngr->GetSection( Enums->Sec_D_FLEXTAIL );
	if ( $sec_D_FLEXTAIL->GetIsActive() ) {

		if ($isFlex) {
			$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_D_FLEXTAIL, 0, 0 );
		}
	}

	# Sec_E_STIFFENER ---------------------------------------------
	my $sec_E_STIFFENER = $secMngr->GetSection( Enums->Sec_E_STIFFENER );

	if ( $sec_E_STIFFENER->GetIsActive() ) {

		if ($isFlex) {
			$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_E_STIFFENER, 0, 0 );
		}
	}
	
	# Sec_F_STIFFENER ---------------------------------------------
	my $sec_F_STIFFENER = $secMngr->GetSection( Enums->Sec_F_STIFFENER );

	if ( $sec_F_STIFFENER->GetIsActive() ) {

		if ($isFlex) {
			$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_F_STIFFENER, 0, 0 );
		}
	}

}

sub __FillRowBackg {
	my $self           = shift;
	my $row            = shift;
	my $backgStyle     = shift;
	my $secType        = shift;
	my $startColOffset = shift // 0;    # number of column positive/negative, where background starts by filled
	my $endColOffset   = shift // 0;    # number of column positive/negative, where background starts by filled

	my $tblMain = $self->{"tblMain"};
	my $secMngr = $self->{"sectionMngr"};

	my $sec     = $secMngr->GetSection($secType);
	my @colsDef = $sec->GetAllColumns();

	my $startPos = $secMngr->GetColumnPos( $secType, $colsDef[0]->GetKey() ) + $startColOffset;
	my $endPos   = $secMngr->GetColumnPos( $secType, $colsDef[ scalar(@colsDef) - 1 ]->GetKey() ) + $endColOffset;

	for ( my $i = $startPos ; $i <= $endPos ; $i++ ) {

		$tblMain->AddCell( $i, $tblMain->GetRowDefPos($row), undef, undef, undef, undef, $backgStyle );

	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

