
#-------------------------------------------------------------------------------------------#
# Description: Represent one task, which are in the queue. Responsible for
# - Initialize units
# - Pass message to specific units
# - Responsible for updating ExportStauts
# - Responsible for sending pcb to produce
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::Task::Task;
use base("Managers::AbstractQueue::Task::Task");

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Exporter::ExportUtility::UnitEnums';

use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::Exporter::ExportUtility::Groups::NifExport::NifUnit';
use aliased 'Programs::Exporter::ExportUtility::Groups::NCExport::NCUnit';

use aliased 'Connectors::HeliosConnector::HegMethods';

use aliased 'Programs::Exporter::ExportUtility::Groups::NifExport::NifUnit';
use aliased 'Programs::Exporter::ExportUtility::Groups::NCExport::NCUnit';
use aliased 'Programs::Exporter::ExportUtility::Groups::ETExport::ETUnit';
use aliased 'Programs::Exporter::ExportUtility::Groups::AOIExport::AOIUnit';
use aliased 'Programs::Exporter::ExportUtility::Groups::PlotExport::PlotUnit';
use aliased 'Programs::Exporter::ExportUtility::Groups::PreExport::PreUnit';
use aliased 'Programs::Exporter::ExportUtility::Groups::ScoExport::ScoUnit';
use aliased 'Programs::Exporter::ExportUtility::Groups::GerExport::GerUnit';
use aliased 'Programs::Exporter::ExportUtility::Groups::PdfExport::PdfUnit';
use aliased 'Programs::Exporter::ExportUtility::Groups::OutExport::OutUnit';
use aliased 'Managers::AbstractQueue::TaskResultMngr';

#-------------------------------------------------------------------------------------------#
#  Package methods, requested by IUnit interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
 
	my $self = $class->SUPER::new(@_);
	bless $self;

	# Managers, contains information about results of
	# whole task, groups, single items, etc
 	$self->{"produceResultMngr"} = TaskResultMngr->new();
 
	# Tell if job can be send to produce,
	# based on Export results and StatusFile
	$self->{"canToProduce"} = undef;

	$self->{"sentToProduce"} = 0;    # Tell if task was sent to produce
	
	$self->__InitUnits();

 
	return $self;
}

# ===================================================================
# Public method
# ===================================================================
 

sub ProduceResultMngr {
	my $self = shift;

	return $self->{"produceResultMngr"};
}
 

# ===================================================================
# Public method - GET or SET state of this task
# ===================================================================

  

# Return result, which tell if pcb can be send to produce
sub ResultToProduce {
	my $self = shift;

	my $res = $self->{"produceResultMngr"}->Succes();

	if ($res) {
		$res = EnumsGeneral->ResultType_OK;
	}
	else {
		$res = EnumsGeneral->ResultType_FAIL;
	}
	return $res;
}
 

sub GetProduceErrorsCnt {
	my $self = shift;

	return $self->{"produceResultMngr"}->GetErrorsCnt();
}

sub GetProduceWarningsCnt {
	my $self = shift;

	return $self->{"produceResultMngr"}->GetWarningsCnt();
}

# ===================================================================
# Method regardings "to produce" issue
# ===================================================================

# Tell if job was sent to produce
sub GetJobSentToProduce {
	my $self = shift;

	return $self->{"sentToProduce"};
}

# Tell if job was not aborted by user during export
# If no, job can/hasn't be sent to produce
sub GetJobCanToProduce {
	my $self = shift;

	return $self->{"canToProduce"};
}

# Tell if user checked in export, job should be sent
# to product automatically
sub GetJobShouldToProduce {
	my $self = shift;

	return $self->{"taskData"}->GetToProduce();
}

# Test if job can be send to produce
# Set results of this action to manager
sub SetToProduceResult {
	my $self = shift;

	$self->{"canToProduce"} = 1;

	my $toProduceMngr = $self->{"produceResultMngr"};

	$toProduceMngr->Clear();

	# check if export is succes
	if ( $self->Result() eq EnumsGeneral->ResultType_FAIL ) {

		my $errorStr = "Can't sent \"to produce\",  ";

		if ( $self->GetJobAborted() ) {

			$errorStr .= "because export was aborted by user.";
			$self->{"canToProduce"} = 0;

		}
		else {

			$errorStr .= "because export was not succes.";
		}

		my $item = $toProduceMngr->GetNewItem( "Sent to produce", EnumsGeneral->ResultType_FAIL );

		$item->AddError($errorStr);
		$toProduceMngr->AddItem($item);
	}

	my @notExportUnits = ();
	if ( !$self->{"taskStatus"}->IsTaskOk( \@notExportUnits ) ) {

		my @notExportUnits = map { UnitEnums->GetTitle($_) } @notExportUnits;
		my $str = join( ", ", @notExportUnits );

		my $errorStr = "Can't sent \"to produce\", because some groups haven't been exported succesfully. \n";
		$errorStr .= "Groups that need to be exported: <b> $str </b>\n";

		$self->{"canToProduce"} = 0;

		my $item = $toProduceMngr->GetNewItem( "Export status", EnumsGeneral->ResultType_FAIL );

		$item->AddError($errorStr);
		$toProduceMngr->AddItem($item);
	}

}

sub SentToProduce {
	my $self = shift;

	# set state HOTOVO-zadat

	eval {
		my $orderRef = HegMethods->GetPcbOrderNumber( $self->{"jobId"} );
		my $orderNum = $self->{"jobId"} . "-" . $orderRef;
		
		my $succ     = HegMethods->UpdatePcbOrderState( $orderNum, "HOTOVO-zadat");
		
	 
		$self->{"taskStatus"}->DeleteStatusFile();
		$self->{"sentToProduce"} = 1;
	};

	if ( my $e = $@ ) {

		 # set status hotovo-yadat fail
		 my $toProduceMngr = $self->{"produceResultMngr"};
		 my $item = $toProduceMngr->GetNewItem( "Set state HOTOVO-zadat", EnumsGeneral->ResultType_FAIL );

		$item->AddError("Set state HOTOVO-zadat failed, try it again. Detail: $e\n");
		$toProduceMngr->AddItem($item);

	}

}

 
#-------------------------------------------------------------------------------------------#
#  Private method
#-------------------------------------------------------------------------------------------#
 
 sub __InitUnits {
	my $self = shift;
 
	my @keys = $self->{"taskData"}->GetOrderedUnitKeys(1);
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
	
	my $title = UnitEnums->GetTitle($unitId);

	if ( $unitId eq UnitEnums->UnitId_NIF ) {

		$unit = NifUnit->new($unitId, $jobId, $title);

	}
	elsif ( $unitId eq UnitEnums->UnitId_NC ) {

		$unit = NCUnit->new($unitId, $jobId, $title);

	}
	elsif ( $unitId eq UnitEnums->UnitId_AOI ) {

		$unit = AOIUnit->new($unitId, $jobId, $title);

	}
	elsif ( $unitId eq UnitEnums->UnitId_ET ) {

		$unit = ETUnit->new($unitId, $jobId, $title);

	}
	elsif ( $unitId eq UnitEnums->UnitId_PLOT ) {

		$unit = PlotUnit->new($unitId, $jobId, $title);

	}
	elsif ( $unitId eq UnitEnums->UnitId_PRE ) {

		$unit = PreUnit->new($unitId, $jobId, $title);

	}
	elsif ( $unitId eq UnitEnums->UnitId_SCO ) {

		$unit = ScoUnit->new($unitId, $jobId, $title);

	}
	elsif ( $unitId eq UnitEnums->UnitId_GER ) {

		$unit = GerUnit->new($unitId, $jobId, $title);

	}
	elsif ( $unitId eq UnitEnums->UnitId_PDF ) {

		$unit = PdfUnit->new($unitId, $jobId, $title);

	}
	elsif ( $unitId eq UnitEnums->UnitId_OUT ) {

		$unit = OutUnit->new($unitId, $jobId, $title);

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

