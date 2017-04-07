
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
use aliased 'Managers::AbstractQueue::ExportData::Enums' => "DataEnums";

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
	my $mode = 		$self->{"data"}->GetExportMode();

	# sort keys by nhash value "__UNITORDER__"
	#my @keys = ;

	# Open job, only if asynchronous mode
	if($mode eq DataEnums->ExportMode_ASYNC ){
		$self->_OpenJob();
	}


	# Open job
	if ( CamJob->IsJobOpen($self->{"inCAM"}, $self->{"pcbId"})) {

		foreach my $unitId (@keys) {

			#tell group export start

			my $exportData = $unitsData{$unitId};

			# Event when group export start
			$self->_GroupExportEvent( Enums->EventType_GROUP_START, $unitId );

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

				$self->_GroupResultEvent( $unitId, ResultEnums->ItemResult_Fail, $errStr );
				 
			}

			# Event when group export end
			$self->_GroupExportEvent( Enums->EventType_GROUP_END, $unitId );
		}

		#close job
		
		if($mode eq DataEnums->ExportMode_ASYNC ){
			
			$self->_CloseJob();
		}
	}
}
 
 

sub __ProcessGroup {
	my $self       = shift;
	my $unitId     = shift;
	my $exportData = shift;    # export data for specific group

	 
	my $inCAM = $self->{"inCAM"};

	# Get right export class and init
	my $exportClass = $self->{"exportClass"}->{$unitId};
	$exportClass->Init( $inCAM, $self->{"pcbId"}, $exportData );

	# Set handlers
	$exportClass->{"onItemResult"}->Add( sub { $self->_ItemResultEvent( $exportClass, $unitId, @_ ) } );

	

	# Final export group
	$exportClass->Run();

	 

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

	#my $app = Programs::Exporter::ExporterUtility->new();

	#$app->Test();

	#$app->MainLoop;

}

1;

