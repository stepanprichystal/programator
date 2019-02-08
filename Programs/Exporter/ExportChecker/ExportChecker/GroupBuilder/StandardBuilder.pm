#
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
	my $preUnit1 = PreUnit->new( $self->{"jobId"});	
	my $nifUnit1 = NifUnit->new( $self->{"jobId"});
	my $plotUnit1 = PlotUnit->new( $self->{"jobId"} );
	my $ncUnit1 = NCUnit->new( $self->{"jobId"});
	my $gerUnit1 = GerUnit->new( $self->{"jobId"} );
	my $scoUnit1 = ScoUnit->new( $self->{"jobId"} );
	my $pdfUnit1 = PdfUnit->new( $self->{"jobId"} );

	my $row1Tab1 = $tableTab1->AddRow();
	$row1Tab1->AddCell($preUnit1, Enums->Width_50);
	$row1Tab1->AddCell($nifUnit1, Enums->Width_50);
	$row1Tab1->AddCell($plotUnit1, Enums->Width_50);


	my $row2Tab1 = $tableTab1->AddRow();
	$row2Tab1->AddCell($ncUnit1, Enums->Width_25);
	$row2Tab1->AddCell($scoUnit1, Enums->Width_25);
	$row2Tab1->AddCell($gerUnit1, Enums->Width_25);
	$row2Tab1->AddCell($pdfUnit1, Enums->Width_25);
	
	# Table 2
	
	my $tableTab2 = $groupTables->AddTable("Other groups");
	# Units
	
	my $aoiUnit1 = AOIUnit->new( $self->{"jobId"} );
	my $etUnit1 = ETUnit->new( $self->{"jobId"} );
	my $impUnit1 = ImpUnit->new( $self->{"jobId"} );
	my $outUnit1 = OutUnit->new( $self->{"jobId"} );
	

	my $row1Tab2 = $tableTab2->AddRow();
	$row1Tab2->AddCell($aoiUnit1, Enums->Width_25);
	$row1Tab2->AddCell($etUnit1, Enums->Width_25);
	$row1Tab2->AddCell($impUnit1, Enums->Width_25);
	$row1Tab2->AddCell($outUnit1, Enums->Width_25);
 
 

	#$self->{"groupTables"}->AddTable($tableTab2);
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

