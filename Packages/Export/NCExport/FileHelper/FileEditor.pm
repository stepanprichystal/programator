
#-------------------------------------------------------------------------------------------#
# Description: Class allow modify nc files, before ther are mmerged and
# moved from output folder to archive
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NCExport::FileHelper::FileEditor;

use Class::Interface;

&implements('Packages::Export::NCExport::FileHelper::IFileEditor');

#3th party library
use strict;
use warnings;
use List::Util qw(first);

#local library

use aliased 'Packages::Export::NCExport::Helpers::NCHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::ProductionPanel::Helper';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::Stackup::StackupNC::StackupNC';
use aliased 'CamHelpers::CamNCHooks';
use aliased 'CamHelpers::CamJob';
use aliased 'Helpers::JobHelper';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {

	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}        = shift;
	$self->{"jobId"}        = shift;
	$self->{"stepName"}     = shift;
	$self->{"layerCnt"}     = shift;
	$self->{"exportSingle"} = shift;

	$self->{"pcbType"} = JobHelper->GetPcbType( $self->{"jobId"} );

	return $self;
}

# Run imidiattely file is open for merging/moving to archiv
# Hance to change something
sub EditAfterOpen {
	my $self      = shift;
	my $layer     = shift;
	my $parseFile = shift;    #parsed file in hash
	my $opItem    = shift;    #operation item reference
	my $machine   = shift;

	# ================================================================
	# 1) EDIT: edit all files, which are generated from V1
	# Add message
	if ( $layer->{"type"} eq EnumsGeneral->LAYERTYPE_plt_fcDrill ) {

		my $m47Mess;

		if ( $opItem->{"name"} =~ /c[0-9]+/ ) {

			$m47Mess = "\n(M47, Vrtani okoli po " . $opItem->GetPressOrder() . ". lisovani.)";
		}
		elsif ( $layer->{"gROWname"} eq "v1" && ( $opItem->{"name"} =~ m/v1/ || $opItem->{"name"} =~ m/^j[0-9]+$/ ) ) {

			# Add message to file (one single program with drilling frame for all cores)
			$m47Mess = "\n(M47, Vrtani okoli jadra.)";

			# Delete "focus header", because it is not needed. (first drilling to empty laminate)
			@{ $parseFile->{"header"} } = ("%%3000\n");
		}
		elsif ( $layer->{"gROWname"} =~ /^v1j([0-9]+)/ && ( $opItem->{"name"} =~ m/v\d+/ || $opItem->{"name"} =~ m/^j[0-9]+$/ ) ) {

			my $coreNum = ( $opItem->{"name"} =~ m/[vj](\d+)/ )[0];

			# Add message to file (special program with drilling frame for specific core)
			$m47Mess = "\n(M47, Vrtani okoli jadra J$coreNum.)";

			# Delete "focus header", because it is not needed. (first drilling to empty laminate)
			@{ $parseFile->{"header"} } = ("%%3000\n");
		}

		my %i = ();
		$i{"line"} = $m47Mess;
		splice @{ $parseFile->{"body"} }, 0, 0, \%i;
	}

	# ================================================================
	# 2) EDIT:  edit z-axis millin top and bot (plated and nonplated)
	# Reason: InCam can't add G82
	# Put message M47, on the right place, before start new tool
	if (    $layer->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillTop
		 || $layer->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillBot
		 || $layer->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillTop
		 || $layer->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillBot
		 || $layer->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_cbMillTop
		 || $layer->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_cbMillBot )
	{
		NCHelper->AddG83WhereMissing($parseFile);
		NCHelper->PutMessRightPlace($parseFile);
	}

	# ================================================================
	# 3) EDIT: Edit drilled number in v1 layer. Decide if v1 layer is added to blind drill/ core drill.
	# Add:
	# - thick of Cu
	# - J<number of core> if opItem is core
	if ( $layer->{"type"} eq EnumsGeneral->LAYERTYPE_plt_fcDrill && $self->{"layerCnt"} > 2 ) {

		my $stackup = Stackup->new( $self->{"inCAM"}, $self->{"jobId"} );

		# case of blind drill (not last pressing) or burried (core drilling) or only frame drill (v1)
		if ( $layer->{"gROWname"} eq "v1" && ( $opItem->{"name"} =~ /^c[0-9]+$/ || $opItem->{"name"} =~ /^j[0-9]+$/ ) ) {

			my $cuThickMark = "";
			my $coreMark    = "";
			my $cuThick;

			my %pressInfo = $stackup->GetPressProducts();

			# Case drilling after pressing
			# Keep drilled number only if exist more than one pressing and it is frist pressing
			if ( $opItem->{"name"} =~ /c[0-9]+/ ) {

				if ( !( $stackup->GetPressCount() > 1 && $opItem->GetPressOrder() == 1 ) ) {

					NCHelper->RemoveDrilledNumber($parseFile);
				}
			}

			# case  burried (core drilling) add J<number of core> to drilled number
			# if layer is: v1j\d drilled number is already included
			if ( $opItem->{"name"} =~ m/^j([0-9]+)$/ ) {

				my $coreNum = $1;

				if ( $coreNum > 0 ) {

					my @cores = $stackup->GetAllCores();
					$cuThick  = $cores[ $coreNum - 1 ]->GetTopCopperLayer()->GetThick();
					$coreMark = "J" . $coreNum;
				}
			}

			$cuThickMark = Helper->__GetCuThickPanelMark($cuThick);
			NCHelper->ChangeDrilledNumber( $parseFile, $cuThickMark, $coreMark );
		}
	}

	# ================================================================
	# 4) EDIT:Add drilled pcb number to rout layers
	# (not possible add this in hooks when layer is type "rout")

	if (    $layer->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_cvrlycMill
		 || $layer->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_cvrlysMill
		 || $layer->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_prepregMill
		 || $layer->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_stiffcMill
		 || $layer->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_stiffsMill
		 || $layer->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_soldcMill
		 || $layer->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_soldsMill
		 || $layer->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_tapecMill
		 || $layer->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_tapesMill )
	{

		# get tool number of r850 tool
		my $t = ( grep { $_->{"line"} =~ /T\d*D85([^\d]|$)/i } @{ $parseFile->{"footer"} } )[0];

		die "Layer: " . $layer->{"gROWname"} . " doesn't contain tool 0.850mm in panel step. It is needed for drilled number" unless ( defined $t );

		my ($toolNum) = $t->{"line"} =~ /(T\d+)/;

		# Search postition in program with theses tool

		for ( my $i = 0 ; $i < scalar( @{ $parseFile->{"body"} } ) ; $i++ ) {

			my $l = $parseFile->{"body"}->[$i];

			if ( defined $l->{"tool"} && $l->{"line"} =~ /$toolNum([^\d]|$)/i ) {

				my $numMirror = $layer->{"gROWdrl_dir"} eq "bot2top" ? 1 : 0;

				my @scanMarks =
				  CamNCHooks->GetLayerCamMarks( $self->{"inCAM"}, $self->{"jobId"}, $self->{"stepName"},
												( $self->{"layerCnt"} > 2 ? "v2" : "c" ), $numMirror );

				my %lim = CamJob->GetProfileLimits( $self->{"inCAM"}, $self->{"jobId"}, $self->{"stepName"} );
				my %nullPoint = ( "x" => abs( $lim{"xmax"} - $lim{"xmin"} ) / 2, "y" => $lim{"ymin"} + 4 );

				my $numPosition = $self->{"layerCnt"} > 2 ? "vvframe" : "stdframe";
				my $dn = CamNCHooks->GetDrilledNumber( $self->{"jobId"}, $numPosition, $machine->{"id"}, \@scanMarks, \%nullPoint, 0 );

				# PRPEREG - Add prepreg number
				if ( $layer->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_prepregMill ) {

					my ( $pre, $suf ) = $dn =~ m/^(.*M97,\w\d{6})(.*)$/;
					my $pNum = " P" . ( $layer->{"gROWname"} =~ m/^fprprg(\d)$/ )[0];
					$dn = $pre . $pNum . $suf . "\n";
				}

				# COVERLAY and STIFFENER - Add coverlay/stiffener signal layer name
				if (    $layer->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_cvrlycMill
					 || $layer->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_cvrlysMill
					 || $layer->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_stiffcMill
					 || $layer->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_stiffsMill 
					 || $layer->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_tapecMill
					 || $layer->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_tapesMill)
				{

					my ( $pre, $suf ) = $dn =~ m/^(.*M97,\w\d{6})(.*)$/;
					my $ncStart = $layer->{"gROWdrl_start"};
					my $sigLayer;
					if (    $layer->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_cvrlycMill
						 || $layer->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_cvrlysMill )
					{

						($sigLayer) = $ncStart =~ /^cvrl(.*)/;
					}
					elsif (    $layer->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_stiffcMill
							|| $layer->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_stiffsMill )
					{

						($sigLayer) = $ncStart =~ /^stiff(.*)/;
					
					}elsif (    $layer->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_tapecMill
							|| $layer->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_tapesMill )
					{

						($sigLayer) = $ncStart =~ /^tp(.*)/;
					}

					$dn = $pre . " " . $sigLayer . $suf . "\n";
				}

				my ($xVal) = $dn =~ /X(\d+\.\d+)Y/;

				my @cmd = ();

				# Mirror drilled pcbid (must be mirrored in subroutine in order to mirror involve only drill number)
				if ($numMirror) {
					push( @cmd, { "line" => "M31" } );
					push( @cmd, { "line" => "$dn" } );
					push( @cmd, { "line" => "M02X" . sprintf( "%.3f", 2 * $xVal ) . "Y0.000M70\n" } );
					push( @cmd, { "line" => "M30\n" } );
				}
				else {
					push( @cmd, { "line" => "$dn" } );
				}

				splice @{ $parseFile->{"body"} }, $i + 1, 0, @cmd;

			}

		}

	}

	# ================================================================
	# 5) EDIT:Move F_<guid> definition from tool line to first line after tool

	my $isRout = scalar( grep { $_->{"gROWlayer_type"} eq "rout" } $opItem->GetSortedLayers() ) ? 1 : 0;
	if ($isRout) {

		my @b = @{ $parseFile->{"body"} };

		# index of rows where is F_<guid> definition
		my @tIdx = grep { defined $b[$_]->{"tool"} && $b[$_]->{"line"} =~ /\(F_[\w-]+\)/ } 0 .. $#b;

		foreach my $idx (@tIdx) {

			my ($fDef) = $b[$idx]->{"line"} =~ /(\(F_[\w-]+\))/;

			$b[$idx]->{"line"} =~ s/\(F_[\w-]+\)//;    # cut F_<guid>
			$b[ $idx + 1 ]->{"line"} =~ s/\n$//;
			$b[ $idx + 1 ]->{"line"} .= $fDef . "\n"    # copy F_<guid> to next line
		}

	}

	# ================================================================
	# 6) EDIT: If export single set F_<guid> definition to F_not_defined

	# Remove F_<guid>, if export single
	if ( $self->{"exportSingle"} && $isRout ) {

		my @b = @{ $parseFile->{"body"} };

		# index of rows where is F_<guid> definition
		my @tIdx = grep { $b[$_]->{"line"} =~ /\(F_[\w-]+\)/ } 0 .. $#b;
		foreach my $idx (@tIdx) {
			$b[$idx]->{"line"} =~ s/\(F_[\w-]+\)/\(F_not_defined\)/;
		}
	}

}

# Run before file is save after merging before moving to archiv
# Chance to change something
sub EditBeforeSave {
	my $self      = shift;
	my $parseFile = shift;    #parsed file in hash
	my $opItem    = shift;    #operation item reference

	# ================================================================
	# 1) EDIT: if operation item contains only layers type of:
	# LAYERTYPE_nplt_nMill
	# LAYERTYPE_nplt_nDrill
	# Put M47, Frezovani po prokovu (2nd mess in program) into brackets (M47 stop machine, brackets no)

	my @l =
	  grep { $_->{"type"} ne EnumsGeneral->LAYERTYPE_nplt_nMill && $_->{"type"} ne EnumsGeneral->LAYERTYPE_nplt_nDrill } $opItem->GetSortedLayers();

	unless ( scalar(@l) ) {

		# put M47, Message to brackets
		my $messageCnt = 0;
		for ( my $i = 0 ; $i < scalar( @{ $parseFile->{"body"} } ) ; $i++ ) {

			if ( $parseFile->{"body"}->[$i]->{"line"} =~ /m47/i ) {

				$messageCnt++;

				if ( $messageCnt == 2 ) {
					$parseFile->{"body"}->[$i]->{"line"} =~ s/\n//;
					$parseFile->{"body"}->[$i]->{"line"} = "(" . $parseFile->{"body"}->[$i]->{"line"} . ")\n";
					last;
				}

			}

		}
	}

	# ================================================================
	# 2) EDIT: if operation item contains only layers type of:
	# LAYERTYPE_plt_nDrill
	# LAYERTYPE_plt_nMill
	# Put M47, Frezovani pred prokovem (2nd mess in program) into brackets (M47 stop machine, brackets no)
	# 18.3. LBA - pozadavek zrusit zavorky, aby se masina zastavila

#	my @l2 =
#	  grep { $_->{"type"} ne EnumsGeneral->LAYERTYPE_plt_nDrill && $_->{"type"} ne EnumsGeneral->LAYERTYPE_plt_nMill } $opItem->GetSortedLayers();
#
#	unless ( scalar(@l2) ) {
#
#		# put M47, Message to brackets
#		my $messageCnt = 0;
#		for ( my $i = 0 ; $i < scalar( @{ $parseFile->{"body"} } ) ; $i++ ) {
#
#			if ( $parseFile->{"body"}->[$i]->{"line"} =~ /m47/i ) {
#
#				$messageCnt++;
#
#				if ( $messageCnt == 2 ) {
#					$parseFile->{"body"}->[$i]->{"line"} =~ s/\n//;
#					$parseFile->{"body"}->[$i]->{"line"} = "(" . $parseFile->{"body"}->[$i]->{"line"} . ")\n";
#					last;
#				}
#
#			}
#
#		}
#	}

	# =============================================================
	# 3) EDIT: Renumber tool numbers ASC if program is merged from more layers

	if ( scalar( $opItem->GetSortedLayers() ) > 1 ) {

		NCHelper->RenumberToolASC($parseFile);
	}

	# =============================================================
	# 4) If CCD is active, add M47 in ordert to stop machine and let user add pad

	if (    $opItem->GetHeaderLayer()->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_nDrill
		 || $opItem->GetHeaderLayer()->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_nMill
		 || $opItem->GetHeaderLayer()->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_nMill )
	{

		# Search if header is active (no brackets) + header is more than one line
		my $messageCnt = 0;
		my $bracket = first { $_ =~ /[\(\)]/ } @{ $parseFile->{"header"} };

		if ( !defined $bracket && scalar( @{ $parseFile->{"header"} } ) > 1 ) {

			my $l;

			if (    $self->{"pcbType"} eq EnumsGeneral->PcbType_1VFLEX
				 || $self->{"pcbType"} eq EnumsGeneral->PcbType_2VFLEX
				 || $self->{"pcbType"} eq EnumsGeneral->PcbType_MULTIFLEX )
			{

				my @depthMill = grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillTop || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillBot }
				  $opItem->GetSortedLayers();

				if (@depthMill) {

					# Add extra text after depth milling - add white drill pad

					my $extraText = "\nM47, Pridani frezovaci podlozky po navedeni CCD\n";
					for ( my $i = 0 ; $i < scalar( @{ $parseFile->{"body"} } ) ; $i++ ) {

						if ( $parseFile->{"body"}->[$i]->{"line"} =~ /Frezovani po prokovu/i ) {
							$parseFile->{"body"}->[$i]->{"line"} = "M47, Frezovani po prokovu - Pridej bilou vrtaci podlozku!\n";
							last;
						}
					}
				}

				$l = "\nM47, Oddelej pripravek pro navadeni a pridej bilou vrtaci podlozku\n";

			}
			else {

				$l = "\nM47, Pridani frezovaci podlozky po navedeni CCD\n";
			}

			push( @{ $parseFile->{"header"} }, $l );

		}

	}

}

1;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
