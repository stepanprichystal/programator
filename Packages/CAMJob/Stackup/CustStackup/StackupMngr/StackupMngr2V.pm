
#-------------------------------------------------------------------------------------------#
# Description: Nif Builder is responsible for creation nif file depend on pcb type
# Builder for pcb no copper
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::CustStackup::StackupMngr::StackupMngr2V;
use base('Packages::CAMJob::Stackup::CustStackup::StackupMngr::StackupMngrBase');

#3th party library
use strict;
use warnings;
use List::Util qw(first min);

#local library

use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';
use aliased 'CamHelpers::CamJob';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Enums::EnumsGeneral';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	return $self;
}

sub GetLayerCnt {
	my $self = shift;

	my $lCnt = CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $self->{"jobId"} );

	return $lCnt;

}

sub GetStackupLayers {
	my $self = shift;

	my @sigL = grep { $_->{"gROWname"} =~ /^[cs]$/ } @{ $self->{"boardBaseLayers"} };

	if ( $self->GetPcbType() eq EnumsGeneral->PcbType_NOCOPPER ) {
		@sigL = ();
	}
	if ( $self->GetPcbType() eq EnumsGeneral->PcbType_1VFLEX ) {
		@sigL = grep { $_->{"gROWname"} eq "c" } @sigL;
	}

	return @sigL;
}

sub GetExistCvrl {
	my $self = shift;
	my $side = shift;    # top/bot
	my $info = shift;    # reference for storing info

	my $l = $side eq "top" ? "coverlayc" : "coverlays";

	my $exist = defined( first { $_->{"gROWname"} eq $l } @{ $self->{"boardBaseLayers"} } ) ? 1 : 0;

	if ($exist) {

		if ( defined $info ) {

			my $matInfo = HegMethods->GetPcbCoverlayMat( $self->{"jobId"} );

			my $thick    = $matInfo->{"tloustka"} * 1000000;
			my $thickAdh = $matInfo->{"tloustka_lepidlo"} * 1000000;

			$info->{"adhesiveText"}  = "";
			$info->{"adhesiveThick"} = $thickAdh;
			$info->{"cvrlText"}      = ( $matInfo->{"nazev_subjektu"} =~ /(LF\s\d+)/ )[0];    # ? is not store
			$info->{"cvrlThick"}     = $thick - $thickAdh;
			$info->{"selective"}     = 0;                                                     # Selective coverlay can bz onlz at RigidFLex pcb

		}
	}

	return $exist;
}

sub GetMaterialName {
	my $self = shift;

	return $self->{"pcbInfoIS"}->{"material_nazev"};
}

sub GetCuThickness {
	my $self = shift;
	
	return HegMethods->GetOuterCuThick( $self->{"jobId"} );
}

sub GetTG {
	my $self = shift;

	# 1) Get min TG of PCB
	my $matKind = HegMethods->GetMaterialKind( $self->{"jobId"}, 1 );

	my $minTG = undef;

	if ( $matKind =~ /tg\s*(\d+)/i ) {

		# single kinf of stackup materials

		$minTG = $1;
	}

	# 2) Get min TG of estra layers (stiffeners/double coated tapes etc..)
	my $specTg = $self->_GetSpecLayerTg();

	if ( defined $minTG && defined $specTg ) {
		$minTG = min( ( $minTG, $specTg ) );
	}

	return $minTG;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

