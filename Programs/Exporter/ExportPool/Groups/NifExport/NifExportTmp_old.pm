package Programs::Exporter::ExportPool::Groups::NifExport::NifExportTmp;

#3th party library
use strict;
use warnings;
use Wx;
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';

use aliased 'CamHelpers::CamDrilling';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::JobHelper';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Enums::EnumsMachines';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Events::Event';

use aliased 'Programs::Exporter::ExportPool::UnitEnums';

use aliased 'Programs::Exporter::ExportPool::Groups::NifExport::NifExport';
use aliased 'Programs::Exporter::DataTransfer::UnitsDataContracts::NifData';
use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Model::NifGroupData';

use aliased 'CamHelpers::CamAttributes';
use aliased 'Connectors::HeliosConnector::HegMethods';

use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Presenter::NifUnit';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'CamHelpers::CamAttributes';

#-------------------------------------------------------------------------------------------#
#  NC export, all layers, all machines..
#-------------------------------------------------------------------------------------------#

my $resultMess = "";
my $succes     = 1;

sub new {

	my $self = shift;
	$self = {};
	bless $self;
	return $self;
}

sub Run {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my $poznamka  = shift;
	my $tenting   = shift;
	my $pressfit  = shift;
	my $maska01   = shift;
	my $datacode  = shift;
	my $ulLogo    = shift;
	my $jumpScore = shift;

	my $stepName = "panel";

	#GET INPUT NIF INFORMATION

	my $groupData = NifGroupData->new();

	$groupData->SetNotes($poznamka);
	$groupData->SetTenting($tenting);
	$groupData->SetPressfit($pressfit);
	$groupData->SetMaska01($maska01);
	$groupData->SetDatacode($datacode);
	$groupData->SetUlLogo($ulLogo);
	$groupData->SetJumpScoring($jumpScore);

	# TODO - vypocet rozmeru pak smazat

	# Dimension
	my %dim = $self->__GetDimension( $inCAM, $jobId );

	$groupData->SetSingle_x( $dim{"single_x"} );
	$groupData->SetSingle_y( $dim{"single_y"} );
	$groupData->SetPanel_x( $dim{"panel_x"} );
	$groupData->SetPanel_y( $dim{"panel_y"} );
	$groupData->SetNasobnost_panelu( $dim{"nasobnost_panelu"} );
	$groupData->SetNasobnost( $dim{"nasobnost"} );

	

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

	# SMAYAT konece

	# Check data
	use aliased 'Packages::ItemResult::ItemResultMngr';
	my $resultMngr = ItemResultMngr->new();

	my $unit = NifUnit->new( $jobId );
	$unit->InitDataMngr($inCAM, $groupData);
		
	$unit->CheckBeforeExport( $inCAM, \$resultMngr );

	unless ( $resultMngr->Succes() ) {

		my $str = "";
		$str .= $resultMngr->GetErrorsStr();
		$str .= $resultMngr->GetWarningsStr();

		my $messMngr = MessageMngr->new( $self->{"jobId"} );

		my @mess1 = ( "Kontrola pred exportem", $str );
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess1 );

		return 0;
	}

	my $exportData = $unit->GetExportData($inCAM);
	

	my $export = NifExport->new( UnitEnums->UnitId_NIF );
	$export->Init( $inCAM, $jobId, $exportData );
	$export->{"onItemResult"}->Add( sub { Test(@_) } );
	$export->Run();

	print "\n========================== E X P O R T: " . UnitEnums->UnitId_NIF . " ===============================\n";
	print $resultMess;
	print "\n========================== E X P O R T: "
	  . UnitEnums->UnitId_NIF
	  . " - F I N I S H: "
	  . ( $succes ? "SUCCES" : "FAILURE" )
	  . " ===============================\n";

	sub Test {
		my $itemResult = shift;

		if ( $itemResult->Result() eq "failure" ) {
			$succes = 0;
		}

		$resultMess .= " \n=============== Export task result: ==============\n";
		$resultMess .= "Task: " . $itemResult->ItemId() . "\n";
		$resultMess .= "Task result: " . $itemResult->Result() . "\n";
		$resultMess .= "Task errors: \n" . $itemResult->GetErrorStr() . "\n";
		$resultMess .= "Task warnings: \n" . $itemResult->GetWarningStr() . "\n";

	}

	unless ($succes) {
		my $messMngr = MessageMngr->new($jobId);

		my @mess1 = ( "== EXPORT FAILURE === GROUP:  " . UnitEnums->UnitId_NIF . "\n" . $resultMess );
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess1 );
	}

	return $succes;

}

# TODO metodu pak smazat

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

1;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::Exporter::ExportPool::Groups::NifExport::NifExportTmp';
	my $checkOk  = 1;
	my $jobId    = "f13610";
	my $stepName = "panel";
	my $inCAM    = InCAM->new();

	#GET INPUT NIF INFORMATION

	my $nifPreGroup = NifPreGroup->new( $inCAM, $jobId );

	my $tenting  = 1;
	my $pressfit = 0;
	my $maska01  = 0;

	my $prepareOk = 1;
	my %exportData = $nifPreGroup->__GetExportData( \$prepareOk, $tenting, $pressfit, $maska01 );

	# Vytvoøení nifu, pokud vstupní parametry jsou OK
	if ($prepareOk) {

		my $export = NifExportTmp->new();
		$export->Run( $inCAM, $jobId, $stepName, \%exportData );

	}

}

1;

