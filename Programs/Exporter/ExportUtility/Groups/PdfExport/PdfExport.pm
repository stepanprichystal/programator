#-------------------------------------------------------------------------------------------#
# Description: This class contains code, which provides export of specific group
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::Groups::PdfExport::PdfExport;
use base('Programs::Exporter::ExportUtility::Groups::ExportBase');

#3th party library
use strict;
use warnings;

# local library
use aliased "Packages::Export::PdfExport::PdfMngr";

#-------------------------------------------------------------------------------------------#
#  NC export, all layers, all machines..
#-------------------------------------------------------------------------------------------#

sub new {

	my $class  = shift;
	my $unitId = shift;

	my $self = {};

	$self = $class->SUPER::new($unitId);
	bless $self;

	# PROPERTIES

	# EVENTS

	return $self;
}

sub Init {
	my $self       = shift;
	my $inCAM      = shift;
	my $jobId      = shift;
	my $exportData = shift;

	$self->{"inCAM"}      = $inCAM;
	$self->{"jobId"}      = $jobId;
	$self->{"exportData"} = $exportData;

	my $exportControl = $exportData->GetExportControl();
	my $controlStep   = $exportData->GetControlStep();
	my $controlLang   = $exportData->GetControlLang();
	my $infoToPdf = $exportData->GetInfoToPdf();
	my $exportStackup = $exportData->GetExportStackup();
	my $exportPressfit = $exportData->GetExportPressfit();
	

	my $mngr = PdfMngr->new( $inCAM, $jobId, $exportControl, $controlStep, $controlLang, $infoToPdf, $exportStackup, $exportPressfit );

	$mngr->{"onItemResult"}->Add( sub { $self->_OnItemResultHandler(@_) } );

	$self->{"exportMngr"} = $mngr;

	$self->{"itemsCount"} = $mngr->ExportItemsCount();

}

1;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

