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
use aliased 'Packages::Stackup::StackupOperation';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

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
	my $mode        = shift // "replace";    # replace / append / duplicate

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
sub GetAffectedLayers {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	$inCAM->COM("get_affect_layer");

	my @layers = split( " ", $inCAM->GetReply() );

	$_ =~ s/\s//g foreach (@layers);

	return @layers;
}

# Return current work layer
sub GetWorkLayer {
	my $self  = shift;
	my $inCAM = shift;

	$inCAM->COM("get_work_layer");

	my $workLayer = $inCAM->GetReply();

	if ( $workLayer eq "" ) {
		return undef;
	}
	else {
		return $workLayer;
	}
}

# Return layer type
sub GetLayerType {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $layer = shift;

	my $l = ( grep { $_->{"gROWname"} eq $layer } CamJob->GetAllLayers( $inCAM, $jobId ) )[0];

	return $l->{"gROWlayer_type"};
}

# Return layer type
sub SetNCLayerStartEnd {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $layer = shift;
	my $start = shift;    # start layer name
	my $end   = shift;    # end layer name

	$inCAM->COM( "matrix_layer_drill", "job" => $jobId, "matrix" => "matrix", "layer" => $layer, "start" => $start, "end" => $end );

}

# Return which phzsic side is special non signal layer oriented
# if wee look through form top to bot
# Layer name must be in format: <layer name><signal layer name> E.g.: coverlays; stiffc etc..
# Return value: top/bot
sub GetNonSignalLayerSide {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $layerName = shift;
	my $stackup   = shift;
	my $sigRef = shift;
	
	my $sigL = ( $layerName =~ /^\w+([csv]\d*)$/ )[0];

	die "reference signal layer was not recognized from non signal layer: $layerName" if ( !defined $sigL );

	my $side = undef;

	if ( $sigL eq "c" ) {
		$side = "top";
	}
	elsif ( $sigL eq "s" ) {

		$side = "bot";
	}
	else {

		$side = StackupOperation->GetSideByLayer( $inCAM, $jobId, $sigL, $stackup );
	
	}
	
	$$sigRef = $sigL if(defined $sigRef);
	
	return $side;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	  use aliased 'CamHelpers::CamMatrix';
	  use aliased 'Packages::InCAM::InCAM';

	  my $inCAM = InCAM->new();

	  my $jobId    = "f13608";
	  my $stepName = "panel";

	  my $workLayer = CamMatrix->GetWorkLayer($inCAM);
	  die;

}

1;
