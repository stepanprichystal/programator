
#-------------------------------------------------------------------------------------------#
# Description: TifFile - interface for signal layers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::Helper;

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

# return
sub GetMaskColor {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my $panelExist = CamHelper->StepExists( $inCAM, $jobId, "panel" );
	my $nifFile = NifFile->new($jobId);

	my %mask = ();

	if ( !$panelExist ) {

		# use nif norris
		%mask = HegMethods->GetSolderMaskColor($jobId);
	}
	else {

		# use nif file
		%mask = $nifFile->GetSolderMaskColor();
	}

	return %mask;
}

# return
sub GetSilkColor {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my $panelExist = CamHelper->StepExists( $inCAM, $jobId, "panel" );
	my $nifFile = NifFile->new($jobId);

	my %silk = ();

	if ( !$panelExist ) {

		# use nif norris
		%silk = HegMethods->GetSilkScreenColor($jobId);

	}
	else {

		# use nif file
		%silk = $nifFile->GetSilkScreenColor();
	}

	return %silk;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Pdf::ControlPdf::ControlPdf';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "f52456";

	my $control = ControlPdf->new( $inCAM, $jobId );

	$control->__ProcessTemplate();

}

1;

