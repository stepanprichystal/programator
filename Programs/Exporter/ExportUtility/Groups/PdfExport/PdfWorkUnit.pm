#-------------------------------------------------------------------------------------------#
# Description: This class contains code, which provides export of specific group
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::Groups::PdfExport::PdfWorkUnit;
use base('Managers::AbstractQueue::AbstractQueue::JobWorkerUnit');

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
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my $taskData = $self->{"taskData"};

	$self->{"inCAM"} = $inCAM;
	$self->{"jobId"} = $jobId;

	my $exportControl       = $taskData->GetExportControl();
	my $controlStep         = $taskData->GetControlStep();
	my $controlLang         = $taskData->GetControlLang();
	my $infoToPdf           = $taskData->GetInfoToPdf();
	my $inclNestedStep      = $taskData->GetControlInclNested();
	my $exportStackup       = $taskData->GetExportStackup();
	my $exportPressfit      = $taskData->GetExportPressfit();
	my $exportToleranceHole = $taskData->GetExportToleranceHole();
	my $exportNCSpecial     = $taskData->GetExportNCSpecial();
	my $exportCvrlStencil   = $taskData->GetExportCvrlStencil();
	my $exportPeelStencil   = $taskData->GetExportPeelStencil();

	my $mngr = PdfMngr->new(
							 $inCAM,           $jobId,             $exportControl, $controlStep,    $controlLang,
							 $infoToPdf,       $inclNestedStep,    $exportStackup, $exportPressfit, $exportToleranceHole,
							 $exportNCSpecial, $exportCvrlStencil, $exportPeelStencil
	);

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

