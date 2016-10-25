
#-------------------------------------------------------------------------------------------#
# Description: Responsible for run export of all groups, which are passed to this class
# Object of this class is created in asynchronous thread
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::ExportUtility::JobWorkerClass;
use base("Managers::AsyncJobMngr::WorkerClass");

#3th party library
use strict;
use warnings;
use Try::Tiny;

#local library

use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::ItemResult::Enums' => 'ResultEnums';
use aliased 'Programs::Exporter::ExportUtility::Enums';
use aliased 'Programs::Exporter::DataTransfer::Enums' => "DataEnums";

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
	
	# Supress all toolkit exception/error windows
	$self->{"inCAM"} ->SupressToolkitException(1);

}

sub RunExport {
	my $self = shift;

	my %unitsData = $self->{"data"}->GetAllUnitData();
	my @keys      = $self->{"data"}->GetOrderedUnitKeys();
	my $mode = 		$self->{"data"}->GetExportMode();

	# sort keys by nhash value "__UNITORDER__"
	#my @keys = ;

	# Open job, only if asynchronous mode
	if($mode eq DataEnums->ExportMode_ASYNC ){
		$self->__OpenJob();
	}


	# Open job
	if ( CamJob->IsJobOpen($self->{"inCAM"}, $self->{"pcbId"})) {

		foreach my $unitId (@keys) {

			#tell group export start

			my $exportData = $unitsData{$unitId};

			# Event when group export start
			$self->__GroupExportEvent( Enums->EventType_GROUP_START, $unitId );

			# DON'T USE TRY/CATCH (TINY LIBRARY), IF SO, NORRIS WRITTER DOESN'T WORK
			# catch all unexpected exception in thread
			eval {
			
				# Process group
				$self->__ProcessGroup( $unitId, $exportData );
			};
			if ( my $e = $@ ) {

				my $errStr = "";

				# get string error from exception
				if ( $e->can("Error") ) {

					$errStr .= $e->Error();

				}
				else {

					$errStr .= $e;
				}

				$self->__GroupResultEvent( $unitId, ResultEnums->ItemResult_Fail, $errStr );
				 
			}

			# Event when group export end
			$self->__GroupExportEvent( Enums->EventType_GROUP_END, $unitId );
		}

		#close job
		
		if($mode eq DataEnums->ExportMode_ASYNC ){
			
			$self->__CloseJob();
		}
	}
}

sub __OpenJob {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};

	# START HANDLE EXCEPTION IN INCAM

	print STDERR "\n\n\n\n ================ handle exception ======================\n\n\n\n";
	$inCAM->HandleException(1);

	

	# TODO smayat

	CamHelper->OpenJob( $self->{"inCAM"}, $self->{"pcbId"} );
	CamJob->CheckOutJob( $self->{"inCAM"}, $self->{"pcbId"} );

	# STOP HANDLE EXCEPTION IN INCAM
	
	print STDERR "\n\n\n\n ================ handle exception END ======================\n\n\n\n";
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

	
	CamJob->CheckInJob( $self->{"inCAM"}, $self->{"pcbId"} );
	CamJob->CloseJob( $self->{"inCAM"}, $self->{"pcbId"} );

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
	#	for ( my $i = 0 ; $i < 5 ; $i++ ) {
	#
	#		my %data1 = ();
	#		$data1{"unitId"}   = $unitId;
	#		$data1{"itemId"}   = "Item id $i";
	#		$data1{"result"}   = "succes";
	#		$data1{"errors"}   = "";
	#		$data1{"warnings"} = "";
	#
	#		$self->_SendMessageEvt( Enums->EventType_ITEM_RESULT, \%data1 );
	#
	#		sleep(0.5);
	#	}
	#
	#	return 0;

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

	

	# Final export group
	$exportClass->Run();

	 

#	my $err = $inCAM->GetExceptionError();
#
#	if ($err) {
#
#		$self->__GroupResultEvent( $unitId, ResultEnums->ItemResult_Fail, $err );
#	}

}

# ====================================================================================
# Function, which sent messages to main thread about state of exporting
# ====================================================================================

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

