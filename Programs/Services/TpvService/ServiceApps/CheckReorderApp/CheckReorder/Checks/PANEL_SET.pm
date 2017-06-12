#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorder::Checks::PANEL_SET;
use base('Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorder::Checks::CheckBase');

use Class::Interface;
&implements('Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorder::Checks::ICheck');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::NifFile::NifFile';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamAttributes';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless($self);

	return $self;
}

# if nif contain info about panel, and there is no mpanel
# It means it is customer set or customer
sub NeedChange {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $jobExist = shift;    # (in InCAM db)
	my $isPool = shift;

	unless ($jobExist) {
		return 1;
	}

	my $needChange = 0;

	my $nif = NifFile->new($jobId);

	my $multiplNif = $nif->GetValue("nasobnost_panelu");

	# Check only when nasobnost_panelu is set, thus potentional missing of job attributes
	if ( defined $multiplNif && $multiplNif ne "" && $multiplNif != 0 ) {

		my $mpanelExist = CamHelper->StepExists( $inCAM, $jobId, "mpanel" );

		my $custPnlExist = CamAttributes->GetJobAttrByName( $inCAM, $jobId, "customer_panel" );    # zakaznicky panel
		my $custSetExist = CamAttributes->GetJobAttrByName( $inCAM, $jobId, "customer_set" );      # zakaznicke sady

		# if mpanel doesn't exist AND customer panel is not set => error

		if ( !$mpanelExist && $custPnlExist ne "yes" && $custSetExist ne "yes" ) {

			$needChange = 1;
		}

		#check if all attributes are properly set

		# if real multiplicity of mpanel doesnt equal multiplicity in nif =>
		if ( $mpanelExist && $custSetExist ne "yes" ) {

			my $multiplReal = scalar( CamStepRepeat->GetRepeatStep( $inCAM, $jobId, "mpanel" ) );
			if ( $multiplNif != $multiplReal ) {

				$needChange = 1;
			}
		}
	}

	return $needChange;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorder::Checks::PANEL_SET' => "Change";
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f52457";

	my $check = Change->new();

	print "Need change: " . $check->NeedChange( $inCAM, $jobId, 1 );
}

1;

