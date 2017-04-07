
#-------------------------------------------------------------------------------------------#
# Description: Represent one task, which are in the queue. Responsible for
# - Initialize units
# - Pass message to specific units
# - Responsible for updating ExportStauts
# - Responsible for sending pcb to Export
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportPool::Task::Task;
use base("Managers::AbstractQueue::Task::Task");

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Exporter::ExportPool::UnitEnums';

use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::Exporter::ExportPool::Groups::NifExport::NifUnit';
use aliased 'Programs::Exporter::ExportPool::Groups::NCExport::NCUnit';

use aliased 'Connectors::HeliosConnector::HegMethods';

use aliased 'Programs::Exporter::ExportPool::Groups::NifExport::NifUnit';
use aliased 'Programs::Exporter::ExportPool::Groups::NCExport::NCUnit';
use aliased 'Programs::Exporter::ExportPool::Groups::ETExport::ETUnit';
use aliased 'Programs::Exporter::ExportPool::Groups::AOIExport::AOIUnit';
use aliased 'Programs::Exporter::ExportPool::Groups::PlotExport::PlotUnit';
use aliased 'Programs::Exporter::ExportPool::Groups::PreExport::PreUnit';
use aliased 'Programs::Exporter::ExportPool::Groups::ScoExport::ScoUnit';
use aliased 'Programs::Exporter::ExportPool::Groups::GerExport::GerUnit';
use aliased 'Programs::Exporter::ExportPool::Groups::PdfExport::PdfUnit';
use aliased 'Programs::Exporter::ExportPool::Groups::OutExport::OutUnit';
use aliased 'Managers::AbstractQueue::ExportResultMngr';

#-------------------------------------------------------------------------------------------#
#  Package methods, requested by IUnit interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
 
	my $self = $class->SUPER::new(@_);
	bless $self;

	# Managers, contains information about results of
	# whole task, groups, single items, etc
 	$self->{"ToExportResultMngr"} = ExportResultMngr->new();
 
	# Tell if job can be send to export,
	# based on Export results and StatusFile
	$self->{"canToExport"} = undef;

	$self->{"SendToExport"} = 0;    # Tell if task was send to export
	
	$self->__InitUnits();

 
	return $self;
}

# ===================================================================
# Public method
# ===================================================================
 

sub ToExportResultMngr {
	my $self = shift;

	return $self->{"ToExportResultMngr"};
}
 

# ===================================================================
# Public method - GET or SET state of this task
# ===================================================================

  

# Return result, which tell if pcb can be send to export
sub ResultToExport {
	my $self = shift;

	my $res = $self->{"ExportResultMngr"}->Succes();

	if ($res) {
		$res = EnumsGeneral->ResultType_OK;
	}
	else {
		$res = EnumsGeneral->ResultType_FAIL;
	}
	return $res;
}
 

sub GetExportErrorsCnt {
	my $self = shift;

	return $self->{"ExportResultMngr"}->GetErrorsCnt();
}

sub GetExportWarningsCnt {
	my $self = shift;

	return $self->{"ExportResultMngr"}->GetWarningsCnt();
}

# ===================================================================
# Method regardings "to Export" issue
# ===================================================================

# Tell if job was send to export
sub GetJobSendToExport {
	my $self = shift;

	return $self->{"SendToExport"};
}

# Tell if job was not aborted by user during export
# If no, job can/hasn't be send to export
sub GetJobCanToExport {
	my $self = shift;

	return $self->{"canToExport"};
}

# Tell if user checked in export, job should be sent
# to product automatically
sub GetJobShouldToExport {
	my $self = shift;

	return $self->{"exportData"}->GetToExport();
}

# Test if job can be send to export
# Set results of this action to manager
sub SetToExportResult {
	my $self = shift;

	$self->{"canToExport"} = 1;

	my $ToExportMngr = $self->{"ExportResultMngr"};

	$ToExportMngr->Clear();

	# check if export is succes
	if ( $self->Result() eq EnumsGeneral->ResultType_FAIL ) {

		my $errorStr = "Can't sent \"to Export\",  ";

		if ( $self->GetJobAborted() ) {

			$errorStr .= "because export was aborted by user.";
			$self->{"canToExport"} = 0;

		}
		else {

			$errorStr .= "because export was not succes.";
		}

		my $item = $ToExportMngr->GetNewItem( "send to export", EnumsGeneral->ResultType_FAIL );

		$item->AddError($errorStr);
		$ToExportMngr->AddItem($item);
	}

	my @notExportUnits = ();
	if ( !$self->{"exportStatus"}->IsExportOk( \@notExportUnits ) ) {

		my @notExportUnits = map { UnitEnums->GetTitle($_) } @notExportUnits;
		my $str = join( ", ", @notExportUnits );

		my $errorStr = "Can't sent \"to Export\", because some groups haven't been exported succesfully. \n";
		$errorStr .= "Groups that need to be exported: <b> $str </b>\n";

		$self->{"canToExport"} = 0;

		my $item = $ToExportMngr->GetNewItem( "Export status", EnumsGeneral->ResultType_FAIL );

		$item->AddError($errorStr);
		$ToExportMngr->AddItem($item);
	}

}

sub SendToExport {
	my $self = shift;

	# set state HOTOVO-zadat

	eval {
		my $orderRef = HegMethods->GetPcbOrderNumber( $self->{"jobId"} );
		my $orderNum = $self->{"jobId"} . "-" . $orderRef;
		
		my $succ     = HegMethods->UpdatePcbOrderState( $orderNum, "HOTOVO-zadat");
		
	 
		$self->{"exportStatus"}->DeleteStatusFile();
		$self->{"SendToExport"} = 1;
	};

	if ( my $e = $@ ) {

		 # set status hotovo-yadat fail
		 my $ToExportMngr = $self->{"ExportResultMngr"};
		 my $item = $ToExportMngr->GetNewItem( "Set state HOTOVO-zadat", EnumsGeneral->ResultType_FAIL );

		$item->AddError("Set state HOTOVO-zadat failed, try it again. Detail: $e\n");
		$ToExportMngr->AddItem($item);

	}

}

 
#-------------------------------------------------------------------------------------------#
#  Private method
#-------------------------------------------------------------------------------------------#
 
 sub __InitUnits {
	my $self = shift;
 
	my @keys = $self->{"exportData"}->GetOrderedUnitKeys(1);
	my @allUnits = ();

	foreach my $key (@keys) {

		my $unit = $self->__GetUnitClass($key);
		push( @allUnits, $unit );
	}

	$self->{"units"}->SetUnits(\@allUnits);

}
# Return initialized "unit" object by unitId
sub __GetUnitClass {
	my $self   = shift;
	my $unitId = shift;

	my $unit;
	my $jobId = $self->{"jobId"};
	
	

	if ( $unitId eq UnitEnums->UnitId_NIF ) {

		$unit = NifUnit->new($unitId, $jobId);

	}
	elsif ( $unitId eq UnitEnums->UnitId_NC ) {

		$unit = NCUnit->new($unitId, $jobId);

	}
	elsif ( $unitId eq UnitEnums->UnitId_AOI ) {

		$unit = AOIUnit->new($unitId, $jobId);

	}
	elsif ( $unitId eq UnitEnums->UnitId_ET ) {

		$unit = ETUnit->new($unitId, $jobId);

	}
	elsif ( $unitId eq UnitEnums->UnitId_PLOT ) {

		$unit = PlotUnit->new($unitId, $jobId);

	}
	elsif ( $unitId eq UnitEnums->UnitId_PRE ) {

		$unit = PreUnit->new($unitId, $jobId);

	}
	elsif ( $unitId eq UnitEnums->UnitId_SCO ) {

		$unit = ScoUnit->new($unitId, $jobId);

	}
	elsif ( $unitId eq UnitEnums->UnitId_GER ) {

		$unit = GerUnit->new($unitId, $jobId);

	}
	elsif ( $unitId eq UnitEnums->UnitId_PDF ) {

		$unit = PdfUnit->new($unitId, $jobId);

	}
	elsif ( $unitId eq UnitEnums->UnitId_OUT ) {

		$unit = OutUnit->new($unitId, $jobId);

	}
	
 

	return $unit;
}
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

