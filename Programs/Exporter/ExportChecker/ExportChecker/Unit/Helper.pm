
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
 	my @cells = $groupTables->GetAllUnits();
	
	my $units = Units->new(); 
	$units->Init( $inCAM, $jobId, \@cells );
	$units->InitDataMngr( $inCAM );
	
	return $units;
}


sub __DefineTableGroups {
	my $self = shift;
	my $jobId = shift;

	my $groupBuilder = undef;
	my $groupTables = GroupTables->new();

	my $typeOfPcb = HegMethods->GetTypeOfPcb( $jobId );

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
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

