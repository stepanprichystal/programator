
#-------------------------------------------------------------------------------------------#
# Description: Base class for BIF builders. Nif Builder is responsible for
# creation nif file depend on pcb type
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::ExportChecker::GroupBuilder::StandardBuilder;

use Class::Interface;
&implements('Programs::Exporter::ExportChecker::ExportChecker::GroupBuilder::IGroupBuilder');

#3th party library
use strict;
use warnings;

#local library

use aliased 'Programs::Exporter::ExportChecker::ExportChecker::GroupTable::GroupTable';
use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Presenter::NifUnit';

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

	my $tableTab1 = GroupTable->new("Main groups");

	# nif unit
	my $nifUnit1 = NifUnit->new( $self->{"jobId"}, "Nif 1" );
	my $nifUnit2 = NifUnit->new( $self->{"jobId"}, "Nif 2" );
	my $nifUnit3 = NifUnit->new( $self->{"jobId"}, "Nif 3" );
	my $nifUnit4 = NifUnit->new( $self->{"jobId"}, "Nif 4" );
	my $nifUnit5 = NifUnit->new( $self->{"jobId"}, "Nif 5" );
	my $nifUnit6 = NifUnit->new( $self->{"jobId"}, "Nif 6" );
	my $nifUnit7 = NifUnit->new( $self->{"jobId"}, "Nif 7" );

	my $row1Tab1 = $tableTab1->AddRow();
	$row1Tab1->AddCell($nifUnit1);

	$row1Tab1->AddCell($nifUnit2);

	#$row1->AddCell($nifUnit3);

	my $row2Tab1 = $tableTab1->AddRow();
	$row2Tab1->AddCell($nifUnit3);
	$row2Tab1->AddCell($nifUnit4);

	my $row3Tab1 = $tableTab1->AddRow();
	$row3Tab1->AddCell($nifUnit5);
	$row3Tab1->AddCell($nifUnit6);
	$row3Tab1->AddCell($nifUnit7);

	#$row2Tab1->AddCell($nifUnit6);

	#	my $tab2 = $self->{"form"}->GetTab(1);
	#
	my $tableTab2 = GroupTable->new("Other groups");

	#
	#	# nif unit
	my $nifUnit8  = NifUnit->new( $self->{"jobId"}, "Nif 8" );
	my $nifUnit9  = NifUnit->new( $self->{"jobId"}, "Nif 9" );
	my $nifUnit10 = NifUnit->new( $self->{"jobId"}, "Nif 10" );
	my $nifUnit11 = NifUnit->new( $self->{"jobId"}, "Nif 11" );
	#
	my $row1Tab2 = $tableTab2->AddRow();
	$row1Tab2->AddCell($nifUnit8);
	$row1Tab2->AddCell($nifUnit9);

	my $row2Tab2 = $tableTab2->AddRow();
	$row2Tab2->AddCell($nifUnit10);
	$row2Tab2->AddCell($nifUnit11);

	$groupTables->AddTable($tableTab1);
	$groupTables->AddTable($tableTab2);

	#$self->{"groupTables"}->AddTable($tableTab2);
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

