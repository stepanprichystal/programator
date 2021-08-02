#-------------------------------------------------------------------------------------------#
# Description: Helper class, contains helper function for matrix, layers etc
# Author: SPR
#-------------------------------------------------------------------------------------------#

package CamHelpers::CamMatrix;

#3th party library
use strict;
use warnings;
use List::Util qw(first);

#loading of locale modules
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::Stackup::StackupOperation';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

# Duplicate layer
# Do not copy lazer data in step and repeat steps
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

# Duplicate layer
# Copy layer data in step and repeat steps
sub DuplicateLayer {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $sourceLayer = shift;
	my $targetLayer = shift;

	die "Layer $sourceLayer already exist" if ( CamHelper->LayerExists( $inCAM, $jobId, $targetLayer ) );

	my @all = CamJob->GetAllLayers( $inCAM, $jobId );
	my @alreadyDupl = grep { $_ =~ /$sourceLayer\+\d+$/ } map { $_->{"gROWname"} } @all;

	my $maxIdx = undef;
	for ( my $i = 0 ; $i < scalar(@alreadyDupl) ; $i++ ) {

		my $curIdx = ( $alreadyDupl[$i] =~ m/(\d+)$/ )[0];
		$maxIdx = $curIdx if ( !defined $maxIdx || $maxIdx < $curIdx );
	}

	# new name
	my $duplName = $sourceLayer . "+";
	if ( defined $maxIdx ) {

		for ( my $i = 1 ; $i <= $maxIdx + 1 ; $i++ ) {

			my $exist = first { $_ eq $sourceLayer . "+$i"; } map { $_->{"gROWname"} } @all;

			unless ($exist) {
				$duplName .= "$i";
				last;
			}
		}
	}
	else {

		$duplName .= "1";
	}

	my $matrixL = first { $_->{"gROWname"} eq $sourceLayer } CamJob->GetAllLayers( $inCAM, $jobId );

	$inCAM->COM(
		'matrix_copy_row',
		"job"     => $jobId,
		"matrix"  => "matrix",
		"row"     => $matrixL->{"gROWrow"},
		"ins_row" => $matrixL->{"gROWrow"},

	);

	# Rename generated laye to required layer

	$self->RenameLayer( $inCAM, $jobId, $duplName, $targetLayer );

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

# Rename matric layer
sub RenameLayer {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $layerOld = shift;    # old layter name
	my $layerNew = shift;    # new layer name

	$inCAM->COM( 'matrix_rename_layer', "job" => $jobId, "matrix" => "matrix", "layer" => $layerOld, "new_name" => $layerNew );
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

# Return layer direction
# return top2bot, bot2top
sub GetLayerDirection {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $layer = shift;

	$inCAM->INFO(
				  units           => 'mm',
				  angle_direction => 'ccw',
				  entity_type     => 'matrix',
				  entity_path     => "$jobId/matrix",
				  data_type       => 'ROW',
				  parameters      => "drl_dir+name"
	);

	my $dir = undef;

	for ( my $i = 0 ; $i < scalar( @{ $inCAM->{doinfo}{gROWname} } ) ; $i++ ) {
		my %info = ();
		if ( ${ $inCAM->{doinfo}{gROWname} }[$i] eq $layer ) {

			$dir = ${ $inCAM->{doinfo}{gROWdrl_dir} }[$i];
			last;
		}
	}

	return $dir;
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

# Return array of displayed layers
sub GetDisplayedLayers {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	$inCAM->COM("get_disp_layers");

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
	my $sigRef    = shift;

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

	$$sigRef = $sigL if ( defined $sigRef );

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

	my $jobId    = "d317363";
	my $stepName = "panel";

	my $workLayer = CamMatrix->DuplicateLayer( $inCAM, $jobId, "c", "t" );
	die;

}

1;
