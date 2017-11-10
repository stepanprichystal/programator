
#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::PoolMerge::PoolMerge::Forms::PoolMergeForm;
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
use aliased 'Programs::PoolMerge::PoolMerge::Forms::JobQueueForm';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Widgets::Forms::CustomNotebook::CustomNotebook';
use aliased 'Widgets::Forms::MyWxBookCtrlPage';
 
use aliased 'Managers::AsyncJobMngr::ServerMngr::ServerInfo';
use aliased 'Packages::Other::AppConf';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	 
	 

	my $self = $class->SUPER::new( @_  );

	bless($self);

	# Properties

	# Events

	$self->{"onSentToExport"} = Event->new();

	# Set base class handlers
	$self->{"onSetJobQueue"}->Add( sub { $self->__OnSetJobQueue(@_) } );
 
	#$self->SetFormColors($Widgets::Style::clrDefaultFrm, undef, Wx::Colour->new( 228, 232, 243 ), Wx::Colour->new( 215, 230, 251 ) );

	return $self;
}

 

# ======================================================
# Public method
# ======================================================

# ============================================================
# Mehtods for update job queue items
# ============================================================

sub SetJobItemSentToExportResult {
	my $self = shift;
	my $task = shift;

	my $jobItem = $self->{"jobQueue"}->GetItem( $task->GetTaskId() );

	$jobItem->SetToExportErrors( $task->GetToExportErrorsCnt() );
	$jobItem->SetToExportWarnings( $task->GetToExportWarningsCnt() );
	$jobItem->SetToExportResult( $task->ResultSentToExport(), $task->GetJobSentToExport() );
}

sub SetJobItemResult {
	my $self = shift;
	my $task = shift;

	my $jobItem = $self->{"jobQueue"}->GetItem( $task->GetTaskId() );

	$jobItem->SetTaskResult( $task->Result(), $task->GetJobAborted(), $task->GetJobSentToExport() );

}

sub SetJobItemStopped {
	my $self   = shift;
	my $task = shift;

	my $jobItem = $self->{"jobQueue"}->GetItem( $task->GetTaskId() );
 
	$jobItem->SetJobItemStopped();
}


sub SetJobItemContinue {
	my $self   = shift;
	my $task = shift;

	my $jobItem = $self->{"jobQueue"}->GetItem( $task->GetTaskId() );
 
	$jobItem->SetJobItemContinue();
}

sub SetMasterJob {
	my $self = shift;
	my $task = shift;
	my $masteJob = shift;
	
	my $jobItem = $self->{"jobQueue"}->GetItem( $task->GetTaskId() );

	$jobItem->SetMasterJob( $masteJob);
	
}

# ======================================================
# HANDLERS of job queue item
# ======================================================

sub __OnToExportJobClick {
	my $self   = shift;
	my $taskId = shift;

	$self->{"onSentToExport"}->Do($taskId);

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

	$$jobQueue->{"onToExport"}->Add( sub { $self->__OnToExportJobClick(@_) } );
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {


}

1;

1;
