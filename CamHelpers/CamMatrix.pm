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
use aliased 'CamHelpers::CamJob';
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

# Duplicate layer
sub CopyLayer {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $sourceLayer = shift;
	my $sourceStep  = shift;
	my $targetLayer = shift;
	my $targetStep  = shift;
	my $invert      = shift // 0;
	my $mode        = shift // "replace";    # replace / append

	$invert = defined $invert && $invert == 1 ? "yes" : "no";

	$inCAM->COM(
		'copy_layer',
		"source_job"   => $jobId,
		"source_step"  => $sourceStep,
		"source_layer" => $sourceLayer,
		"dest"         => 'layer_name',
		"dest_layer"   => $targetLayer,
		"dest_step"    => $targetStep,
		"mode"         => $mode,
		"invert"       => $invert
	);
	
	return 1;
 
}

# Create new empty layer
sub CreateLayer {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $layerName = shift;
	my $layerType = shift;
	my $polarity  = shift;
	my $board     = shift;
	my $insLayer  = shift // "";          # name of next layer where new layer will be put
	my $location  = shift // "before";    # before/after

	$layerType = "document" unless ( defined $layerType );

	$polarity = "positive" unless ( defined $polarity );

	$board = defined $board && $board == 1 ? "board" : "misc";

	$inCAM->COM(
				 'create_layer',
				 "layer"     => $layerName,
				 "context"   => $board,
				 "type"      => $layerType,
				 "polarity"  => $polarity,
				 "ins_layer" => $insLayer,
				 "location"  => $location
	);

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
	my $dir   = shift;    # bottom_to_top, top_to_bottom

	$inCAM->COM( "matrix_layer_direction", "job" => "$jobId", "matrix" => "matrix", "layer" => "$layer", "direction" => $dir );

}

# Return layer polarity
sub GetLayerPolarity {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $layer = shift;

	my $l = ( grep { $_->{"gROWname"} eq $layer } CamJob->GetAllLayers( $inCAM, $jobId ) )[0];

	return $l->{"gROWpolarity"};
}

# Return array of affected layers
sub GetAffectedLayers{
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	
	$inCAM->COM("get_affect_layer");
	
	my @layers = split(" ", $inCAM->GetReply()) ;
	
 	$_ =~ s/\s//g foreach(@layers);
	
	return @layers;
}

1;
