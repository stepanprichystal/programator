
#-------------------------------------------------------------------------------------------#
# Description: Base class for BIF builders. Nif Builder is responsible for
# creation nif file depend on pcb type
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::ExportChecker::GroupBuilder::OfferBuilder;

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
	my $offerUnit1  = UnitHelper->GetUnitById( UnitEnums->UnitId_OFFER,  $self->{"jobId"} );
	my $commUnit1 = UnitHelper->GetUnitById( UnitEnums->UnitId_COMM, $self->{"jobId"} );
	 

	my $row1Tab2 = $tableTab2->AddRow();
	$row1Tab2->AddCell( $offerUnit1, Enums->Width_25 );
	$row1Tab2->AddCell( $commUnit1,  Enums->Width_50 );

 
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

