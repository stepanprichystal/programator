
#-------------------------------------------------------------------------------------------#
# Description: Form represent one JobQueue item. Contain controls which show
# status of tasking job.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Managers::AbstractQueue::AbstractQueue::Forms::JobQueueItemForm;
use base qw(Widgets::Forms::CustomQueue::MyWxCustomQueueItem);

#3th party library
use Wx;

use strict;
use warnings;

#local library
use aliased 'Packages::Events::Event';
use aliased 'Enums::EnumsGeneral';
use aliased 'Widgets::Forms::ErrorIndicator::ErrorIndicator';
use aliased 'Widgets::Forms::ResultIndicator::ResultIndicator';
 

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class        = shift;
	my $parent       = shift;
	my $jobId        = shift;
	my $taskId       = shift;
	my $taskData = shift;
	my $taskMngr     = shift;
	my $groupMngr    = shift;
	my $itemMngr     = shift;

	my $self = $class->SUPER::new( $parent, $taskId,  &Wx::wxBORDER_SIMPLE );

	bless($self);

	# PROPERTIES
	$self->{"jobId"}        = $jobId;
	$self->{"taskId"}       = $taskId;
	$self->{"taskData"} = $taskData;

	$self->{"taskMngr"}  = $taskMngr;
	$self->{"groupMngr"} = $groupMngr;
	$self->{"itemMngr"}  = $itemMngr;


	# EVENTS

	$self->{"onStop"}     = Event->new();
	$self->{"onContinue"} = Event->new();
	$self->{"onAbort"}    = Event->new();
	$self->{"onRestart"}    = Event->new();
	$self->{"onRemove"}   = Event->new();

	return $self;
}

# ==============================================
# ITEM QUEUE HANDLERS
# ==============================================

sub _OnStop {
	my $self = shift;

	$self->{"onStop"}->Do( $self->{"taskId"} );
}

sub _OnContinue {
	my $self = shift;

	$self->{"onContinue"}->Do( $self->{"taskId"} );
}

sub _OnAbort {
	my $self = shift;

	$self->{"onAbort"}->Do( $self->{"taskId"} );
}

sub _OnRestart {
	my $self = shift;

	$self->{"onRestart"}->Do( $self->{"taskId"} );
}

sub _OnRemove {
	my $self = shift;

	$self->{"onRemove"}->Do( $self->{"taskId"} );
}

 
# ==============================================
# PUBLIC FUNCTION
# ==============================================
sub GetTaskId {
	my $self = shift;
	return $self->{"taskId"};
}



# ==============================================
# HELPER FUNCTION
# ==============================================
sub _GetDelimiter {
	my $self = shift;
	

	my $pnl = Wx::Panel->new( $self, -1, [ -1, -1 ], [ 1, 1 ] );
	$pnl->SetBackgroundColour( Wx::Colour->new( 150, 150, 150 ) );

	return $pnl;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
