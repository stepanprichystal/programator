
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

#local library

use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::Stackup::Stackup::Enums' => 'StackEnums';
use aliased 'CamHelpers::CamJob';

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

sub GetExistCvrl {
	my $self = shift;
	my $side = shift;    # top/bot
	my $info = shift;    # reference for storing info

	my $l = $side eq "top" ? "cvrlc" : "cvrls";

	my $exist = defined( first { $_->{"gROWname"} eq $l } @{ $self->{"boardBaseLayers"} } ) ? 1 : 0;

	if ($exist) {

		if ( defined $stifInfo ) {

			my $matInfo = HegMethods->GetPcbCoverlayMat( $self->{"jobId"} );

			$stifInfo->{"adhesiveText"}  = "";
			$stifInfo->{"adhesiveThick"} = $matInfo->{"tloustka_lepidlo"} * 1000;
			$stifInfo->{"cvrlText"}      = $matInfo->{"nazev_subjektu"};                                    # ? is not store
			$stifInfo->{"cvrlThick"}     = $matInfo->{"tloustka"} * 1000 - $stifInfo->{"adhesiveThick"};    # µm
			$stifInfo->{"selective"} = 0;    # Selective coverlay can bz onlz at RigidFLex pcb

		}
	}

	return $exist;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

