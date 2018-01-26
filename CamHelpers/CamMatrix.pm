#-------------------------------------------------------------------------------------------#
# Description: Helper class, contains helper function for matrix, layers etc
# Author: SPR
#-------------------------------------------------------------------------------------------#

package CamHelpers::CamMatrix;

#3th party library
use strict;
use warnings;

#loading of locale modules
use aliased 'CamHelpers::CamHelper';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

# Return all layers from matrix as array of hash, which are layer_type == board
# which contain info:
# - gROWname
# - gROWlayer_type
# - gROWcontext
sub AddSideType {
	my $self   = shift;
	my $layers = shift;

	foreach my $l ( @{$layers} ) {

		if ( $l->{"gROWname"} =~ /^[mpl]*c$/ ) {

			$l->{"side"} = "top";

		}
		elsif ( $l->{"gROWname"} =~ /^[mpl]*s$/ ) {

			$l->{"side"} = "bot";

		}
		elsif ( $l->{"gROWname"} =~ /v\d/ ) {

			#not implmented, we have to read from stackup
			$l->{"side"} = undef;
		}

	}
}

# create new empty layer
sub CreateLayer{
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $layerName = shift;
	my $layerType = shift;
	my $polarity = shift;
	my $board = shift;

	$layerType = "document" unless(defined $layerType );
	
	$polarity = "positive" unless(defined $polarity );

	$board = defined $board && $board == 1 ? "board" : "misc";
	
	$inCAM->COM( 'create_layer', "layer" => $layerName, "context" => $board, "type" => $layerType, "polarity" => $polarity, "ins_layer" => '' );
	
}

# Delete Layer if exist
sub DeleteLayer {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $layer = shift;

	if ( CamHelper->LayerExists( $inCAM, $jobId, $layer ) ) {

		$inCAM->COM( "delete_layer", "layer" => $layer );
		return 1;
	}
	else {
		return 0;
	}

}

# Set layer direction
sub SetLayerDirection {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $layer = shift;
	my $dir = shift; # bottom_to_top, top_to_bottom

	$inCAM->COM("matrix_layer_direction","job" => "$jobId","matrix" => "matrix","layer" => "$layer","direction" => $dir);
	
}

1;
