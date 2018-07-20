#-------------------------------------------------------------------------------------------#
# Description: Helper methods with dimensions and multiplicity of cam job
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Dim::JobDim;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamAttributes';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

# Return hash with values for HEG columns:
# nasobnost_panelu
# nasobnost
# single_x
# single_y
# panel_x
# panel_y
#
# If job is POOL child, doesn't return value: nasobnost
sub GetDimension {

	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my %dim = ();
	$dim{"single_x"}         = "";
	$dim{"single_y"}         = "";
	$dim{"panel_x"}          = "";
	$dim{"panel_y"}          = "";
	$dim{"nasobnost_panelu"} = "";
	$dim{"nasobnost"}        = "";

	#get information about dimension, Ssteps: 0+1, mpanel

	my %profilO1 = CamJob->GetProfileLimits( $inCAM, $jobId, "o+1" );
	my %profilM = ();

	my $mExist = CamHelper->StepExists( $inCAM, $jobId, "mpanel" );

	if ($mExist) {
		%profilM = CamJob->GetProfileLimits( $inCAM, $jobId, "mpanel" );
	}

	#get information about customer panel if exist

	my $custPnlExist = CamAttributes->GetJobAttrByName( $inCAM, $jobId, "customer_panel" );    # zakaznicky panel
	my $custSetExist = CamAttributes->GetJobAttrByName( $inCAM, $jobId, "customer_set" );      # zakaznicke sady

	#get inforamtion about multiplicity steps
	my $mpanelMulipl;
	if ($mExist) {
		$mpanelMulipl = $self->__GetMultiplOfStep( $inCAM, $jobId, "mpanel" );
	}

	my $panelMultipl;

	my $pnlExist = CamHelper->StepExists( $inCAM, $jobId, "panel" );

	# if job is pool child, panel doesn't exist
	if ($pnlExist) {

		my $isPool = HegMethods->GetPcbIsPool($jobId);

		if ($isPool) {
			$panelMultipl = $self->__GetMultiplOfStep( $inCAM, $jobId, "panel", "o+1" );
		}
		else {
			$panelMultipl = $self->__GetMultiplOfStep( $inCAM, $jobId, "panel" );
		}
	}

	#set dimension by "customer panel"
	if ( $custPnlExist eq "yes" ) {

		my $custSingleX    = CamAttributes->GetJobAttrByName( $inCAM, $jobId, "cust_pnl_singlex" );
		my $custSingleY    = CamAttributes->GetJobAttrByName( $inCAM, $jobId, "cust_pnl_singley" );
		my $custPnlMultipl = CamAttributes->GetJobAttrByName( $inCAM, $jobId, "cust_pnl_multipl" );

		$dim{"single_x"}         = $custSingleX;
		$dim{"single_y"}         = $custSingleY;
		$dim{"panel_x"}          = abs( $profilO1{"xmax"} - $profilO1{"xmin"} );
		$dim{"panel_y"}          = abs( $profilO1{"ymax"} - $profilO1{"ymin"} );
		$dim{"nasobnost_panelu"} = $custPnlMultipl;
		$dim{"nasobnost"}        = $custPnlMultipl * $panelMultipl if ($pnlExist);    # only if step panel exist

	}

	# set dimension by "customer set"
	elsif ( $custSetExist eq "yes" ) {

		my $custSetMultipl = CamAttributes->GetJobAttrByName( $inCAM, $jobId, "cust_set_multipl" );
		my $mpanelX        = abs( $profilM{"xmax"} - $profilM{"xmin"} );
		my $mpanelY        = abs( $profilM{"ymax"} - $profilM{"ymin"} );

		# compute dimension based on number of count in mpanel
		if ( $custSetMultipl == 1 ) {
			$dim{"single_x"} = $mpanelX;
			$dim{"single_y"} = $mpanelY;
		}
		else {

			# create fake dimension of one set

			$dim{"single_x"} = $mpanelX;
			$dim{"single_y"} = $mpanelY / $custSetMultipl;
		}

		$dim{"panel_x"}          = $mpanelX;
		$dim{"panel_y"}          = $mpanelY;
		$dim{"nasobnost_panelu"} = $custSetMultipl;
		$dim{"nasobnost"}        = $custSetMultipl * $panelMultipl if ($pnlExist);    # only if step panel exist
	}
	else {

		$dim{"single_x"} = abs( $profilO1{"xmax"} - $profilO1{"xmin"} );
		$dim{"single_y"} = abs( $profilO1{"ymax"} - $profilO1{"ymin"} );

		my $panelXtmp     = "";
		my $panelYtmp     = "";
		my $mMultiplTmp   = "";
		my $pnlMultiplTmp = $panelMultipl;

		if ($mExist) {
			$panelXtmp     = abs( $profilM{"xmax"} - $profilM{"xmin"} );
			$panelYtmp     = abs( $profilM{"ymax"} - $profilM{"ymin"} );
			$mMultiplTmp   = $mpanelMulipl;
			$pnlMultiplTmp = $pnlMultiplTmp * $mpanelMulipl if ($pnlExist);    # only if step panel exist
		}

		$dim{"panel_x"}          = $panelXtmp;
		$dim{"panel_y"}          = $panelYtmp;
		$dim{"nasobnost_panelu"} = $mMultiplTmp;
		$dim{"nasobnost"}        = $pnlMultiplTmp if ($pnlExist);              # only if step panel exist

	}

	#format numbers
	$dim{"single_x"} = sprintf( "%.1f", $dim{"single_x"} ) if ( $dim{"single_x"} );
	$dim{"single_y"} = sprintf( "%.1f", $dim{"single_y"} ) if ( $dim{"single_y"} );
	$dim{"panel_x"}  = sprintf( "%.1f", $dim{"panel_x"} )  if ( $dim{"panel_x"} );
	$dim{"panel_y"}  = sprintf( "%.1f", $dim{"panel_y"} )  if ( $dim{"panel_y"} );

	if ($pnlExist) {
		
		my %profilP = CamJob->GetProfileLimits( $inCAM, $jobId, "panel" );

		$dim{"vyrobni_panel_x"} = abs( $profilP{"xmax"} - $profilP{"xmin"} );
		$dim{"vyrobni_panel_y"} = abs( $profilP{"ymax"} - $profilP{"ymin"} );
	}

	return %dim;
}

sub __GetMultiplOfStep {

	my $self         = shift;
	my $inCAM        = shift;
	my $jobId        = shift;
	my $stepName     = shift;
	my $onlyStepName = shift;    # tell which "child" step is only counting

	my $stepExist = CamHelper->StepExists( $inCAM, $jobId, $stepName );

	unless ($stepExist) {
		return 0;
	}

	$inCAM->INFO( units => 'mm', entity_type => 'step', entity_path => "$jobId/$stepName", data_type => 'NUM_REPEATS' );
	my $stepCnt = $inCAM->{doinfo}{gNUM_REPEATS};

	$inCAM->INFO( units => 'mm', entity_type => 'step', entity_path => "$jobId/$stepName", data_type => 'SR' );
	my @stepNames = @{ $inCAM->{doinfo}{gSRstep} };
	my @stepNx    = @{ $inCAM->{doinfo}{gSRnx} };
	my @stepNy    = @{ $inCAM->{doinfo}{gSRny} };

	foreach my $stepName (@stepNames) {
		if ( $stepName =~ /coupon_?\d*/ ) {
			$stepCnt -= 1;
		}
	}

	# if defined, count only steps with name <$onlyStepName>
	if ($onlyStepName) {
		$stepCnt = 0;

		for ( my $i = 0 ; $i < scalar(@stepNames) ; $i++ ) {

			my $name = $stepNames[$i];
			if ( $name =~ /\Q$onlyStepName/i ) {
				my $x = $stepNx[$i];
				my $y = $stepNy[$i];
				$stepCnt += ( $x * $y );
			}
		}

	}

	return $stepCnt;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAMJob::Dim::JobDim';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f52456";

	my %dim = JobDim->GetDimension( $inCAM, $jobId );

	print "eee";
}

1;

