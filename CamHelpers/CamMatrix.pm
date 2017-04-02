#-------------------------------------------------------------------------------------------#
# Description: Helper class, contains helper function for matrix, layers etc
# Author: SPR
#-------------------------------------------------------------------------------------------#

package CamHelpers::CamMatrix;


#3th party library
use strict;
use warnings;

#loading of locale modules

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#


  # Return all layers from matrix as array of hash, which are layer_type == board
# which contain info:
# - gROWname
# - gROWlayer_type
# - gROWcontext
sub AddSideType {
	my $self  = shift;
	my $layers = shift;
	
	foreach my $l (@{$layers}){
		
		if($l->{"gROWname"} =~ /^[mpl]*c$/){
			
			$l->{"side"} = "top";
			
		}elsif($l->{"gROWname"} =~ /^[mpl]*s$/){
			
			$l->{"side"} = "bot";
			
		}elsif($l->{"gROWname"} =~ /v\d/){
			
			#not implmented, we have to read from stackup
			$l->{"side"} = undef;
		}
 
	}
	 
}
 

1;
