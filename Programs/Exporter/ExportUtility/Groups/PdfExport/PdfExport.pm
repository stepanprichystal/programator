#-------------------------------------------------------------------------------------------#
# Description: This class contains code, which provides export of specific group
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::Groups::PdfExport::PdfExport;
use base('Managers::AbstractQueue::Groups::TaskClassBase');

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
	my $taskData = shift;

	$self->{"inCAM"}      = $inCAM;
	$self->{"jobId"}      = $jobId;
	$self->{"taskData"} = $taskData;

	my $exportControl = $taskData->GetExportControl();
	my $controlStep   = $taskData->GetControlStep();
	my $controlLang   = $taskData->GetControlLang();
	my $infoToPdf = $taskData->GetInfoToPdf();
	my $exportStackup = $taskData->GetExportStackup();
	my $exportPressfit = $taskData->GetExportPressfit();
	

	my $mngr = PdfMngr->new( $inCAM, $jobId, $exportControl, $controlStep, $controlLang, $infoToPdf, $exportStackup, $exportPressfit );

	$mngr->{"onItemResult"}->Add( sub { $self->_OnItemResultHandler(@_) } );

	$self->{"taskMngr"} = $mngr;

	$self->{"itemsCount"} = $mngr->TaskItemsCount();

}

1;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

