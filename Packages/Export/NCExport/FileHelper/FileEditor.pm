
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

use aliased 'Packages::Export::NCExport::NCHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::ProductionPanel::Helper';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::Stackup::StackupNC::StackupNC';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {

	my $self = shift;
	$self = {};
	bless $self;

	$self->{"pcbId"}    = shift;
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

	# ================================================================
	# 1) EDIT: edit all files, which are generated from V1
	if ( $layer->{"type"} eq EnumsGeneral->LAYERTYPE_plt_fDrill ) {

		my $m47Mess;

		if ( $opItem->{"name"} =~ /c[0-9]+/ ) {

			$m47Mess = "\nM47, Vrtani okoli po " . $opItem->GetPressOrder() . ". lisovani.\n";
		}
		elsif ( $opItem->{"name"} =~ /v1/ || $opItem->{"name"} =~ /j([0-9]+)/ ) {

			# Add message to file
			$m47Mess = "\nM47, Vrtani okoli jadra.";

			# Delete "focus header", because it is not needed. (first drilling to empty laminate)
			@{ $parseFile->{"header"} } = ('%%3000');
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
		 || $layer->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_jbMillTop
		 || $layer->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_jbMillBot )
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

		my $stackup = Stackup->new( $self->{"pcbId"} );

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
					$cuThick   = $stackup->GetCuLayer($topCuName)->GetThick();
				}

			}

			# case of  frame drill (v1)
			if ( $opItem->{"name"} =~ /v1/ ) {

				#take first cu on first core

				my @cores   = $stackup->GetAllCores();
				$cuThick = $cores[0]->GetTopCopperLayer()->GetThick();

			}

			# case  burried (core drilling)
			if ( $opItem->{"name"} =~ /j[0-9]+/ ) {


				# add J<number of core> if opItem is core behind pcb
				if ( $opItem->{"name"} =~ m/j([0-9]+)/ ) {
					
					my $coreNum = $1;
					
					if($coreNum > 0){
						
						my @cores   = $stackup->GetAllCores();
						$cuThick = $cores[$coreNum-1]->GetTopCopperLayer()->GetThick();
						
						$coreMark = "J" . $coreNum;
						
					}
				}
			}

			$cuThickMark = Helper->__GetCuThickPanelMark($cuThick);

			NCHelper->ChangeDrilledNumber( $parseFile, $cuThickMark, $coreMark );
		}
	}
}

# Run before file is save after merging before moving to archiv
# Chance to change something
sub EditBeforeSave {
	my $self      = shift;
	my $parseFile = shift;    #parsed file in hash
	my $opItem    = shift;    #operation item reference

}    #first argument OperationMangr

1;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
