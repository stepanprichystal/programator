
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for NIF creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Coupon::CpnBuilder::CpnLayout::TitleLayout;

#3th party library
use strict;
use warnings;

#local library
 

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

 	$self->{"type"} = undef; # top/right
 	 	$self->{"w"} = undef;
 	 	$self->{"h"} = undef;
 	
 	# Job id
 	$self->{"jobIdPosition"} = undef;
 	$self->{"jobIdVal"} = undef;
 	
 	# Logo
 	$self->{"logoPosition"} = undef;
 	#$self->{"logoVal"} = undef;
 	
 	# title position + rotation

 	$self->{"angle"} = undef;
 
 
	return $self;
 
}
 
sub SetType{
	my $self  = shift;
	my $type = shift;
	
	$self->{"type"} = $type;
} 
 
 
sub GetType{
	my $self  = shift;
	
	return $self->{"type"};
}
 
sub SetHeight {
	my $self = shift;

	$self->{"h"} = shift;
}

sub GetHeight {
	my $self = shift;

	return $self->{"h"};
}

sub SetWidth {
	my $self  = shift;
	my $width = shift;

	$self->{"w"} = $width;

}

sub GetWidth {
	my $self = shift;

	return $self->{"w"};
}

 

sub SetJobIdPosition{
	my $self  = shift;
	my $pos = shift;
	
	$self->{"jobIdPosition"} = $pos;
} 

sub GetJobIdPosition {
	my $self = shift;

	return $self->{"jobIdPosition"};
}

sub SetLogoPosition{
	my $self  = shift;
	my $pos = shift;
	
	$self->{"logoPosition"} = $pos;
} 

sub GetLogoPosition {
	my $self = shift;

	return $self->{"logoPosition"};
}
 
 
sub SetJobIdVal{
	my $self  = shift;
	my $val = shift;
	
	$self->{"jobIdVal"} = $val;
} 

sub GetJobIdVal {
	my $self = shift;

	return $self->{"jobIdVal"};
} 

 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

