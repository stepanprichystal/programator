
#-------------------------------------------------------------------------------------------#
# Description: Represent notify form and its behavoiur
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Managers::AbstractQueue::NotifyMngr::Notify;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
 
#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $self = shift;
	$self = {};
	bless $self;

	# state data for gui controls
	 
	$self->{"notifyFrm"} = shift;
	
	$self->{"taskId"} = shift; # abstractQueue task asociated with this notify frm
	
	$self->{"autoClose"} = shift;

	$self->{"dispTime"} = shift;
	
	
	
	$self->{"displayed"} = undef; # tie when notifz was displayed
 
	return $self;
}

 
sub SetDisplayed{
	my $self  = shift;
	my $displayed = shift;
	
	$self->{"displayed"} = $displayed;
} 

sub GetDisplayed {
	my $self  = shift;
	return $self->{"displayed"};
}
  
 
sub GetNotifyFrm {
	my $self  = shift;
	return $self->{"notifyFrm"};
}
  
  
sub GetAutoClose {
	my $self  = shift;
	return $self->{"autoClose"};
}

 
sub GetDispTime {
	my $self  = shift;
	return $self->{"dispTime"};
}

sub GetNotifyId{
	my $self  = shift;
	return $self->{"notifyFrm"}->GetNotifyId();
}

sub GetTaskId{
	my $self  = shift;
 
	return $self->{"taskId"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

 
}

1;

