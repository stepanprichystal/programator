
#-------------------------------------------------------------------------------------------#
# Description:  
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Coupon::CpnPolicy::CpnVariant::CpnPoolVariant;

#3th party library
use strict;
use warnings;
use List::Util qw[max];

#local library

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;
	
	$self->{"order"} = shift; # pool order, 0 = below, 1 = above 
 
	$self->{"strips"} = [];
	 
	return $self;
}
 
 
sub AddStrip{
	my $self = shift;
	my $strip = shift;
	
	push(@{$self->{"strips"}}, $strip);
} 

sub GetStrips{
	my $self = shift;
	 
	 return @{$self->{"strips"}};
}

sub GetStripsByLayer{
	my $self = shift;
	my $layer = shift;
 
	 return grep { $_->Data()->{"xmlConstraint"}->GetTrackLayer() eq $layer  }@{$self->{"strips"}};
}  


sub GetColumnCnt{
	my $self = shift;
	
	my @cols = map { $_->Col() }   @{$self->{"strips"}};

	my $max = max(@cols);


	return max(@cols) +1;
}

sub GetOrder{
	my $self = shift;
	 
	return $self->{"order"};
} 


sub GetStripByColumn{
	my $self = shift;
	my $column = shift;
 
	my $s = (grep { $_->Col() == $column } @{$self->{"strips"}})[0];
	
	return $s;
}


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

