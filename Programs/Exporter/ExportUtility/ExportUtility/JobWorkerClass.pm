
#-------------------------------------------------------------------------------------------#
# Description: Responsible for run export of all groups, which are passed to this class
# Object of this class is created in asynchronous thread
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::ExportUtility::JobWorkerClass;
use base("Managers::AbstractQueue::AbstractQueue::JobWorkerClass");

#3th party library
use strict;
use warnings;
use Try::Tiny;
use Win32::GuiTest qw(SetForegroundWindow GetForegroundWindow );

#local library

use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::ItemResult::Enums' => 'ResultEnums';
use aliased 'Managers::AbstractQueue::Enums';
use aliased 'Managers::AsyncJobMngr::Enums' => 'EnumsJobMngr';
use aliased 'Packages::Exceptions::BaseException';
use aliased 'Programs::Exporter::ExportUtility::UnitEnums';


#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless($self);

	return $self;
}

sub RunTask {
	my $self = shift;

	$self->{"logger"}->debug( "Thread start, pcb id:" . ${ $self->{"pcbId"} } );

	eval {
		$self->__RunTask();

	};
	if ( my $e = $@ ) {

		my $baseE = BaseException->new( "Export utility thread (jobId: " . ${ $self->{"pcbId"} } . ") was unexpectedly exited", $e );

		$self->_TaskResultEvent( ResultEnums->ItemResult_Fail, $baseE->Error() );
	}

	$self->{"logger"}->debug( "Thread end, pcb id:" . ${ $self->{"pcbId"} } );

}

sub __RunTask {
	my $self = shift;

	my %workUnits = $self->_GetWorkUnits();
	my @keys      = $self->{"taskData"}->GetOrderedUnitKeys();
	my $mode      = $self->{"taskData"}->GetTaskMode();

	# sort keys by nhash value "__UNITORDER__"
	#my @keys = ;

	# Open job, only if asynchronous mode
	if ( $mode eq EnumsJobMngr->TaskMode_ASYNC ) {
		$self->_OpenJob("panel");
	}

	# Open job
	if ( CamJob->IsJobOpen( $self->{"inCAM"}, ${ $self->{"pcbId"} } ) ) {

		

		# 1) Init groups

		for ( my $i = 0 ; $i < scalar(@keys) ; $i++ ) {

			my $unitId   = $keys[$i];
			my $workUnit = $workUnits{$unitId};

			$self->__InitGroup($unitId);
		}

		# 2) Process groups

		for ( my $i = 0 ; $i < scalar(@keys) ; $i++ ) {

			$self->{"logger"}->debug( "Thread group processing: $i/" . scalar(@keys) . ", pcb id:" . ${ $self->{"pcbId"} } );

			my $unitId = $keys[$i];

			#tell group export start

			# Event when group export start
			$self->_GroupTaskEvent( Enums->EventType_GROUP_START, $unitId );

			# DON'T USE TRY/CATCH (TINY LIBRARY), IF SO, NORRIS WRITTER DOESN'T WORK
			# catch all unexpected exception in thread
			eval {

				# Process group
				$self->__ProcessGroup($unitId);
			};
			if ( my $e = $@ ) {

				my $baseE =
				  BaseException->new( "Processing of group: " . UnitEnums->GetTitle($unitId) . " was unexpectedly aborted", $e );

				$self->_GroupResultEvent( $unitId, ResultEnums->ItemResult_Fail, $baseE->Error() );

			}

			# Event when group export end
			$self->_GroupTaskEvent( Enums->EventType_GROUP_END, $unitId );

		}


		# 3) Close job

		if ( $mode eq EnumsJobMngr->TaskMode_ASYNC ) {

			#my $hwndCurWin = GetForegroundWindow(); # Incamsteal focus from another window when close job

			$self->_CloseJob();

			#SetForegroundWindow($hwndCurWin); # return focus to former window
		}

	}

}

sub __InitGroup {
	my $self   = shift;
	my $unitId = shift;

	my $inCAM = $self->{"inCAM"};

	# Get right export class and init
	my $workUnit = $self->{"workerUnits"}->{$unitId};

	$workUnit->Init( $inCAM, ${ $self->{"pcbId"} } );

	# Set handlers

	# catch item with results
	$workUnit->{"onItemResult"}->Add( sub { $self->_ItemResultEvent( $workUnit, $unitId, @_ ) } );

}

sub __ProcessGroup {
	my $self   = shift;
	my $unitId = shift;

	my %workUnits = $self->_GetWorkUnits();

	# Get right export class and init
	my $workUnit = $workUnits{$unitId};

	# Final export group
	$workUnit->Run();
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#my $app = Programs::Exporter::ExportUtility->new();

	#$app->Test();

	#$app->MainLoop;

}

1;

