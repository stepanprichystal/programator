#-------------------------------------------------------------------------------------------#
# Description: Child class, responsible for initialiyation "worker unit", which are processed
# by worker class in child thread
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::ExportUtility::UnitBuilder;
use base("Managers::AbstractQueue::AbstractQueue::UnitBuilderBase");

use Class::Interface;
&implements('Managers::AbstractQueue::AbstractQueue::IUnitBuilder');

#3th party library
use strict;
use warnings;
use JSON;

#local library
use aliased 'Programs::Exporter::ExportUtility::DataTransfer::DataTransfer';
use aliased 'Programs::Exporter::ExportUtility::DataTransfer::Enums' => 'EnumsTransfer';

use aliased 'Programs::Exporter::ExportUtility::Groups::NifExport::NifWorkUnit';
use aliased 'Programs::Exporter::ExportUtility::Groups::NCExport::NCWorkUnit';
use aliased 'Programs::Exporter::ExportUtility::Groups::ETExport::ETWorkUnit';
use aliased 'Programs::Exporter::ExportUtility::Groups::AOIExport::AOIWorkUnit';
use aliased 'Programs::Exporter::ExportUtility::Groups::PlotExport::PlotWorkUnit';
use aliased 'Programs::Exporter::ExportUtility::Groups::PreExport::PreWorkUnit';
use aliased 'Programs::Exporter::ExportUtility::Groups::ScoExport::ScoWorkUnit';
use aliased 'Programs::Exporter::ExportUtility::Groups::GerExport::GerWorkUnit';
use aliased 'Programs::Exporter::ExportUtility::Groups::PdfExport::PdfWorkUnit';
use aliased 'Programs::Exporter::ExportUtility::Groups::OutExport::OutWorkUnit';
use aliased 'Programs::Exporter::ExportUtility::Groups::StnclExport::StnclWorkUnit';
use aliased 'Programs::Exporter::ExportUtility::Groups::ImpExport::ImpWorkUnit';
use aliased 'Programs::Exporter::ExportUtility::UnitEnums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	my $json     = JSON->new();
	my $hashData = $json->decode( $self->{"jobStrData"} );

 
	my $dataTransfer = DataTransfer->new( $self->{"jobId"}, EnumsTransfer->Mode_READFROMSTR, undef, $hashData->{"jsonData"} );

	$self->{"taskData"} = $dataTransfer->GetExportData( $hashData->{"jsonData"} );

	return $self;
}

sub GetTaskData {
	my $self = shift;

	return $self->{"taskData"};
}

sub GetUnits {
	my $self = shift;

	my $taskData = $self->{"taskData"};

	my @keys     = $taskData->GetOrderedUnitKeys(1);
	my %allUnits = ();

	foreach my $key (@keys) {

		my $unitTaskData = $taskData->GetUnitData($key);

		my $unit = $self->__GetUnitClass($key);

		$unit->SetTaskData($unitTaskData);

		#$unit->Init( $self->{"inCAM"}, $self->{"jobId"}, $unitTaskData );

		$allUnits{$key} = $unit;
	}

	return %allUnits;
}

# Return initialized "unit" object by unitId
sub __GetUnitClass {
	my $self   = shift;
	my $unitId = shift;

	my $unit;
	my $jobId = $self->{"jobId"};

	if ( $unitId eq UnitEnums->UnitId_NIF ) {

		$unit = NifWorkUnit->new($unitId);

	}
	elsif ( $unitId eq UnitEnums->UnitId_NC ) {

		$unit = NCWorkUnit->new($unitId);

	}
	elsif ( $unitId eq UnitEnums->UnitId_ET ) {

		$unit = ETWorkUnit->new($unitId);

	}
	elsif ( $unitId eq UnitEnums->UnitId_AOI ) {

		$unit = AOIWorkUnit->new($unitId);

	}
	elsif ( $unitId eq UnitEnums->UnitId_PLOT ) {

		$unit = PlotWorkUnit->new($unitId);

	}
	elsif ( $unitId eq UnitEnums->UnitId_PRE ) {

		$unit = PreWorkUnit->new($unitId);

	}
	elsif ( $unitId eq UnitEnums->UnitId_SCO ) {

		$unit = ScoWorkUnit->new($unitId);

	}
	elsif ( $unitId eq UnitEnums->UnitId_GER ) {

		$unit = GerWorkUnit->new($unitId);

	}
	elsif ( $unitId eq UnitEnums->UnitId_PDF ) {

		$unit = PdfWorkUnit->new($unitId);

	}
	elsif ( $unitId eq UnitEnums->UnitId_OUT ) {

		$unit = OutWorkUnit->new($unitId);

	}elsif ( $unitId eq UnitEnums->UnitId_STNCL ) {

		$unit = StnclWorkUnit->new($unitId);

	}elsif ( $unitId eq UnitEnums->UnitId_IMP ) {

		$unit = ImpWorkUnit->new($unitId);

	}else{
		
		die "Unit class (id: $unitId) was not found";
	}



	return $unit;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use aliased 'Programs::Exporter::ExportChecker::ExportChecker::StorageMngr';

	#my $id

	#my $form = StorageMngr->new();

}

1;

