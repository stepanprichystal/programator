#-------------------------------------------------------------------------------------------#
# Description: Represent Universal Drill tool manager

# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::TpvService::ServiceApps::ProcessReorderApp::Reorder::CheckInfo;

#3th party library
use strict;
use warnings;
 

#local library
 

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

 
 	$self->{"description"} = shift;
 	$self->{"key"} = shift;
  	$self->{"ver"} = shift;
 	$self->{"type"} = shift;
 	$self->{"mess"} = shift;
 
	return $self;
}


sub GetDesc{
	my $self = shift;
	
	return $self->{"description"};
}

sub GetKey{
	my $self = shift;
	
	return $self->{"key"};
}

sub GetVersion{
	my $self = shift;
	
	return $self->{"ver"};
}

sub GetType{
	my $self = shift;
	
	return $self->{"type"};
}

sub GetMessage{
	my $self = shift;
	
	return $self->{"mess"};
}
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	 
}

1;

