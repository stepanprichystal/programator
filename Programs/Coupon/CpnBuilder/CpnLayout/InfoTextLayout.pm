
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for NIF creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnBuilder::CpnLayout::InfoTextLayout;

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
 	$self->{"width"} = undef; 
 	$self->{"height"} = undef;
 	$self->{"position"} = undef;
 	
 	$self->{"texts"} = [];
 
	return $self;
 
}
 
sub SetType{
	my $self  = shift;
	my $type = shift;
	
	$self->{"type"} = $type;
} 

sub SetWidth{
	my $self  = shift;
	my $width = shift;
	
	$self->{"width"} = $width;
} 

sub SetHeight{
	my $self  = shift;
	my $height = shift;
	
	$self->{"height"} = $height;
} 

sub SetPosition{
	my $self  = shift;
	my $pos = shift;
	
	$self->{"position"} = $pos;
} 
 
sub AddText{
	my $self  = shift;
	my $point = shift;
	my $textVal = shift;
	
	my %info = ();
	
	$info{"point"} = $point;
	$info{"val"} = $textVal;
	
	
	push(@{$self->{"texts"}}, \%info);
	
} 

sub GetTexts{
	my $self  = shift;
	
	return @{$self->{"texts"}};
}
 
sub GetType{
	my $self  = shift;
	
	return $self->{"type"};
}

sub GetHeight {
	my $self = shift;

	return $self->{"height"};
}

sub GetWidth {
	my $self = shift;

	return $self->{"width"};
}

sub GetPosition {
	my $self = shift;

	return $self->{"position"};
}
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

