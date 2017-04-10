
#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::ExportUtility::Forms::ExportUtilityForm;
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
use aliased 'Programs::Exporter::ExportUtility::ExportUtility::Forms::JobQueueForm';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Widgets::Forms::CustomNotebook::CustomNotebook';
use aliased 'Widgets::Forms::MyWxBookCtrlPage';
 
use aliased 'Managers::AsyncJobMngr::ServerMngr::ServerInfo';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $title = "Exporter utility";
	my $name = "Exporter utility";
	my @dimension = ( 1120, 760 );

	my $self = $class->SUPER::new( @_, $title,$name, \@dimension );

	bless($self);

	# Properties

	# Events

	$self->{"onToProduce"} = Event->new();

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

sub SetJobItemToProduceResult {
	my $self = shift;
	my $task = shift;

	my $jobItem = $self->{"jobQueue"}->GetItem( $task->GetTaskId() );

	$jobItem->SetProduceErrors( $task->GetProduceErrorsCnt() );
	$jobItem->SetProduceWarnings( $task->GetProduceWarningsCnt() );
	$jobItem->SetProduceResult( $task->ResultToProduce(), $task->GetJobSentToProduce() );
}

# ======================================================
# HANDLERS of job queue item
# ======================================================

sub __OnProduceJobClick {
	my $self   = shift;
	my $taskId = shift;

	$self->{"onToProduce"}->Do($taskId);

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

	$$jobQueue->{"onProduce"}->Add( sub { $self->__OnProduceJobClick(@_) } );
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use aliased 'Programs::Exporter::ExportUtility';

	#my $exporter = ExportUtility->new();

	#$app->Test();

	#$exporter->MainLoop;

}

1;

1;
