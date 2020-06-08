
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for core files creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::MngrBase;
use base('Packages::ItemResult::ItemEventMngr');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Export::PreExport::FakeLayers';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class       = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $packageId   = shift;
	my $createFakeL = shift;                            # create fake layers
	my $self        = $class->SUPER::new($packageId);
	bless $self;

	$self->{"createFakeL"} = $createFakeL;
	$self->{"inCAM"}       = $inCAM;
	$self->{"jobId"}       = $jobId;

	# If panel doesn't exist, do note create any fake layers
	FakeLayers->CreateFakeLayers( $inCAM, $jobId ) if ( $createFakeL && CamHelper->StepExists( $inCAM, $jobId, "panel" ) );

	return $self;
}

sub _SaveJob {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# Before saving, remove fake layers if exist
	my $recreateFake = 0;
	if ( $self->{"createFakeL"} && CamHelper->StepExists( $inCAM, $jobId, "panel" ) ) {

		FakeLayers->RemoveFakeLayers( $inCAM, $jobId );
		$recreateFake = 1;
	}

	my $resultItemSave = $self->_GetNewItem("Saving job");

	$inCAM->HandleException(1);

	CamJob->SaveJob( $inCAM, $self->{"jobId"} );

	$resultItemSave->AddError( $inCAM->GetExceptionError() );
	$inCAM->HandleException(0);

	$self->_OnItemResult($resultItemSave);

	if ( $self->{"createFakeL"} && CamHelper->StepExists( $inCAM, $jobId, "panel" ) ) {
		FakeLayers->CreateFakeLayers( $inCAM, $jobId );
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

