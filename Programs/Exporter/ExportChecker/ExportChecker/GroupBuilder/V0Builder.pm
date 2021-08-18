
#-------------------------------------------------------------------------------------------#
# Description: Base class for BIF builders. Nif Builder is responsible for
# creation nif file depend on pcb type
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::ExportChecker::GroupBuilder::V0Builder;

use Class::Interface;
&implements('Programs::Exporter::ExportChecker::ExportChecker::GroupBuilder::IGroupBuilder');

#3th party library
use strict;
use warnings;

#local library

use aliased 'Programs::Exporter::ExportChecker::ExportChecker::GroupTable::GroupTable';
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::GroupBuilder::Enums';
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::Unit::Helper' => "UnitHelper";
use aliased 'Programs::Exporter::ExportUtility::UnitEnums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	return $self;
}

sub Build {
	my $self = shift;
	$self->{"jobId"} = shift;
	my $groupTables = shift;

	# Table 1

	my $tableTab1 = $groupTables->AddTable("Technology groups");

	# Units
	my $preUnit1 = UnitHelper->GetUnitById( UnitEnums->UnitId_PRE, $self->{"jobId"} );

	my $row1Tab1 = $tableTab1->AddRow();
	$row1Tab1->AddCell( $preUnit1, Enums->Width_75 );

	# Table 2

	my $tableTab2 = $groupTables->AddTable("Main groups");

	# Units
	my $nifUnit1  = UnitHelper->GetUnitById( UnitEnums->UnitId_NIF,  $self->{"jobId"} );
	my $mdiUnit1  = UnitHelper->GetUnitById( UnitEnums->UnitId_MDI,  $self->{"jobId"} );
	my $gerUnit1  = UnitHelper->GetUnitById( UnitEnums->UnitId_GER,  $self->{"jobId"} );
	my $ncUnit1   = UnitHelper->GetUnitById( UnitEnums->UnitId_NC,   $self->{"jobId"} );
	my $scoUnit1  = UnitHelper->GetUnitById( UnitEnums->UnitId_SCO,  $self->{"jobId"} );
	my $pdfUnit1  = UnitHelper->GetUnitById( UnitEnums->UnitId_PDF,  $self->{"jobId"} );
	my $etUnit1  = UnitHelper->GetUnitById( UnitEnums->UnitId_ET,  $self->{"jobId"} );

	my $row1Tab2 = $tableTab2->AddRow();
	$row1Tab2->AddCell( $nifUnit1,  Enums->Width_50 );
	$row1Tab2->AddCell( $gerUnit1, Enums->Width_25 );
	$row1Tab2->AddCell( $mdiUnit1, Enums->Width_25 );

	my $row2Tab2 = $tableTab2->AddRow();
	$row2Tab2->AddCell( $ncUnit1,  Enums->Width_25 );
	$row2Tab2->AddCell( $scoUnit1, Enums->Width_25 );
	$row2Tab2->AddCell( $etUnit1, Enums->Width_25 );
	$row2Tab2->AddCell( $pdfUnit1, Enums->Width_25 );

	# Table 3

	my $tableTab3 = $groupTables->AddTable("Other groups");

	# Units

	my $outUnit1 = UnitHelper->GetUnitById( UnitEnums->UnitId_OUT, $self->{"jobId"} );
	my $plotUnit1 = UnitHelper->GetUnitById( UnitEnums->UnitId_PLOT, $self->{"jobId"} );
	my $commUnit1 = UnitHelper->GetUnitById( UnitEnums->UnitId_COMM, $self->{"jobId"} );

	my $row1Tab3 = $tableTab3->AddRow();
	$row1Tab3->AddCell( $outUnit1, Enums->Width_25 );
	$row1Tab3->AddCell( $plotUnit1, Enums->Width_50 );
	$row1Tab3->AddCell( $commUnit1, Enums->Width_50 );

	# Set which group is selected by default
	$groupTables->SetDefaultSelected($tableTab2);

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

