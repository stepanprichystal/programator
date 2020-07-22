#-------------------------------------------------------------------------------------------#
# Description: This class contains code, which provides export of specific group
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::Groups::StnclExport::StnclWorkUnit;
use base('Managers::AbstractQueue::AbstractQueue::JobWorkerUnit');

#3th party library
use strict;
use warnings;

# local library
use aliased 'Packages::Export::StnclExport::StnclMngr';

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

	my $nif            = $taskData->GetExportNif();
	my $data           = $taskData->GetExportData();
	my $pdf            = $taskData->GetExportPdf();
	my $dim2ControlPdf = $taskData->GetDim2ControlPdf();
	my $measure        = $taskData->GetExportMeasureData();
	my $thickness      = $taskData->GetThickness();
	my $fiducInfo      = $taskData->GetFiducialInfo();

	my $mngr = StnclMngr->new( $inCAM, $jobId, $nif, $data, $pdf, $dim2ControlPdf, $measure, $thickness, $fiducInfo );

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

