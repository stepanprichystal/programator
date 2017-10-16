
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
use aliased 'Programs::Exporter::ExportChecker::Groups::StnclExport::Presenter::StnclUnit';
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::GroupBuilder::Enums';

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
	my $stnclUnit = StnclUnit->new( $self->{"jobId"} );

	my $row1Tab1 = $tableTab1->AddRow();
	$row1Tab1->AddCell( $stnclUnit, Enums->Width_25 );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

