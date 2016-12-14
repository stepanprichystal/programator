
#-------------------------------------------------------------------------------------------#
# Description: Special layer - Copper, contain special propery and operation for this
# type of layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::SinglePreview::LayerData::LayerDataSingle;


#3th party library
use strict;
use warnings;

#local library

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self  = {};
	bless $self;
 
	$self->{"l"} = shift;
	$self->{"enTit"} = shift;
 	$self->{"czTit"} = shift;
 	$self->{"enInf"} = shift;
 	$self->{"czInf"} = shift;	
 	
	return $self;  
}


sub GetLayer{
	my $self = shift;
	
	return $self->{"l"};
	
}
 
 
sub GetTitle{
	my $self = shift;
	my $lang = shift;
	
	if($lang eq "cz"){
		
		return $self->{"czTit"};
		
	}elsif($lang eq "en"){
		
		
		return $self->{"enTit"};
	}
	
} 


sub GetInfo{
	my $self = shift;
	my $lang = shift;
	
	if($lang eq "cz"){
		
		return $self->{"czInf"};
		
	}elsif($lang eq "en"){
		
		
		return $self->{"enInf"};
	}
	
} 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

