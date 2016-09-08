
#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::ExportUtility::JobWorkerClass;
use base("Managers::AsyncJobMngr::WorkerClass");

#3th party library
use strict;
use warnings;

#local library

use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';

use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::ItemResult::Enums' => 'ResultEnums';
use aliased 'Programs::Exporter::ExportUtility::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $self = $class->SUPER::new(@_);
	bless($self);

	return $self;
}

sub Init {
	my $self = shift;

	$self->{"pcbId"}       = shift;
	$self->{"taskId"}      = shift;
	$self->{"inCAM"}       = shift;
	$self->{"exportClass"} = shift;    # classes for export each group
	$self->{"data"}        = shift;    # export data

}

sub RunExport {
	my $self = shift;

	my %unitsData = $self->{"data"}->GetAllUnitData();
	my @keys      = $self->{"data"}->GetOrderedUnitKeys();

	# sort keys by nhash value "__UNITORDER__"
	#my @keys = ;

	foreach my $unitId (@keys) {

		#tell group export start

		my $exportData = $unitsData{$unitId};

		# Event when group export start
		$self->__GroupExportEvent( Enums->EventType_GROUP_START, $unitId );

		# Open job
		#if ( $self->__OpenJob() ) {

		# Process group
		$self->__ProcessGroup( $unitId, $exportData );

		#}

		#close job
		#$self->__CloseJob();

		# Event when group export end
		$self->__GroupExportEvent( Enums->EventType_GROUP_END, $unitId );

	}
}

sub __OpenJob {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};

	# START HANDLE EXCEPTION IN INCAM
	$inCAM->HandleException(1);

	CamHelper->OpenJob( $self->{"inCAM"}, $self->{"pcbId"} );

	# STOP HANDLE EXCEPTION IN INCAM
	$inCAM->HandleException(0);

	my $err = $inCAM->GetExceptionError();

	if ($err) {

		$self->__TaskResultEvent( ResultEnums->ItemResult_Fail, $err );
		return 0;
	}
	else {
		return 1;
	}
}

sub __CloseJob {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};

	# START HANDLE EXCEPTION IN INCAM
	$inCAM->HandleException(1);

	CamHelper->SaveAndCloseJob( $self->{"inCAM"}, $self->{"pcbId"} );

	# STOP HANDLE EXCEPTION IN INCAM
	$inCAM->HandleException(0);

	my $err = $inCAM->GetExceptionError();

	if ($err) {

		$self->__TaskResultEvent( ResultEnums->ItemResult_Fail, $err );
		return 0;
	}
	else {
		return 1;
	}
}

sub __ProcessGroup {
	my $self       = shift;
	my $unitId     = shift;
	my $exportData = shift;    # export data for specific group

#	use Time::HiRes qw (sleep);
#	for ( my $i = 0 ; $i < 50 ; $i++ ) {
#
#		my %data1 = ();
#		$data1{"unitId"}   = $unitId;
#		$data1{"itemId"}   = "Item id $i";
#		$data1{"result"}   = "failure";
#		$data1{"errors"}   = "rrrrrrrrrrr";
#		$data1{"warnings"} = "";
#
#		$self->_SendMessageEvt( Enums->EventType_ITEM_RESULT, \%data1 );
#
#		sleep(0.01);
#	}


	#use Connectors::HeliosConnector::HegMethods;

	#my $test = Connectors::HeliosConnector::HegMethods->GetPcbOrderNumber("D92987");

	#sleep(2);

	#$test = Connectors::HeliosConnector::HegMethods->GetPcbOrderNumber("D92987");

	#sleep(2);

#	my $num = rand(10);
#
#	use Time::HiRes qw (sleep);
#	for ( my $i = 0 ; $i < $num ; $i++ ) {
#
#		my %data1 = ();
#		$data1{"unitId"}   = $unitId;
#		$data1{"itemId"}   = "Item id $i";
#		$data1{"result"}   = "failure";
#		$data1{"errors"}   = "rrrrrrrrrrr";
#		$data1{"warnings"} = "";
#
#		$self->_SendMessageEvt( Enums->EventType_ITEM_RESULT, \%data1 );
#
#		sleep(0.6);
#	}
#
#	for ( my $i = 0 ; $i < 2 ; $i++ ) {
#
#		my %data1 = ();
#		$data1{"unitId"}   = $unitId;
#		$data1{"itemId"}   = "Item id $i";
#		$data1{"result"}   = "failure";
#		$data1{"errors"}   = "rrrrrrrrrrr";
#		$data1{"group"}    = "Layer";
#		$data1{"warnings"} = "";
#
#		#
#		$self->_SendMessageEvt( Enums->EventType_ITEM_RESULT, \%data1 );
#
#		#		sleep(1);
#
#	}
#
#	return 1;

	my $inCAM = $self->{"inCAM"};

	# Get right export class and init
	my $exportClass = $self->{"exportClass"}->{$unitId};
	$exportClass->Init( $inCAM, $self->{"pcbId"}, $exportData );

	# Set handlers
	$exportClass->{"onItemResult"}->Add( sub { $self->__ItemResultEvent( $exportClass, $unitId, @_ ) } );

	# START HANDLE EXCEPTION IN INCAM
	$inCAM->HandleException(1);

	# TODO Doplni try catch kdzy bude chzba v kodu +

	# Final export group
	$exportClass->Run();

	# STOP HANDLE EXCEPTION IN INCAM
	$inCAM->HandleException(0);

	my $err = $inCAM->GetExceptionError();

	if ($err) {

		$self->__GroupResultEvent( $unitId, ResultEnums->ItemResult_Fail, $err );
	}

}

sub __ItemResultEvent {
	my $self        = shift;
	my $exportClass = shift;
	my $unitId      = shift;
	my $itemResult  = shift;

	# Item result event

	my %data1 = ();
	$data1{"unitId"}   = $unitId;
	$data1{"itemId"}   = $itemResult->ItemId();
	$data1{"result"}   = $itemResult->Result();
	$data1{"errors"}   = $itemResult->GetErrorStr( Enums->ItemResult_DELIMITER );
	$data1{"warnings"} = $itemResult->GetWarningStr( Enums->ItemResult_DELIMITER );
	$data1{"group"}    = $itemResult->GetGroup();

	$self->_SendMessageEvt( Enums->EventType_ITEM_RESULT, \%data1 );

	# Progress value event

	my %data2 = ();
	$data2{"unitId"} = $unitId;
	$data2{"value"}  = $exportClass->GetProgressValue();

	print " ==========Job WorkerClass Progress, UnitId:" . $unitId . " - " . $exportClass->GetProgressValue() . "\n";

	$self->_SendProgressEvt( \%data2 );

}

sub __GroupResultEvent {
	my $self   = shift;
	my $unitId = shift;
	my $result = shift;
	my $error  = shift;

	# Item result event

	my %data1 = ();
	$data1{"unitId"} = $unitId;
	$data1{"result"} = $result;
	$data1{"errors"} = $error;

	$self->_SendMessageEvt( Enums->EventType_GROUP_RESULT, \%data1 );

}

sub __TaskResultEvent {
	my $self   = shift;
	my $result = shift;
	my $error  = shift;

	# Item result event

	my %data1 = ();
	$data1{"result"} = $result;
	$data1{"errors"} = $error;

	$self->_SendMessageEvt( Enums->EventType_TASK_RESULT, \%data1 );

}

#sub __ItemErrorEvent {
#	my $self = shift;
#	my $data = shift;
#
#	$self->__OnMessageEvt( ITEM_ERROR, $data );
#}

sub __GroupExportEvent {
	my $self   = shift;
	my $type   = shift;    #GROUP_EXPORT_<START/END>
	my $unitId = shift;

	my %data = ();
	$data{"unitId"} = $unitId;

	$self->_SendMessageEvt( $type, \%data );
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#my $app = Programs::Exporter::ExporterUtility->new();

	#$app->Test();

	#$app->MainLoop;

}

1;

