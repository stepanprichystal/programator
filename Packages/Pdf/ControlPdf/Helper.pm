
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

	# use nif file
	if ( !$panelExist || ( $panelExist && !$nifFile->Exist() ) ) {

		%mask = $nifFile->GetSolderMaskColor();
	}
	else {

		# use nif norris
		%mask = HegMethods->GetSolderMaskColor($jobId);
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

	# use nif file
	if ( !$panelExist || ( $panelExist && !$nifFile->Exist() ) ) {

		%silk = $nifFile->GetSilkScreenColor();
	}
	else {

		# use nif norris
		%silk = HegMethods->GetSilkScreenColor($jobId);
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

