
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

#local library

use aliased 'Packages::Export::NCExport::Helpers::NCHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::ProductionPanel::Helper';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::Stackup::StackupNC::StackupNC';
use aliased 'CamHelpers::CamNCHooks';
use aliased 'CamHelpers::CamJob';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {

	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}    = shift;
	$self->{"jobId"}    = shift;
	$self->{"stepName"} = shift;
	$self->{"layerCnt"} = shift;

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
	if ( $layer->{"type"} eq EnumsGeneral->LAYERTYPE_plt_fDrill ) {

		my $m47Mess;

		if ( $opItem->{"name"} =~ /c[0-9]+/ ) {

			$m47Mess = "\n(M47, Vrtani okoli po " . $opItem->GetPressOrder() . ". lisovani.)";
		}
		elsif ( $opItem->{"name"} =~ /v1/ || $opItem->{"name"} =~ /j([0-9]+)/ ) {

			# Add message to file
			$m47Mess = "\n(M47, Vrtani okoli jadra.)";

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
	if ( $layer->{"type"} eq EnumsGeneral->LAYERTYPE_plt_fDrill && $self->{"layerCnt"} > 2 ) {

		my $stackup = Stackup->new( $self->{"jobId"} );

		# case of blind drill (not last pressing) or burried (core drilling) or only frame drill (v1)
		if ( $opItem->{"name"} =~ /c[0-9]+/ || $opItem->{"name"} =~ /v1/ || $opItem->{"name"} =~ /j[0-9]+/ ) {

			my $cuThickMark = "";
			my $coreMark    = "";
			my $cuThick;

			my %pressInfo = $stackup->GetPressInfo();

			# case of blind drill (not last pressing) or burried (core drilling)
			if ( $opItem->{"name"} =~ /c[0-9]+/ ) {

				if ( $opItem->GetPressOrder() != $stackup->GetPressCount() ) {

					my $press     = $pressInfo{ $opItem->GetPressOrder() };
					my $topCuName = $press->{"top"};
					$cuThick = $stackup->GetCuLayer($topCuName)->GetThick();
				}

			}

			# case of  frame drill (v1)
			if ( $opItem->{"name"} =~ /v1/ ) {

				#take first cu on first core

				my @cores = $stackup->GetAllCores();
				$cuThick = $cores[0]->GetTopCopperLayer()->GetThick();

			}

			# case  burried (core drilling)
			if ( $opItem->{"name"} =~ /j[0-9]+/ ) {

				# add J<number of core> if opItem is core behind pcb
				if ( $opItem->{"name"} =~ m/j([0-9]+)/ ) {

					my $coreNum = $1;

					if ( $coreNum > 0 ) {

						my @cores = $stackup->GetAllCores();
						$cuThick = $cores[ $coreNum - 1 ]->GetTopCopperLayer()->GetThick();

						$coreMark = "J" . $coreNum;

					}
				}
			}

			$cuThickMark = Helper->__GetCuThickPanelMark($cuThick);

			NCHelper->ChangeDrilledNumber( $parseFile, $cuThickMark, $coreMark );
		}
	}

	# ================================================================
	# 4) EDIT:Add drilled pcb number (not possible add this in hooks when layer is type "rout")

	if ( $layer->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_cvrlycMill || $layer->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_cvrlysMill ||
	    $layer->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_prepregMill ) {

		# get tool number of r850 tool
		my $t = ( grep { $_->{"line"} =~ /T\d*D85([^\d]|$)/i } @{ $parseFile->{"footer"} } )[0];

		if ( defined $t ) {

			my ($toolNum) = $t->{"line"} =~ /(T\d+)/;

			# Search postition in program with theses tool

			for ( my $i = 0 ; $i < scalar( @{ $parseFile->{"body"} } ) ; $i++ ) {

				my $l = $parseFile->{"body"}->[$i];

				if ( defined $l->{"tool"} && $l->{"line"} =~ /$toolNum([^\d]|$)/i ) {

					my $mirror = $layer->{"gROWdrl_dir"} eq "bot2top" ? 1 : 0;
					my @scanMarks =
					  CamNCHooks->GetLayerCamMarks( $self->{"inCAM"}, $self->{"jobId"}, $self->{"stepName"}, "c", $mirror );

					my %lim = CamJob->GetProfileLimits( $self->{"inCAM"}, $self->{"jobId"}, $self->{"stepName"} );
					my %nullPoint = ( "x" => abs( $lim{"xmax"} - $lim{"xmin"} ) / 2, "y" => $lim{"ymin"} + 4 );

					my $dn = CamNCHooks->GetDrilledNumber( $self->{"jobId"}, $layer->{"gROWname"}, $machine->{"id"}, \@scanMarks, \%nullPoint, 0 );
					my ($xVal) = $dn =~ /X(\d+\.\d+)Y/;

					my @cmd = ();
					
					# Mirror drilled pcbid (must be mirrored in subroutine in order to mirror involve only drill number)
					if ($mirror) {
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

	my @l2 =
	  grep { $_->{"type"} ne EnumsGeneral->LAYERTYPE_plt_nDrill && $_->{"type"} ne EnumsGeneral->LAYERTYPE_plt_nMill } $opItem->GetSortedLayers();

	unless ( scalar(@l2) ) {

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

	# =============================================================
	# 3) EDIT: Renumber tool numbers ASC if program is merged from more layers

	if ( scalar( $opItem->GetSortedLayers() ) > 1 ) {

		NCHelper->RenumberToolASC($parseFile);
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
