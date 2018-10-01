package Programs::Exporter::ExportUtility::Groups::NifExport::NifExportTmpPool;

#3th party library
use strict;
use warnings;
use Wx;
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

use aliased 'Programs::Exporter::ExportUtility::UnitEnums';

use aliased 'CamHelpers::CamAttributes';
use aliased 'Connectors::HeliosConnector::HegMethods';

use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'CamHelpers::CamAttributes';

use aliased 'Packages::Export::NifExport::NifMngr';
use aliased 'Programs::Exporter::ExportUtility::DataTransfer::UnitsDataContracts::NifData';
use aliased 'Packages::ItemResult::ItemResultMngr';

use aliased 'Packages::CAMJob::Dim::JobDim';

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

	my $poznamka    = shift;
	my $tenting     = shift;
	my $pressfit    = shift;
	my $tolHole 	= shift;
	my $maska01     = shift;
	my $datacode    = shift;
	my $ulLogo      = shift;
	my $jumpScore   = shift;
	my $wrongFormat = shift;

	my $stepName = "panel";

	# ========================================================
	# Prepare GROUP DATA =====================================
	# ========================================================

	my $taskData = NifData->new();

	if ( defined $poznamka ) {
		$taskData->SetNotes($poznamka);
	}
	if ( defined $tenting ) {
		$taskData->SetTenting($tenting);
	}
	if ( defined $pressfit ) {
		$taskData->SetPressfit($pressfit);
	}
	if(defined $tolHole){
		$taskData->SetToleranceHole($tolHole);
	}
	if ( defined $maska01 ) {
		$taskData->SetMaska01($maska01);
	}
	if ( defined $datacode ) {
		$taskData->SetDatacode($datacode);
	}
	if ( defined $ulLogo ) {
		$taskData->SetUlLogo($ulLogo);
	}
	if ( defined $jumpScore ) {
		$taskData->SetJumpScoring($jumpScore);
	}
	if ( defined $wrongFormat ) {
		$taskData->SetWrongFormat($wrongFormat);
	}

	#mask
	my %masks2 = HegMethods->GetSolderMaskColor($jobId);
	unless ( defined $masks2{"top"} ) {
		$masks2{"top"} = "";
	}
	unless ( defined $masks2{"bot"} ) {
		$masks2{"bot"} = "";
	}
	$taskData->SetC_mask_colour( $masks2{"top"} );
	$taskData->SetS_mask_colour( $masks2{"bot"} );

	#silk
	my %silk2 = HegMethods->GetSilkScreenColor($jobId);

	unless ( defined $silk2{"top"} ) {
		$silk2{"top"} = "";
	}
	unless ( defined $silk2{"bot"} ) {
		$silk2{"bot"} = "";
	}

	$taskData->SetC_silk_screen_colour( $silk2{"top"} );
	$taskData->SetS_silk_screen_colour( $silk2{"bot"} );

	#my %dim = $self->__GetDimension( $inCAM, $jobId );

	my %dim = JobDim->GetDimension( $inCAM, $jobId );

	$taskData->SetSingle_x( $dim{"single_x"} );
	$taskData->SetSingle_y( $dim{"single_y"} );
	$taskData->SetPanel_x( $dim{"panel_x"} );
	$taskData->SetPanel_y( $dim{"panel_y"} );
	$taskData->SetNasobnost_panelu( $dim{"nasobnost_panelu"} );

	my $name = CamAttributes->GetJobAttrByName( $inCAM, $jobId, "user_name" );
	$taskData->SetZpracoval($name);

	# ========================================================
	# Check GROUP DATA =====================================
	# ========================================================

	my $resultMngr = ItemResultMngr->new();

	#mask
	my %masks = CamLayer->ExistSolderMasks( $inCAM, $jobId );
	my $topMaskExist = CamHelper->LayerExists( $inCAM, $jobId, "mc" );
	my $botMaskExist = CamHelper->LayerExists( $inCAM, $jobId, "ms" );

	# Control mask existence
	if ( $masks{"top"} != $topMaskExist ) {

		my $item = $resultMngr->GetNewItem("Maska TOP");
		$resultMngr->AddItem($item);
		$item->AddError("Nesedí maska top v metrixu jobu a ve formuláøi Heliosu");

	}
	if ( $masks{"bot"} != $botMaskExist ) {

		my $item = $resultMngr->GetNewItem("Maska BOT");
		$resultMngr->AddItem($item);
		$item->AddError("Nesedí maska bot v metrixu jobu a ve formuláøi Heliosu");

	}

	#silk
	my %silk = CamLayer->ExistSilkScreens( $inCAM, $jobId );
	my $topSilkExist = CamHelper->LayerExists( $inCAM, $jobId, "pc" );
	my $botSilkExist = CamHelper->LayerExists( $inCAM, $jobId, "ps" );

	# Control silk existence
	if ( $silk{"top"} != $topSilkExist ) {

		my $item = $resultMngr->GetNewItem("Potisk TOP");
		$resultMngr->AddItem($item);
		$item->AddError("Nesedí potisk top v metrixu jobu a ve formuláøi Heliosu");

	}
	if ( $silk{"bot"} != $botSilkExist ) {

		my $item = $resultMngr->GetNewItem("Potisk BOT");
		$resultMngr->AddItem($item);
		$item->AddError("Nesedí potisk bot v metrixu jobu a ve formuláøi Heliosu");
	}

	# Control on customer panel if exist o+1_single and not exist customer_panel
	# multi
	if ( HegMethods->GetIdcustomer( $jobId)  ne '05626' ) {

		if ( CamHelper->StepExists( $inCAM, $jobId, "o+1_single" ) && CamAttributes->GetJobAttrByName( $inCAM, $jobId, "customer_panel" ) ne "yes" ) {

			my $item = $resultMngr->GetNewItem("Customer panel");
			$resultMngr->AddItem($item);
			$item->AddError("V jobu je step o+1_single, ale nejsou nastaveny atributy zakaznickeho panelu. Nastav je.");
		}
	}

	unless ( $resultMngr->Succes() ) {

		my $str = "";
		$str .= $resultMngr->GetErrorsStr();
		$str .= $resultMngr->GetWarningsStr();

		my $messMngr = MessageMngr->new( $self->{"jobId"} );

		my @mess1 = ( "Kontrola pred exportem", $str );
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess1 );

		return 0;
	}

	# ====================================================================
	# Export =============================================================
	# ====================================================================

	my %exportNifData = %{ $taskData->{"data"} };

	my $nifMngr = NifMngr->new( $inCAM, $jobId, \%exportNifData );

	$nifMngr->{"onItemResult"}->Add( sub { Test(@_) } );

	$nifMngr->Run();

	print "\n========================== E X P O R T: " . $self->{"id"} . " ===============================\n";
	print $resultMess;
	print "\n========================== E X P O R T: "
	  . $self->{"id"}
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

		my @mess1 = ( "== EXPORT FAILURE === GROUP:  " . $self->{"id"} . "\n" . $resultMess );
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess1 );
	}

	return $succes;

}

# TODO metodu pak smazat
#
#sub __GetDimension {
#
#	my $self  = shift;
#	my $inCAM = shift;
#	my $jobId = shift;
#
#	my %dim = ();
#	$dim{"single_x"} = "";
#	$dim{"single_y"} = "";
#
#	#get information about dimension, Ssteps: 0+1, mpanel
#
#	my %profilO1 = CamJob->GetProfileLimits( $inCAM, $jobId, "o+1" );
#
#	$dim{"single_x"} = abs( $profilO1{"xmax"} - $profilO1{"xmin"} );
#	$dim{"single_y"} = abs( $profilO1{"ymax"} - $profilO1{"ymin"} );
#
#	#format numbers
#	$dim{"single_x"} = sprintf( "%.1f", $dim{"single_x"} ) if ( $dim{"single_x"} );
#	$dim{"single_y"} = sprintf( "%.1f", $dim{"single_y"} ) if ( $dim{"single_y"} );
#
#	return %dim;
#}

1;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::Exporter::ExportUtility::Groups::NifExport::NifExportTmp';
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
	my %taskData = $nifPreGroup->__GetTaskData( \$prepareOk, $tenting, $pressfit, $maska01 );

	# Vytvoøení nifu, pokud vstupní parametry jsou OK
	if ($prepareOk) {

		my $export = NifExportTmp->new();
		$export->Run( $inCAM, $jobId, $stepName, \%taskData );

	}

}

1;

