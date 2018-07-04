
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for NIF creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnBuilder::CpnLayout::PadTextLayout;

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

 	$self->{"text"} = shift; # top/right
 	$self->{"position"} = shift; 
 	$self->{"positionMirror"} = shift;
 	$self->{"negRectW"} = shift;
 	$self->{"negRectH"} = shift;
 	$self->{"negRectPosition"} = shift; 
 	$self->{"negRectPositionMirror"} = shift;
 	 
 
	return $self;
 
}
 
sub SetText{
	my $self  = shift;
	my $type = shift;
	
	$self->{"text"} = $type;
} 

sub GetText{
	my $self  = shift;
	
	return $self->{"text"};
}
 
sub SetPosition{
	my $self  = shift;
	my $pos = shift;
	
	$self->{"position"} = $pos;
} 


sub GetPosition {
	my $self = shift;

	return $self->{"position"};
}

sub SetPositionMirror{
	my $self  = shift;
	my $pos = shift;
	
	$self->{"positionMirror"} = $pos;
} 


sub GetPositionMirror {
	my $self = shift;

	return $self->{"positionMirror"};
}


sub SetNegRectW{
	my $self  = shift;
	my $pos = shift;
	
	$self->{"negRectW"} = $pos;
} 


sub GetNegRectW {
	my $self = shift;

	return $self->{"negRectW"};
}

sub SetNegRectH{
	my $self  = shift;
	my $pos = shift;
	
	$self->{"negRectH"} = $pos;
} 


sub GetNegRectH {
	my $self = shift;

	return $self->{"negRectH"};
}
 

sub SetNegRectPosition{
	my $self  = shift;
	my $pos = shift;
	
	$self->{"negRectPosition"} = $pos;
} 


sub GetNegRectPosition {
	my $self = shift;

	return $self->{"negRectPosition"};
}

sub SetNegRectPositionMirror{
	my $self  = shift;
	my $pos = shift;
	
	$self->{"negRectPositionMirror"} = $pos;
} 


sub GetNegRectPositionMirror {
	my $self = shift;

	return $self->{"negRectPositionMirror"};
}

 
 
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

