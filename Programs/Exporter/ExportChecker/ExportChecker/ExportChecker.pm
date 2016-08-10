
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
use aliased 'Programs::Exporter::ExportChecker::Enums';
use aliased 'Connectors::HeliosConnector::HegMethods';

use aliased 'Programs::Exporter::ExportChecker::ExportChecker::StorageMngr';
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::ExportPopup';

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

	my $serverPort = shift;
	my $serverPid  = shift;

	$self->{"inCAM"} = undef;

	# Client maage conenction between this app and server
	$self->{"client"} = Client->new();

	# Main application form
	$self->{"form"} = ExportCheckerForm->new( -1, $self->{"jobId"}, $self->{"inCAM"} );

	# Class whin manage popup form for checking
	$self->{"exportPopup"} = ExportPopup->new($self->{"jobId"});

	# Keep structure of groups on tabs
	$self->{"groupTables"} = GroupTables->new();

	# Keep all references of used groups/units in form
	$self->{"units"} = Units->new();

	# Manage group date (store/load group data from/to disc)
	$self->{"storageMngr"} =  StorageMngr->new( $self->{"jobId"}, $self->{"units"} );

	$self->__Connect( $serverPort, $serverPid );
	$self->__Init();
	$self->__Run();

	return $self;
}

sub __Init {
	my $self = shift;

	# 1) Initialization of whole export app

	#set handlers for main app form
	$self->__SetHandlers();

	# Keep structure of groups
	$self->__DefineTableGroups();

	# Save all references of groups
	my @cells = $self->{"groupTables"}->GetAllUnits();
	$self->{"units"}->Init(\@cells);   
 
 
	# Build phyisic table with groups, which has completely set GUI
	#my $groupBuilder = $self->{"form"}->GetGroupBuilder();
	#$groupBuilder->Build( $self->{"groupTables"}, $self->{"inCAM"} );
	$self->{"form"}->BuildGroupTableForm( $self->{"groupTables"} );

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

}

sub __Run {
	my $self = shift;
	$self->{"form"}->{"mainFrm"}->Show(1);

	#$self->{"units"}->RefreshGUI($self->{"inCAM"});

	$self->{"form"}->MainLoop();

}

# ================================================================================
# FORM HANDLERS
# ================================================================================
sub __ExportSyncFormHandler {
	my $self   = shift;
	my $client = $self->{"client"};

	print STDERR "Export sync\n";

	#if ( $client->ClientConnected() ) {
	#
	#		print STDERR "Close\n";
	#		$self->{"inCAM"}->CloseServer();
	#
	#	}\

	#use Win32::OLE;
	my $typeOfPcb = HegMethods->GetTypeOfPcb( $self->{"jobId"} );
	my $typeOfPcb = HegMethods->GetTypeOfPcb( $self->{"jobId"} );
	$self->__CheckBeforeExport();
}

sub __ExportASyncFormHandler {
	my $self = shift;

	#$self->{"form"}->{"pnlChecker"}->Raise();

	$self->{"popup"}->ShowPopup();

}

sub __OnCloseFormHandler {
	my $self = shift;

	$self->__CleanUpAndExitForm();

}

 
sub __CheckBeforeExport {
	my $self = shift;

	#disable from during checking
	$self->{"form"}->DisableForm(1);

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

 	#init and run checking form
	$self->{"exportPopup"}->Init($self->{"units"}, $self->{"form"});
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

	print "\n F O R M destroyed\n"

}

sub __UncheckAllHandler {
	my $self = shift;

}

sub __LoadLastHandler {
	my $self = shift;

	$self->{"units"}->InitDataMngr( $self->{"inCAM"} , $self->{"storageMngr"});

}

sub __LoadDefaultHandler {
	my $self = shift;
	
	 
 
}

# ================================================================================
# EXPORT POPUP HANDLERS
# ================================================================================
 sub __OnClosePopupHandler {
	my $self = shift;

	$self->{"form"}->DisableForm(0);

	$self->__CleanUpAndExitForm();

}

sub __OnResultPopupHandler {
	my $self       = shift;
	my $resultType = shift;

	if (    $resultType eq Enums->PopupResult_EXPORTFORCE
		 || $resultType eq Enums->PopupResult_SUCCES )
	{

		#start exporting

	}
	elsif ( $resultType eq Enums->PopupResult_CHANGE ) {

		#do nothing

	}

	$self->{"form"}->DisableForm(0);

}

# ================================================================================
# PRIVATE METHODS
# ================================================================================

sub __Connect {
	my $self = shift;

	my $port = shift;
	my $pid  = shift;

	print STDERR "\n\n EXPORTER CHECKER $port   $pid \n\n ";

	# Manage conenctio between client and server
	my $client = $self->{"client"};

	# set running server on port
	$client->SetServer( $port, $pid );

	# try to connect to server
	my $result = $client->Connect();

	print STDERR "RESULT is $result";

	# if test ok, connect inCAM library to server
	$self->{"inCAM"} = InCAM->new( "port" => $port );

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
	
	
	
	$self->{"exportPopup"}->{"onResultEvt"}->Add( sub    { $self->__OnResultPopupHandler(@_) } );
	$self->{"exportPopup"}->{'onClose'}->Add( sub        { $self->__OnClosePopupHandler(@_) } );

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

