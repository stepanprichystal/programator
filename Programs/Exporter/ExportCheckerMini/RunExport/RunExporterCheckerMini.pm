
#-------------------------------------------------------------------------------------------#
# Description: This package run exporter checker
# 1) run single window app as single perl program
# 2) run server.pl from this script
# 3) Export checker will be communicate with this server, after export, this server is killed
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportCheckerMini::RunExport::RunExporterCheckerMini;

#3th party library
#use strict;
use warnings;

#local library

use aliased 'Packages::InCAMHelpers::AppLauncher::AppLauncher';
use aliased 'Packages::InCAMHelpers::AppLauncher::Enums';
use aliased 'Helpers::GeneralHelper';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Enums::EnumsIS';
use aliased 'Programs::Exporter::ExportUtility::UnitEnums';

sub new {
	my $self = shift;
	$self = {};
	bless($self);

	# 1) Check job
	$self->{"jobid"}   = shift;
	$self->{"unitId"}  = shift;
	$self->{"unitDim"} = shift;
	$self->{"serverExist"} = shift // 0;  
	$self->{"serverPort"} = shift;

	unless ( $self->__IsJobOpen( $self->{"jobid"} ) ) {

		return 0;
	}

	# 3) Launch app
	my $jobId   = $self->{"jobid"};
	my $unitId  = $self->{"unitId"};
	my $unitDim = $self->{"unitDim"};

	my $appName = 'Programs::Exporter::ExportCheckerMini::ExportCheckerMini';    # has to implement IAppLauncher

	my @appParams = ($jobId, $unitId, $unitDim, 0);

	my $launcher = AppLauncher->new( $appName, @appParams );

	$launcher->SetWaitingFrm(
							  "Exporter checker mini " . UnitEnums->GetTitle($unitId) . " - " . $jobId,
							  "Loading Exporter checker mini " . UnitEnums->GetTitle($unitId) . "...",
							  Enums->WaitFrm_CLOSEAUTO
	);

	if($self->{"serverExist"}){
		 
		$launcher->RunFromApp($self->{"jobid"}, $self->{"serverPort"});
		
	}else{
		$launcher->RunFromInCAM();
	}
	
}
 
 
sub __IsJobOpen {
	my $self  = shift;
	my $jobId = shift;

	unless ($jobId) {

		my $messMngr = MessageMngr->new("Exporter checker mini");
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
