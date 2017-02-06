#-------------------------------------------------------------------------------------------#
# Description: Class which represent primitive geometric - line
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::SymbolDrawing::Point;

 
#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::CAM::SymbolDrawing::Enums';
 

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;
	
	$self->{"x"} = shift;
	$self->{"y"} = shift;

	unless(defined $self->{"x"}){
		$self->{"x"} = 0;
	}
	
	unless(defined $self->{"y"}){
		$self->{"y"} = 0;
	}	
 
	return $self;
}

 
sub X{
		my $self  = shift;
		return $self->{"x"};
}

sub Y{
		my $self  = shift;
		return $self->{"y"};
}
 
 
sub Move{
		my $self  = shift;
		my $x  = shift; # number of mm in x axis
		my $y  = shift;  # number of mm in y axis
		
		$self->{"x"} += $x;
		$self->{"y"} += $y;
} 


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

