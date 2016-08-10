
#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for creation:
# - Export data, (from prepared group data), which will consume exporter utility. Handler: OnExportGroupData
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::NifExport::Model::NifExportData;

#3th party library
use strict;
use warnings;
use File::Copy;

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamAttributes';

use aliased 'CamHelpers::CamDrilling';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::JobHelper';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Enums::EnumsMachines';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Events::Event';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Managers::MessageMngr::MessageMngr';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	return $self;
}

# Export data, (from prepared group data), which will consume exporter utility
# are prepared in this method
sub OnExportGroupData {
	my $self     = shift;
	my $dataMngr = shift;    #instance of GroupDataMngr

	my %groupData = $dataMngr->GetGroupData();

	my $inCAM = $dataMngr->{"inCAM"};
	my $jobId = $dataMngr->{"jobId"};

	my $stepName = "panel";

	my %exportData = ();

	$exportData{"zpracoval"} = $ENV{"LOGNAME"};

	#mask
	my %masks2 = HegMethods->GetSolderMaskColor($jobId);

	$exportData{"c_mask_colour"} = $masks2{"top"};
	$exportData{"s_mask_colour"} = $masks2{"bot"};

	#silk
	my %silk2 = HegMethods->GetSilkScreenColor($jobId);

	$exportData{"c_silk_screen_colour"} = $silk2{"top"};
	$exportData{"s_silk_screen_colour"} = $silk2{"bot"};

	#dimension
	my %dim = $self->__GetDimension( $inCAM, $jobId );

	$exportData{"single_x"}         = $dim{"single_x"};
	$exportData{"single_y"}         = $dim{"single_y"};
	$exportData{"panel_x"}          = $dim{"panel_x"};
	$exportData{"panel_y"}          = $dim{"panel_y"};
	$exportData{"nasobnost_panelu"} = $dim{"nasobnost_panelu"};
	$exportData{"nasobnost"}        = $dim{"nasobnost"};

	#other
	$exportData{"tenting"}        = $groupData{"tenting"};
	$exportData{"poznamka"}       = $groupData{"notes"};

	$exportData{"rel(22305,L)"}   = $groupData{"maska01"};
	$exportData{"datacode"}       = $groupData{"datacode"};
	$exportData{"ul_logo"} = $groupData{"ul_logo"};
	$exportData{"merit_presfitt"} = $groupData{"pressfit"};
	$exportData{"prerusovana_drazka"} = $groupData{"prerusovana_drazka"};
	return %exportData;

}

sub __GetDimension {

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

	#get information about customer panel if wxist

	my $custPnlExist = CamAttributes->GetJobAttrByName( $inCAM, $jobId, "customer_panel" );
	my $custSingleX;
	my $custSingleY;
	my $custPnlMultipl;

	if ( $custPnlExist eq "yes" ) {
		$custSingleX    = CamAttributes->GetJobAttrByName( $inCAM, $jobId, "cust_pnl_singlex" );
		$custSingleY    = CamAttributes->GetJobAttrByName( $inCAM, $jobId, "cust_pnl_singley" );
		$custPnlMultipl = CamAttributes->GetJobAttrByName( $inCAM, $jobId, "cust_pnl_multipl" );
	}

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

		$dim{"single_x"}         = $custSingleX;
		$dim{"single_y"}         = $custSingleY;
		$dim{"panel_x"}          = abs( $profilO1{"xmax"} - $profilO1{"xmin"} );
		$dim{"panel_y"}          = abs( $profilO1{"ymax"} - $profilO1{"ymin"} );
		$dim{"nasobnost_panelu"} = $custPnlMultipl;
		$dim{"nasobnost"}        = $custPnlMultipl * $panelMultipl;

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

