
#-------------------------------------------------------------------------------------------#
# Description: 
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::RunPnlWizard::RunPnlWizard;

#3th party library
#use strict;
use warnings;

#local library

use aliased 'Packages::InCAMHelpers::AppLauncher::AppLauncher';
use aliased 'Packages::InCAMHelpers::AppLauncher::Enums';
use aliased 'Helpers::GeneralHelper';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';




sub new {
	my $self = shift;
	$self = {};
	bless($self);

	# 1) Check job
	$self->{"jobId"}       = shift;
	$self->{"pnlType"} = shift;
	$self->{"serverExist"} = shift // 0;
	$self->{"serverPort"}  = shift;
	$self->{"waitOnAppExist"} = shift //0;

	unless ( $self->__IsJobOpen( $self->{"jobId"} ) ) {

		return 0;
	}

	# 3) Launch app

	my $appName = 'Programs::Panelisation::PnlWizard::PnlWizard';    # has to implement IAppLauncher
 
	 
	my @params = ($self->{"jobId"}, $self->{"pnlType"} );
	my $launcher = AppLauncher->new( $appName, @params);
	
	$launcher->SetWaitingFrm( "Panel builder - ".$self->{"jobId"}, "Loading panel builder ...", Enums->WaitFrm_CLOSEAUTO );
 
	if ( $self->{"serverExist"} ) {

		$launcher->RunFromApp( $self->{"jobId"}, $self->{"serverPort"}, $self->{"waitOnAppExist"} );

	}
	else {
		$launcher->RunFromInCAM();
	}
}

sub __IsJobOpen {
	my $self  = shift;
	my $jobId = shift;

	unless ($jobId) {

		my $messMngr = MessageMngr->new("Panel builder wizard");
		my @mess1    = ("You have to run sript in open job.");
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess1 );

		return 0;

	}

	return 1;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#my $app = Programs::Exporter::AsyncJobMngr->new();

	#$app->Test();

	#$app->MainLoop;

}
1;
