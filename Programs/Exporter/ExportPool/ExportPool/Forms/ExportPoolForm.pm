
#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportPool::ExportPool::Forms::ExportPoolForm;
use base 'Managers::AbstractQueue::AbstractQueue::Forms::AbstractQueueForm';

#3th party library

use Wx;
use strict;
use warnings;
use Win32::GuiTest qw(FindWindowLike SetFocus SetForegroundWindow);

#local library
use Widgets::Style;
use aliased 'Widgets::Forms::MyWxFrame';
use aliased 'Helpers::FileHelper';
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';

use aliased 'Packages::Events::Event';
use aliased 'Programs::Exporter::ExportPool::ExportPool::Forms::JobQueueForm';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Widgets::Forms::CustomNotebook::CustomNotebook';
use aliased 'Widgets::Forms::MyWxBookCtrlPage';
use aliased 'Managers::AbstractQueue::ExportData::Enums' => 'EnumsTransfer';
use aliased 'Managers::AsyncJobMngr::ServerMngr::ServerInfo';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $title = "Exporter utility";
	my @dimension = ( 1120, 760 );

	my $self = $class->SUPER::new( @_, $title, \@dimension );

	bless($self);

	# Properties

	# Events

	$self->{"onToExport"} = Event->new();

	# Set base class handlers
	$self->{"onSetJobQueue"}->Add( sub { $self->__OnSetJobQueue(@_) } );

	return $self;
}

# ======================================================
# Public method
# ======================================================

# ============================================================
# Mehtods for update job queue items
# ============================================================

sub SetJobItemToExportResult {
	my $self = shift;
	my $task = shift;

	my $jobItem = $self->{"jobQueue"}->GetItem( $task->GetTaskId() );

	$jobItem->SetExportErrors( $task->GetExportErrorsCnt() );
	$jobItem->SetExportWarnings( $task->GetExportWarningsCnt() );
	$jobItem->SetToExportResult( $task->ResultToExport(), $task->GetJobSendToExport() );
}

# ======================================================
# HANDLERS of job queue item
# ======================================================

sub __OnExportJobClick {
	my $self   = shift;
	my $taskId = shift;

	$self->{"onToExport"}->Do($taskId);

}

# ========================================================================================== #
#  BUILD GUI SECTION
# ========================================================================================== #

# Set job queue GUI
sub __OnSetJobQueue {
	my $self      = shift;
	my $parent    = shift;
	my $dimension = shift;
	my $jobQueue  = shift;

	$$jobQueue = JobQueueForm->new( $parent, $dimension );

	$$jobQueue->{"onExport"}->Add( sub { $self->__OnExportJobClick(@_) } );
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use aliased 'Programs::Exporter::ExporterUtility';

	#my $exporter = ExporterUtility->new();

	#$app->Test();

	#$exporter->MainLoop;

}

1;

1;
