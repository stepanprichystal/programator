
#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for prepare:
# - default "dataset" (groupData) for displaying them in GUI. Handler: OnPrepareGroupData
# - decide, if group will be active in GUI. Handler: OnGetGroupState
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::NifExport::Model::NifPrepareData;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Model::NifGroupData';
use aliased 'Programs::Exporter::ExportChecker::Enums';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamAttributes';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Enums::EnumsGeneral';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	return $self;    # Return the reference to the hash.
}

# This method decide, if group will be "active" or "passive"
# If active, decide if group will be switched ON/OFF
# Return enum: Enums->GroupState_xxx
sub OnGetGroupState {
	my $self     = shift;
	my $dataMngr = shift;    #instance of GroupDataMngr

	#we want nif group allow always, so return ACTIVE ON
	return Enums->GroupState_ACTIVEON;

}

# Default "group data" are prepared in this method
sub OnPrepareGroupData {
	my $self     = shift;
	my $dataMngr = shift;    #instance of GroupDataMngr

	my $groupData = NifGroupData->new();

	my $inCAM = $dataMngr->{"inCAM"};
	my $jobId = $dataMngr->{"jobId"};

	my $defaultInfo = $dataMngr->GetDefaultInfo();

	# Controls when step panel not exist
	$groupData->SetMaska01(0);
	
	# Preapre pressfit
	my $defPressfit = 0;

	if ( $defaultInfo->GetPressfitExist() || $defaultInfo->GetMeritPressfitIS()) {

		$defPressfit = 1;
	}
 
	$groupData->SetPressfit($defPressfit);
	$groupData->SetNotes("");

	# prepare default selected quick notes
	my @quickNotes = ();
	$groupData->SetQuickNotes( \@quickNotes );

	# prepare datacode
	$groupData->SetDatacode( HegMethods->GetDatacodeLayer($jobId) );
	$groupData->SetUlLogo( HegMethods->GetUlLogoLayer($jobId) );

	# Mask color

	#mask
	my %masks2 = HegMethods->GetSolderMaskColor($jobId);
	unless ( defined $masks2{"top"} ) {
		$masks2{"top"} = "";
	}
	unless ( defined $masks2{"bot"} ) {
		$masks2{"bot"} = "";
	}
	$groupData->SetC_mask_colour( $masks2{"top"} );
	$groupData->SetS_mask_colour( $masks2{"bot"} );

	#silk
	my %silk2 = HegMethods->GetSilkScreenColor($jobId);

	unless ( defined $silk2{"top"} ) {
		$silk2{"top"} = "";
	}
	unless ( defined $silk2{"bot"} ) {
		$silk2{"bot"} = "";
	}

	$groupData->SetC_silk_screen_colour( $silk2{"top"} );
	$groupData->SetS_silk_screen_colour( $silk2{"bot"} );

	my $tenting = $self->__IsTenting( $inCAM, $jobId, $defaultInfo );

	$groupData->SetTenting($tenting);

	my $scoreChecker = $defaultInfo->GetScoreChecker();
	my $jump         = 0;
	if ($scoreChecker) {
		$jump = $scoreChecker->CustomerJumpScoring();
	}

	$groupData->SetJumpScoring($jump);

	# Dimension
	my %dim = $self->__GetDimension( $inCAM, $jobId, $defaultInfo );

	$groupData->SetSingle_x( $dim{"single_x"} );
	$groupData->SetSingle_y( $dim{"single_y"} );
	$groupData->SetPanel_x( $dim{"panel_x"} );
	$groupData->SetPanel_y( $dim{"panel_y"} );
	$groupData->SetNasobnost_panelu( $dim{"nasobnost_panelu"} );
	$groupData->SetNasobnost( $dim{"nasobnost"} );

	return $groupData;
}

sub __IsTenting {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $defaultInfo = shift;

	unless ($defaultInfo) {
		return 0;
	}

	my $tenting = 0;

	# if layer cnt > 1
	if ( $defaultInfo->GetLayerCnt() >= 1 ) {

		if ( CamHelper->LayerExists( $inCAM, $jobId, "c" ) ) {

			my $etch = $defaultInfo->GetEtchType("c");

			if ( $etch eq EnumsGeneral->Etching_TENTING ) {

				$tenting = 1;
			}
		}
	}

	return $tenting;
}

sub __GetDimension {

	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $defaultInfo = shift;

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

	my $custPnlExist = $defaultInfo->GetJobAttrByName("customer_panel" );    # zakaznicky panel
	my $custSetExist = $defaultInfo->GetJobAttrByName("customer_set" );      # zakaznicke sady

	#get inforamtion about multiplicity steps
	my $mpanelMulipl;
	if ($mExist) {
		$mpanelMulipl = $self->__GetMultiplOfStep( $inCAM, $jobId, "mpanel" );
	}

	my $panelMultipl;

	my $isPool = HegMethods->GetPcbIsPool($jobId);

	if ($isPool) {
		$panelMultipl = $self->__GetMultiplOfStep( $inCAM, $jobId, "panel", "o+1" );
	}
	else {
		$panelMultipl = $self->__GetMultiplOfStep( $inCAM, $jobId, "panel" );
	}

	#set dimension by "customer panel"
	if ( $custPnlExist eq "yes" ) {

		my $custSingleX    = $defaultInfo->GetJobAttrByName("cust_pnl_singlex" );
		my $custSingleY    = $defaultInfo->GetJobAttrByName("cust_pnl_singley" );
		my $custPnlMultipl = $defaultInfo->GetJobAttrByName("cust_pnl_multipl" );

		$dim{"single_x"}         = $custSingleX;
		$dim{"single_y"}         = $custSingleY;
		$dim{"panel_x"}          = abs( $profilO1{"xmax"} - $profilO1{"xmin"} );
		$dim{"panel_y"}          = abs( $profilO1{"ymax"} - $profilO1{"ymin"} );
		$dim{"nasobnost_panelu"} = $custPnlMultipl;
		$dim{"nasobnost"}        = $custPnlMultipl * $panelMultipl;

	}

	# set dimension by "customer set"
	elsif ( $custSetExist eq "yes" ) {

		my $custSetMultipl = $defaultInfo->GetJobAttrByName( "cust_set_multipl" );
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
		$dim{"nasobnost"}        = $custSetMultipl * $panelMultipl;
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
			$pnlMultiplTmp = $pnlMultiplTmp * $mpanelMulipl;
		}

		$dim{"panel_x"}          = $panelXtmp;
		$dim{"panel_y"}          = $panelYtmp;
		$dim{"nasobnost_panelu"} = $mMultiplTmp;
		$dim{"nasobnost"}        = $pnlMultiplTmp;

	}

	#format numbers
	$dim{"single_x"} = sprintf( "%.1f", $dim{"single_x"} ) if ( $dim{"single_x"} );
	$dim{"single_y"} = sprintf( "%.1f", $dim{"single_y"} ) if ( $dim{"single_y"} );
	$dim{"panel_x"}  = sprintf( "%.1f", $dim{"panel_x"} )  if ( $dim{"panel_x"} );
	$dim{"panel_y"}  = sprintf( "%.1f", $dim{"panel_y"} )  if ( $dim{"panel_y"} );

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
		if ( $stepName =~ /coupon_\d/ ) {
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

	#	use aliased 'Packages::Export::NCExport::NCExportGroup';
	#
	#	my $jobId    = "F13608";
	#	my $stepName = "panel";
	#
	#	my $inCAM = InCAM->new();
	#
	#	my $ncgroup = NCExportGroup->new( $inCAM, $jobId );
	#
	#	$ncgroup->Run();

	#print $test;

}

1;

