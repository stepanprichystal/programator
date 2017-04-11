
#-------------------------------------------------------------------------------------------#
# Description: Class is used as data store for Unit object
# Keep also state of group and task error information
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Managers::AbstractQueue::Groups::GroupData;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Managers::AbstractQueue::TaskResultMngr';
use aliased 'Managers::AbstractQueue::Enums';
#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $self = shift;
	$self = {};
	bless $self;

	# state data for gui controls
	 
	$self->{"itemsMngr"} = TaskResultMngr->new();
	
	$self->{"groupMngr"} = TaskResultMngr->new();
	
	# state of whole group. Value is enum GroupState_xx
	$self->{"state"} = Enums->GroupState_WAITING;
	
	$self->{"progress"} = 0;

	return $self;
}

 
 sub SetProgress {
	my $self  = shift;
	$self->{"progress"} = shift;
}

sub GetProgress {
	my $self  = shift;
	return $self->{"progress"};
}
 
sub SetGroupState {
	my $self  = shift;
	$self->{"state"} = shift;
}

sub GetGroupState {
	my $self  = shift;
	return $self->{"state"};
}



#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

 
}

1;

