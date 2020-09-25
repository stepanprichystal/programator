
#-------------------------------------------------------------------------------------------#
# Description: Defaine groups when pcb it type of stencil
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::ExportChecker::GroupBuilder::TemplateBuilder;

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

	my $tableTab1 = $groupTables->AddTable("Main groups");

	# Units
	my $stnclUnit = UnitHelper->GetUnitById( UnitEnums->UnitId_STNCL,  $self->{"jobId"} );
	my $commUnit1 = UnitHelper->GetUnitById( UnitEnums->UnitId_COMM, $self->{"jobId"} );

	my $row1Tab1 = $tableTab1->AddRow();
	$row1Tab1->AddCell( $stnclUnit, Enums->Width_50 );
	$row1Tab1->AddCell( $commUnit1, Enums->Width_50 );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

