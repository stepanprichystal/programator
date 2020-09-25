
#-------------------------------------------------------------------------------------------#
# Description: Prepare units for exporter checker
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::ExportChecker::Unit::Helper;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::Unit::Units';
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::GroupTable::GroupTables';
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::GroupBuilder::StandardBuilder';
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::GroupBuilder::TemplateBuilder';
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::GroupBuilder::V0Builder';
use aliased 'Programs::Exporter::ExportUtility::UnitEnums';

use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::Presenter::PreUnit';
use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Presenter::NifUnit';
use aliased 'Programs::Exporter::ExportChecker::Groups::NCExport::Presenter::NCUnit';
use aliased 'Programs::Exporter::ExportChecker::Groups::AOIExport::Presenter::AOIUnit';
use aliased 'Programs::Exporter::ExportChecker::Groups::ETExport::Presenter::ETUnit';
use aliased 'Programs::Exporter::ExportChecker::Groups::PlotExport::Presenter::PlotUnit';
use aliased 'Programs::Exporter::ExportChecker::Groups::GerExport::Presenter::GerUnit';
use aliased 'Programs::Exporter::ExportChecker::Groups::ScoExport::Presenter::ScoUnit';
use aliased 'Programs::Exporter::ExportChecker::Groups::PdfExport::Presenter::PdfUnit';
use aliased 'Programs::Exporter::ExportChecker::Groups::OutExport::Presenter::OutUnit';
use aliased 'Programs::Exporter::ExportChecker::Groups::ImpExport::Presenter::ImpUnit';
use aliased 'Programs::Exporter::ExportChecker::Groups::CommExport::Presenter::CommUnit';
use aliased 'Programs::Exporter::ExportChecker::Groups::OfferExport::Presenter::OfferUnit';
use aliased 'Programs::Exporter::ExportChecker::Groups::StnclExport::Presenter::StnclUnit';

#-------------------------------------------------------------------------------------------#
#  Package methods, requested by IUnit interface
#-------------------------------------------------------------------------------------------#

# Return <Units> class which conatin prepared unit for specific type of pcb
# Preparetion is done by one of "group builder" choosed by type of pcb
sub PrepareUnits {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	# Keep all references of used groups/units in form

	my $groupTables = $self->__DefineTableGroups($jobId);
	my @cells       = $groupTables->GetAllUnits();

	my $units = Units->new();
	$units->Init( $inCAM, $jobId, undef, \@cells );
	$units->InitDataMngr($inCAM);

	return $units;
}

sub __DefineTableGroups {
	my $self  = shift;
	my $jobId = shift;

	my $groupBuilder = undef;
	my $groupTables  = GroupTables->new();

	my $typeOfPcb = HegMethods->GetTypeOfPcb($jobId);

	if ( $typeOfPcb eq 'Neplatovany' ) {

		$groupBuilder = V0Builder->new();
	}
	elsif ( $typeOfPcb eq 'Sablona' ) {

		$groupBuilder = TemplateBuilder->new();

	}
	else {

		$groupBuilder = StandardBuilder->new();
	}

	$groupBuilder->Build( $jobId, $groupTables );

	return $groupTables;

}

sub GetUnitById {
	my $self   = shift;
	my $unitId = shift;
	my $jobId  = shift;

	my $unit = undef;

	if ( $unitId eq UnitEnums->UnitId_NIF ) {
		$unit = NifUnit->new($jobId);
	}
	elsif ( $unitId eq UnitEnums->UnitId_NC )    { $unit = NCUnit->new($jobId); }
	elsif ( $unitId eq UnitEnums->UnitId_ET )    { $unit = ETUnit->new($jobId); }
	elsif ( $unitId eq UnitEnums->UnitId_AOI )   { $unit = AOIUnit->new($jobId); }
	elsif ( $unitId eq UnitEnums->UnitId_PLOT )  { $unit = PlotUnit->new($jobId); }
	elsif ( $unitId eq UnitEnums->UnitId_PRE )   { $unit = PreUnit->new($jobId); }
	elsif ( $unitId eq UnitEnums->UnitId_GER )   { $unit = GerUnit->new($jobId); }
	elsif ( $unitId eq UnitEnums->UnitId_PDF )   { $unit = PdfUnit->new($jobId); }
	elsif ( $unitId eq UnitEnums->UnitId_SCO )   { $unit = ScoUnit->new($jobId); }
	elsif ( $unitId eq UnitEnums->UnitId_OUT )   { $unit = OutUnit->new($jobId); }
	elsif ( $unitId eq UnitEnums->UnitId_STNCL ) { $unit = StnclUnit->new($jobId); }
	elsif ( $unitId eq UnitEnums->UnitId_IMP )   { $unit = ImpUnit->new($jobId); }
	elsif ( $unitId eq UnitEnums->UnitId_COMM )  { $unit = CommUnit->new($jobId); }
	elsif ( $unitId eq UnitEnums->UnitId_OFFER )  { $unit = OfferUnit->new($jobId); }

	return $unit;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

