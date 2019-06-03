
#-------------------------------------------------------------------------------------------#
# Description: Helper for FillTemplate class
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::PcbControlPdf::Helper;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::NifFile::NifFile';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamHelper';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

# Decide of get mask color ftom NIF/Helios
sub GetMaskColor {
	my $self       = shift;
	my $inCAM      = shift;
	my $jobId      = shift;
	my $secondMask = shift;

	my $panelExist = CamHelper->StepExists( $inCAM, $jobId, "panel" );
	my $nifFile = NifFile->new($jobId);

	my %mask = ();

	if ( !$panelExist ) {

		# use nif norris
		%mask = $secondMask ? HegMethods->GetSolderMaskColor2($jobId) : HegMethods->GetSolderMaskColor($jobId);
	}
	else {

		# use nif file
		%mask = $nifFile->GetSolderMaskColor();

		# check if exist second mask in IS
		if ($secondMask) {

			%mask = HegMethods->GetSolderMaskColor2($jobId);
		}
	}

	return %mask;
}

# Decide of get silk color ftom NIF/Helios
sub GetSilkColor {
	my $self       = shift;
	my $inCAM      = shift;
	my $jobId      = shift;
	my $secondSilk = shift;

	my $panelExist = CamHelper->StepExists( $inCAM, $jobId, "panel" );
	my $nifFile = NifFile->new($jobId);

	my %silk = ();

	if ( !$panelExist ) {

		# use nif norris
		%silk = $secondSilk ? HegMethods->GetSilkScreenColor2($jobId) : HegMethods->GetSilkScreenColor($jobId);

	}
	else {

		# use nif file
		%silk = $secondSilk ? $nifFile->GetSilkScreenColor2() : $nifFile->GetSilkScreenColor();
	}

	return %silk;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

