
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

#local library

use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::ItemResult::Enums' => 'ResultEnums';
use aliased 'Managers::AbstractQueue::Enums';
use aliased 'Managers::AsyncJobMngr::Enums'           => 'EnumsJobMngr';
 

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	bless($self);

	return $self;
}
 

sub RunExport {
	my $self = shift;

	my %unitsData = $self->{"data"}->GetAllUnitData();
	my @keys      = $self->{"data"}->GetOrderedUnitKeys();
	my $mode = 		$self->{"data"}->GetTaskMode();

	# sort keys by nhash value "__UNITORDER__"
	#my @keys = ;

	# Open job, only if asynchronous mode
	if($mode eq EnumsJobMngr->TaskMode_ASYNC ){
		$self->_OpenJob();
	}


	# Open job
	if ( CamJob->IsJobOpen($self->{"inCAM"}, $self->{"pcbId"})) {

		foreach my $unitId (@keys) {

			#tell group export start

			my $taskData = $unitsData{$unitId};

			# Event when group export start
			$self->_GroupTaskEvent( Enums->EventType_GROUP_START, $unitId );

			# DON'T USE TRY/CATCH (TINY LIBRARY), IF SO, NORRIS WRITTER DOESN'T WORK
			# catch all unexpected exception in thread
			eval {
			
				# Process group
				$self->__ProcessGroup( $unitId, $taskData );
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

				$self->_GroupResultEvent( $unitId, ResultEnums->ItemResult_Fail, $errStr );
				 
			}

			# Event when group export end
			$self->_GroupTaskEvent( Enums->EventType_GROUP_END, $unitId );
		}

		#close job
		
		if($mode eq EnumsJobMngr->TaskMode_ASYNC ){
			
			$self->_CloseJob();
		}
	}
}
 
 

sub __ProcessGroup {
	my $self       = shift;
	my $unitId     = shift;
	my $taskData = shift;    # export data for specific group

	 
	my $inCAM = $self->{"inCAM"};

	# Get right export class and init
	my $taskClass = $self->{"taskClass"}->{$unitId};
	$taskClass->Init( $inCAM, $self->{"pcbId"}, $taskData );

	# Set handlers
	$taskClass->{"onItemResult"}->Add( sub { $self->_ItemResultEvent( $taskClass, $unitId, @_ ) } );

	

	# Final export group
	$taskClass->Run();

	 

#	my $err = $inCAM->GetExceptionError();
#
#	if ($err) {
#
#		$self->_GroupResultEvent( $unitId, ResultEnums->ItemResult_Fail, $err );
#	}

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

