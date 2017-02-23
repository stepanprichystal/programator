
#-------------------------------------------------------------------------------------------#
# Description: Class which keep symbol reference and absolute position to origin
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::SymbolDrawing::SymbolInfo;
 
#3th party library
use strict;
use warnings;
use Storable qw(dclone);

#local library

use aliased 'Packages::CAM::SymbolDrawing::Enums';
use aliased 'Packages::CAM::SymbolDrawing::Point';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {

	my $self = shift;
	$self = {};
	bless $self;
	
	$self->{"symbol"} = shift;
	$self->{"position"} = shift; # absolute position to origin
	
	unless($self->{"position"}){
		$self->{"position"} = Point->new(0,0);
	}
	
	 
	return $self;
}

 
sub GetSymbol {
	my $self  = shift;
 
	return $self->{"symbol"};
}


sub GetPosition {
	my $self  = shift;
 
	return $self->{"position"};
}
 


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

