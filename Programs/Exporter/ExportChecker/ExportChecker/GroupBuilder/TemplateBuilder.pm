
#-------------------------------------------------------------------------------------------#
# Description: Base class for BIF builders. Nif Builder is responsible for
# creation nif file depend on pcb type
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
	my $self  = shift;
	$self->{"jobId"} = shift;
	my $groupTables  = shift;
	
	 my $tableTab1 = GroupTable->new("Template groups");

	# nif unit
	my $nifUnit1 = NifUnit->new( $self->{"jobId"}, "Nif 1");
	my $nifUnit2 = NifUnit->new( $self->{"jobId"}, "Nif 2" );
	 
	
	my $row1Tab1 = $tableTab1->AddRow();
	$row1Tab1->AddCell($nifUnit1);

	 
	my $row2Tab1 = $tableTab1->AddRow();
	$row2Tab1->AddCell($nifUnit2);
 
	$groupTables->AddTable($tableTab1);
}
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

