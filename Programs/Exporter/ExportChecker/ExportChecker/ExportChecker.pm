
#-------------------------------------------------------------------------------------------#
# Description: Base class for BIF builders. Nif Builder is responsible for
# creation nif file depend on pcb type
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::ExportChecker::ExportChecker;

#3th party library
use strict;
use warnings;
use threads;
use threads::shared;
use Win32::Process;
use Wx;

#use strict;

#local library

use aliased 'Programs::Exporter::ExportChecker::ExportChecker::Forms::ExportCheckerForm';
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::Forms::ExportPopupForm';
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::Unit::Units';

use aliased 'Programs::Exporter::ExportChecker::ExportChecker::GroupBuilder::StandardBuilder';
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::GroupBuilder::TemplateBuilder';
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::GroupBuilder::V0Builder';

use aliased 'Programs::Exporter::ExportChecker::ExportChecker::GroupTable::GroupTables';
use aliased 'Programs::Exporter::ExportChecker::Server::Client';
use aliased 'Packages::InCAM::InCAM';

use aliased 'Connectors::HeliosConnector::HegMethods';

use aliased 'Programs::Exporter::ExportChecker::ExportChecker::StorageMngr';
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::ExportPopup';
use aliased 'Programs::Exporter::ExportUtility::RunExport::RunExportUtility';

use aliased 'Programs::Exporter::ExportUtility::DataTransfer::DataTransfer';
use aliased 'Programs::Exporter::ExportChecker::Enums';
use aliased 'Managers::AsyncJobMngr::Enums'                          => 'EnumsJobMngr';
use aliased 'Programs::Exporter::ExportUtility::DataTransfer::Enums' => 'EnumsTransfer';

use aliased 'Helpers::GeneralHelper';
use aliased 'Widgets::Forms::LoadingForm';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'Enums::EnumsPaths';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
#my $CHECKER_START_EVT : shared;
#my $CHECKER_END_EVT : shared;
#my $CHECKER_FINISH_EVT : shared;
#my $THREAD_FORCEEXIT_EVT : shared;

# ================================================================================
# PUBLIC METHOD
# ================================================================================

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"jobId"} = shift;

	$self->{"serverPort"}    = shift;
	$self->{"serverPid"}     = shift;
	$self->{"loadingFrmPid"} = shift;

	$self->{"inCAM"} = undef;

	# Client maage conenction between this app and server
	$self->{"client"} = Client->new();

	# Main application form
	$self->{"form"} = ExportCheckerForm->new( -1, $self->{"jobId"}, $self->{"inCAM"} );

	# Class whin manage popup form for checking
	$self->{"exportPopup"} = ExportPopup->new( $self->{"jobId"} );

	# Keep structure of groups on tabs
	$self->{"groupTables"} = GroupTables->new();

	# Keep all references of used groups/units in form
	$self->{"units"} = Units->new();

	# Manage group date (store/load group data from/to disc)
	$self->{"storageMngr"} = StorageMngr->new( $self->{"jobId"}, $self->{"units"} );

	$self->__Connect();
	$self->__Init();
	$self->__Run();

	return $self;
}

sub __Init {
	my $self = shift;

	# 1) Initialization of whole export app

	# Keep structure of groups
	$self->__DefineTableGroups();

	# Save all references of groups
	my @cells = $self->{"groupTables"}->GetAllUnits();
	$self->{"units"}->Init( $self->{"inCAM"}, $self->{"jobId"}, \@cells );

	# Build phyisic table with groups, which has completely set GUI
	#my $groupBuilder = $self->{"form"}->GetGroupBuilder();
	#$groupBuilder->Build( $self->{"groupTables"}, $self->{"inCAM"} );
	$self->{"form"}->BuildGroupTableForm( $self->{"groupTables"}, $self->{"inCAM"} );

	# 2) Initialization of each single group

	#posloupnost volani metod
	#1) new()
	#2) InitForm()
	#3) BuildGUI()
	#4) InitDataMngr()
	#5) RefreshGUI()
	#==> export
	#6) CheckBeforeExport()
	#7) GetGroupData()

	$self->{"units"}->InitDataMngr( $self->{"inCAM"} );

	$self->{"units"}->RefreshGUI();

	$self->__RefreshForm();

	#set handlers for main app form
	$self->__SetHandlers();

}

sub __Run {
	my $self = shift;
	$self->{"form"}->{"mainFrm"}->Show(1);

	# When all succesinit, close waiting form
	if ( $self->{"loadingFrmPid"} ) {
		Win32::Process::KillProcess( $self->{"loadingFrmPid"}, 0 );
	}

	#Helper->ShowAbstractQueueWindow(0,"Loading Exporter Checker");

	$self->{"form"}->MainLoop();

}

# ================================================================================
# FORM HANDLERS
# ================================================================================
sub __ExportSyncFormHandler {
	my $self   = shift;
	my $client = $self->{"client"};

	#if ( $client->ClientConnected() ) {
	#
	#		print STDERR "Close\n";
	#		$self->{"inCAM"}->CloseServer();
	#
	#	}\

	#use Win32::OLE;
	#my $typeOfPcb = HegMethods->GetTypeOfPcb( $self->{"jobId"} );

	#my $typeOfPcb = HegMethods->GetTypeOfPcb( $self->{"jobId"} );
	$self->__CheckBeforeExport( EnumsJobMngr->TaskMode_SYNC );
}

sub __ExportASyncFormHandler {
	my $self     = shift;
	my $onServer = shift;

	my $client = $self->{"client"};

	#if ( $client->ClientConnected() ) {
	#
	#		print STDERR "Close\n";
	#		$self->{"inCAM"}->CloseServer();
	#
	#	}\

	#use Win32::OLE;
	#my $typeOfPcb = HegMethods->GetTypeOfPcb( $self->{"jobId"} );

	#my $typeOfPcb = HegMethods->GetTypeOfPcb( $self->{"jobId"} );
	$self->__CheckBeforeExport( EnumsJobMngr->TaskMode_ASYNC, $onServer );

}

sub __OnCloseFormHandler {
	my $self = shift;

	$self->__CleanUpAndExitForm();

}

sub __CheckBeforeExport {
	my $self     = shift;
	my $mode     = shift;
	my $onServer = shift // 0; # default is not export on server

	#disable from during checking
	$self->{"disableForm"} = 1;
	$self->__RefreshForm();

	my $client = $self->{"client"};
	my $inCAM  = $self->{"inCAM"};

	#get all gorup data and save them to disc
	$self->{"storageMngr"}->SaveGroupData();

	#test if client is connected
	#if so, disconnect, because child porcess has to connect to server itself
	if ( $client->IsConnected() ) {
		$inCAM->ClientFinish();

		#$client->SetConnected(0);
	}
	my $serverPort = $client->ServerPort();

	#Win32::OLE->Uninitialize();

	#init and run checking form
	$self->{"exportPopup"}->Init( $mode, $onServer, $self->{"units"}, $self->{"form"} );
	$self->{"exportPopup"}->CheckBeforeExport($serverPort);

}

sub __CleanUpAndExitForm {
	my ($self) = @_;

	my $client     = $self->{"client"};
	my $serverPort = $client->ServerPort();

	print STDERR "On close\n";

	#reconnect again for exit server

	#if ( $client->IsConnected() ) {

	$self->{"inCAM"}->ClientFinish();

	$self->{"inCAM"} = InCAM->new( "port" => $serverPort );

	if ( $self->{"inCAM"}->ServerReady() ) {
		$self->{"inCAM"}->CloseServer();
	}

	#}

	$self->{"form"}->{"mainFrm"}->Destroy();

}

sub __UncheckAllHandler {
	my $self = shift;

	$self->{"units"}->SetGroupState( Enums->GroupState_ACTIVEOFF );

	# Refresh loaded data in group form
	$self->{"units"}->RefreshGUI();

	# Refresh form
	$self->__RefreshForm();

}

sub __LoadLastHandler {
	my $self = shift;

	# Load/get saved group data
	$self->{"units"}->InitDataMngr( $self->{"inCAM"}, $self->{"storageMngr"} );

	# Refresh loaded data in group form
	$self->{"units"}->RefreshGUI();

	# Refresh form
	$self->__RefreshForm();

}

sub __LoadDefaultHandler {
	my $self = shift;

	$self->{"units"}->InitDataMngr( $self->{"inCAM"} );

	# Refresh loaded data in group form
	$self->{"units"}->RefreshGUI();

	# Refresh form
	$self->__RefreshForm();
}

sub __OnGroupChangeState {
	my $self = shift;
	my $unit = shift;

	print STDERR "Unif " . $unit->{"unitId"} . " change state: " . $unit->GetGroupState() . "\n";
	print STDERR "All units state: " . $self->{"units"}->GetGroupState() . "\n";

	$self->__RefreshForm();

}

# ================================================================================
# EXPORT POPUP HANDLERS
# ================================================================================
sub __OnClosePopupHandler {
	my $self = shift;

	# After close popup window is necessery Re-connect to income server
	# Because checking was processed in child thread and was connected
	# to this income server

	$self->__Connect();

	$self->{"disableForm"} = 0;
	$self->__RefreshForm();

	#$self->__CleanUpAndExitForm();

}

sub __OnResultPopupHandler {
	my $self       = shift;
	my $resultType = shift;
	my $exportMode = shift;
	my $onServer   = shift;

	# After close popup window is necessery Re-connect to income server
	# Because checking was processed in child thread and was connected
	# to this income server

	$self->__Connect();

	my $active    = 1;
	my $toProduce = $self->{"form"}->GetToProduce($active);

	if (    $resultType eq Enums->PopupResult_EXPORTFORCE
		 || $resultType eq Enums->PopupResult_SUCCES )
	{

		my $pathExportFile = EnumsPaths->Client_EXPORTFILES . $self->{"jobId"};

		if ( $exportMode eq EnumsJobMngr->TaskMode_ASYNC && $onServer ) {
			$pathExportFile = EnumsPaths->Jobs_EXPORTFILESPCB . $self->{"jobId"};
		}

		my $dataTransfer = DataTransfer->new( $self->{"jobId"}, EnumsTransfer->Mode_WRITE, $self->{"units"}, undef, $pathExportFile );

		my $inCAM  = $self->{"inCAM"};
		my $client = $self->{"client"};

		my @orders = map { $_->{"reference_subjektu"} } HegMethods->GetOrdersByState( $self->{"jobId"}, 2 );    # Orders on Predvzrobni priprava

		if ( $exportMode eq EnumsJobMngr->TaskMode_ASYNC ) {

			# Save and close job
			$self->{"form"}->{"mainFrm"}->Hide();

			CamJob->SaveJob( $inCAM, $self->{"jobId"} );
			CamJob->CheckInJob( $inCAM, $self->{"jobId"} );
			CamJob->CloseJob( $inCAM, $self->{"jobId"} );

			if ( $client->IsConnected() ) {
				$inCAM->CloseServer();
			}

			# Save exported data
			$dataTransfer->SaveData( $exportMode, $toProduce, undef, undef, \@orders );

		}
		elsif ( $exportMode eq EnumsJobMngr->TaskMode_SYNC ) {

			# Generate random port number

			#my $portNumber = "200". int(rand(9));    #random number
			#my $portNumber = "2001";    #random number
			#my $serverPID  = $$;        # PID

			# Save and hide form
			$self->{"form"}->{"mainFrm"}->Hide();
			CamJob->SaveJob( $inCAM, $self->{"jobId"} );

			my $formPos = $self->{"form"}->{"mainFrm"}->GetPosition();

			# Save exported data
			$dataTransfer->SaveData( $exportMode, $toProduce, $self->{"serverPort"}, $formPos, \@orders );

			#test if client is connected
			#if so, disconnect, because exportUtility connect to this server (launched in InCAM toolkit)
			if ( $client->IsConnected() ) {
				$inCAM->ClientFinish();

				#$client->SetConnected(0);
			}

			# Start server in this script

			#my $serverPath = GeneralHelper->Root() . "\\Managers\\AsyncJobMngr\\Server\\ServerExporter.pl";

			#$ARGV[0] = $self->{"serverPort"};    # port number of server running in Toolkit, pass as argument
			#require $serverPath;

		}

		
		
		if($onServer){
			
			# Show summary message 
			$self->{"form"}->{"messageMngr"}
			
		}else{
			
			# Launch export utility if hasn't launched before
			my $utility = RunExportUtility->new(0);
		}

		# Exit export window
		$self->{"form"}->{"mainFrm"}->Destroy();

		return 1;

	}
	elsif ( $resultType eq Enums->PopupResult_CHANGE ) {

		#do nothing

	}

	$self->{"disableForm"} = 0;
	$self->__RefreshForm();
}

# ================================================================================
# PRIVATE METHODS
# ================================================================================

sub __RefreshForm {
	my $self = shift;

	# Disable/enable whole form
	$self->{"form"}->DisableForm( $self->{"disableForm"} );

	# Disable/enable button Load last button
	$self->{"form"}->SetLoadLastBtn( $self->{"storageMngr"}->ExistGroupData() );

	# Set export buttons
	my $groupsState = $self->{"units"}->GetGroupState();

	if ( $groupsState eq Enums->GroupState_ACTIVEOFF || $groupsState eq Enums->GroupState_DISABLE ) {
		$self->{"form"}->DisableExportBtn(1);
	}
	else {
		$self->{"form"}->DisableExportBtn(0);
	}

}

sub __Connect {
	my $self = shift;

	my $port = $self->{"serverPort"};
	my $pid  = $self->{"serverPid"};

	# Manage conenctio between client and server
	my $client = $self->{"client"};

	# set running server on port
	$client->SetServer( $port, $pid );

	# try to connect to server
	my $result = $client->Connect();

	# if test ok, connect inCAM library to server
	if ( $self->{"inCAM"} ) {

		$self->{"inCAM"}->Reconnect();
	}
	else {

		$self->{"inCAM"} = InCAM->new( "port" => $port );
	}

	return $result;
}

sub __SetHandlers {
	my $self = shift;

	$self->{"form"}->{"onExportSync"}->Add( sub  { $self->__ExportSyncFormHandler(@_) } );
	$self->{"form"}->{"onExportASync"}->Add( sub { $self->__ExportASyncFormHandler(@_) } );
	$self->{"form"}->{"onClose"}->Add( sub       { $self->__OnCloseFormHandler(@_) } );
	$self->{"form"}->{"onUncheckAll"}->Add( sub  { $self->__UncheckAllHandler(@_) } );
	$self->{"form"}->{"onLoadLast"}->Add( sub    { $self->__LoadLastHandler(@_) } );
	$self->{"form"}->{"onLoadDefault"}->Add( sub { $self->__LoadDefaultHandler(@_) } );

	$self->{"exportPopup"}->{"onResultEvt"}->Add( sub { $self->__OnResultPopupHandler(@_) } );
	$self->{"exportPopup"}->{'onClose'}->Add( sub     { $self->__OnClosePopupHandler(@_) } );

	$self->{"units"}->SetGroupChangeHandler( sub { $self->__OnGroupChangeState(@_) } );

}

sub __DefineTableGroups {
	my $self = shift;

	my $groupBuilder = undef;
	$self->{"groupTables"} = GroupTables->new();

	my $typeOfPcb = HegMethods->GetTypeOfPcb( $self->{"jobId"} );

	if ( $typeOfPcb eq 'Neplatovany' ) {

		$groupBuilder = V0Builder->new();
	}
	elsif ( $typeOfPcb eq 'Sablona' ) {

		$groupBuilder = TemplateBuilder->new();

	}
	else {

		$groupBuilder = StandardBuilder->new();
	}

	$groupBuilder->Build( $self->{"jobId"}, $self->{"groupTables"} );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::Exporter::ExportChecker::ExportChecker::ExportChecker';

	my $form = ExportChecker->new();

}

1;
 