#-------------------------------------------------------------------------------------------#
# Description: Wrapper for operations connected with inCam features filter
# On the beginning each function, whole filter is reset, thus it is not possible use this functions
# in combination with former set filter criteria (will be reset)
# Author:SPR
#-------------------------------------------------------------------------------------------#

package CamHelpers::CamFilter;

#3th party library
use strict;
use warnings;

#loading of locale modules

#use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamAttributes';

#use aliased 'Connectors::HeliosConnector::HegMethods';
#use aliased 'Helpers::GeneralHelper';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

# include attribute and att value to filter
sub SelectByFeatureIndexes {
	my $self           = shift;
	my $inCAM          = shift;
	my $jobId          = shift;
	my $featureIndexes = shift;

	$inCAM->COM('adv_filter_reset');
	$inCAM->COM( 'filter_reset', filter_name => 'popup' );

	my @ids = @{$featureIndexes};

	# if there is too much feature ids, split it and delete rout in cycle

	my @idsPart = ();

	# each loop delete 20 edges
	for ( my $i = 0 ; $i < scalar(@ids) ; $i++ ) {

		push( @idsPart, $ids[$i] );

		if ( scalar(@idsPart) == 20 ) {

			my $str = join( "\\;", @idsPart );
			$inCAM->COM(
						 "adv_filter_set",
						 "filter_name" => "popup",
						 "active"      => "yes",
						 "indexes"     => $str,
			);

			$inCAM->COM('filter_area_strt');
			$inCAM->COM( 'filter_area_end', filter_name => 'popup', operation => 'select' );
			$inCAM->COM( 'filter_reset', filter_name => 'popup' );

			@idsPart = ();
		}
	}

	# delete rest of edges
	if ( scalar(@idsPart) ) {
		my $str = join( "\\;", @idsPart );
		$inCAM->COM(
					 "adv_filter_set",
					 "filter_name" => "popup",
					 "active"      => "yes",
					 "indexes"     => $str,
		);

		$inCAM->COM('filter_area_strt');
		$inCAM->COM( 'filter_area_end', filter_name => 'popup', operation => 'select' );
		$inCAM->COM( 'filter_reset', filter_name => 'popup' );
	}

	$inCAM->COM('get_select_count');

	return $inCAM->GetReply();

}

# Select all attributes of step in hash
# Return count of celected features
sub SelectBySingleAtt {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $att       = shift;
	my $attValue  = shift;
	my $condition = shift;

	my $polarity = shift;    # not implemented yet
	my $symbol   = shift;    # not implemented yet

	$inCAM->COM('adv_filter_reset');
	$inCAM->COM( 'filter_reset', filter_name => 'popup' );

	$self->__AddFilterAtt( $inCAM, $jobId, $att, $attValue, 0, $condition );

	#$inCAM->COM( 'set_filter_and_or_logic', filter_name => 'popup', criteria => 'inc_attr', logic => 'or' );
	$inCAM->COM('filter_area_strt');
	$inCAM->COM( 'filter_area_end', filter_name => 'popup', operation => 'select' );

	$inCAM->COM( 'filter_reset', filter_name => 'popup' );

	$inCAM->COM('get_select_count');

	return $inCAM->GetReply();
}

sub __AddFilterAtt {
	my $self       = shift;
	my $inCAM      = shift;
	my $jobId      = shift;
	my $attName    = shift;
	my $attVal     = shift;
	my $refenrence = shift;         # if set, attributes are set for reference filter
	my $condition  = shift // 1;    # some attributes can have additional condition

	unless ( defined $attName ) {
		return 0;
	}

	# decide, which type is attribute
	my %attrInfo = CamAttributes->GetAttrParamsByName( $inCAM, $jobId, $attName );

	my $min_int_val   = 0;
	my $max_int_val   = 0;
	my $min_float_val = 0;
	my $max_float_val = 0;
	my $option        = "";
	my $text          = "";

	die "Attribute ($attName) additional condition is not defined" if($condition && !defined $attVal);

	if ($condition) {

		if ( $attrInfo{"gATRtype"} eq "int" ) {

			$min_int_val = $attVal->{"min"};
			$max_int_val = $attVal->{"max"};

		}
		elsif ( $attrInfo{"gATRtype"} eq "float" ) {

			$min_float_val = $attVal->{"min"};
			$max_float_val = $attVal->{"max"};

		}
		elsif ( $attrInfo{"gATRtype"} eq "option" ) {

			$option = $attVal;

		}
		elsif ( $attrInfo{"gATRtype"} eq "text" ) {

			$text = $attVal;
		}
	}

	$inCAM->COM(
				 'set_filter_attributes',
				 filter_name => !$refenrence ? 'popup' : 'ref_select',
				 exclude_attributes => 'no',
				 condition          => $condition ? 'yes' : 'no',
				 attribute          => $attName,
				 min_int_val        => $min_int_val,
				 max_int_val        => $max_int_val,
				 min_float_val      => $min_float_val,
				 max_float_val      => $max_float_val,
				 option             => $option,
				 text               => $text
	);

}

# Select all attributes of step in hash
# Return count of celected features
sub BySymbols {
	my $self    = shift;
	my $inCAM   = shift;
	my @symbols = @{ shift(@_) };

	my $symbolStr = join( "\\;", @symbols );

	$inCAM->COM('adv_filter_reset');
	$inCAM->COM( 'filter_reset', filter_name => 'popup' );

	$inCAM->COM( "set_filter_symbols", "filter_name" => "", "exclude_symbols" => "no", "symbols" => $symbolStr );

	#$inCAM->COM( 'set_filter_and_or_logic', filter_name => 'popup', criteria => 'inc_attr', logic => 'or' );
	$inCAM->COM('filter_area_strt');
	$inCAM->COM( 'filter_area_end', filter_name => 'popup', operation => 'select' );

	$inCAM->COM('get_select_count');

	return $inCAM->GetReply();
}

# Select all features by DCode
# Return count of celected features
sub ByDCodes {
	my $self   = shift;
	my $inCAM  = shift;
	my @DCodes = @{ shift(@_) };

	my $slected = 0;

	$inCAM->COM('adv_filter_reset');
	$inCAM->COM( 'filter_reset', filter_name => 'popup' );

	foreach my $dcode (@DCodes) {

		$inCAM->COM( "set_filter_dcode", "filter_name" => "", "dcode" => $dcode );
		$inCAM->COM('filter_area_strt');
		$inCAM->COM( 'filter_area_end', filter_name => 'popup', operation => 'select' );

	}

	$inCAM->COM('get_select_count');
	$slected = $inCAM->GetReply();

	return $slected;
}

# Select features by type
sub ByTypes {
	my $self  = shift;
	my $inCAM = shift;
	my @types = @{ shift(@_) };

	my $typeStr = join( "\\;", @types );

	$inCAM->COM('adv_filter_reset');
	$inCAM->COM( 'filter_reset', filter_name => 'popup' );

	$inCAM->COM(
				 'filter_set',
				 'filter_name'  => 'popup',
				 'update_popup' => 'no',
				 'feat_types'   => $typeStr,
				 'polarity'     => "positive\;negative"
	);

	$inCAM->COM('filter_area_strt');
	$inCAM->COM( 'filter_area_end', filter_name => 'popup', operation => 'select' );

	$inCAM->COM('get_select_count');

	return $inCAM->GetReply();
}

# Select surface by area
sub BySurfaceArea {
	my $self    = shift;
	my $inCAM   = shift;
	my $minArea = shift;
	my $maxArea = shift;

	unless ($minArea) {
		$minArea = 0;
	}

	unless ($maxArea) {
		$maxArea = 0;
	}

	$inCAM->COM( "set_filter_type", "filter_name" => "", "lines" => "yes", "pads" => "yes", "surfaces" => "yes", "arcs" => "yes", "text" => "yes" );
	$inCAM->COM( "set_filter_polarity", "filter_name" => "", "positive" => "yes", "negative" => "yes" );

	$inCAM->COM('adv_filter_reset');
	$inCAM->COM('filter_area_strt');

	$inCAM->COM(
				 "adv_filter_set",
				 "filter_name"   => "popup",
				 "active"        => "yes",
				 "limit_box"     => "no",
				 "bound_box"     => "no",
				 "srf_values"    => "yes",
				 "min_islands"   => "0",
				 "max_islands"   => "0",
				 "min_holes"     => "0",
				 "max_holes"     => "0",
				 "min_edges"     => "0",
				 "max_edges"     => "0",
				 "srf_area"      => "yes",
				 "min_area"      => $minArea,
				 "max_area"      => $maxArea,
				 "mirror"        => "any",
				 "ccw_rotations" => ""
	);

	$inCAM->COM( "filter_area_end", "filter_name" => "popup", "operation" => "select" );
	return $inCAM->GetReply();

}

# Select all features which are inside boundbox
# Select all features which are smaller than square with edge = $maxWidth ande bigger than square edge = $minWidth
sub ByBoundBox {
	my $self     = shift;
	my $inCAM    = shift;
	my $minWidth = shift;
	my $maxWidth = shift;

	$inCAM->COM( 'filter_reset', filter_name => 'popup' );
	$inCAM->COM( "reset_filter_criteria", "filter_name" => "", "criteria" => "all" );
	$inCAM->COM( "set_filter_type", "filter_name" => "", "lines" => "yes", "pads" => "yes", "surfaces" => "yes", "arcs" => "yes", "text" => "yes" );
	$inCAM->COM( "set_filter_polarity", "filter_name" => "", "positive" => "yes", "negative" => "yes" );

	$inCAM->COM('adv_filter_reset');
	$inCAM->COM(
				 'adv_filter_set',
				 "filter_name"  => 'popup',
				 "update_popup" => 'yes',
				 "bound_box"    => 'yes',
				 "min_width"    => "$minWidth",
				 "max_width"    => "$maxWidth",
				 "min_length"   => '0',
				 "max_length"   => '0'
	);

	$inCAM->COM('filter_area_strt');

	$inCAM->COM(
				 'filter_area_end',
				 "layer"       => '',
				 "filter_name" => 'popup',
				 "operation"   => 'select'
	);

	return $inCAM->GetReply();

}

# Select features, based on reference layer
# Is possible do condition by feature attribute (both - layer and reference layer symbols)
sub SelectByReferenece {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $mode        = shift;    # touch, disjoint, etc..
	my $layer       = shift;
	my $att         = shift;
	my $attValue    = shift;
	my $polarity    = shift;    # if undef, polarity positive and negative
	my $refLayer    = shift;
	my $refAtt      = shift;
	my $refAttValue = shift;
	my $refPolarity = shift;

	CamLayer->WorkLayer( $inCAM, $layer );

	$inCAM->COM('adv_filter_reset');
	$inCAM->COM( 'filter_reset', filter_name => 'popup' );
	$inCAM->COM( "reset_filter_criteria", "filter_name" => "", "criteria" => "all" );

	# Set filtered layer ====================================================================
	$self->__AddFilterAtt( $inCAM, $jobId, $att, $attValue );

	$inCAM->COM(
				 'filter_set',
				 'filter_name'  => 'popup',
				 'update_popup' => 'no',
				 'feat_types'   => 'line\;pad\;surface\;arc\;text',
				 'polarity'     => !defined $polarity ? "positive\;negative" : $polarity
	);

	# Set reference layer ====================================================================

	$self->__AddFilterAtt( $inCAM, $jobId, $refAtt, $refAttValue, 1 );

	#$inCAM->COM( 'filter_area_end', filter_name => 'popup', operation => 'select' );

	$inCAM->COM(
				 'sel_ref_feat',
				 'layers'   => $refLayer,
				 'use'      => 'filter',
				 'mode'     => $mode,
				 'pads_as'  => 'shape',
				 'f_types'  => 'line\;pad\;surface\;arc\;text',
				 'polarity' => !defined $refPolarity ? "positive\;negative" : $refPolarity
	);

	return $inCAM->GetReply();

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'CamHelpers::CamFilter';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d238832+1";

	#my $step  = "mpanel_10up";

	my $result = CamFilter->SelectBySingleAtt( $inCAM, $jobId, ".pilot_hole", {"min" =>4, "max" =>4} );

	#my $self             = shift;

	print 1;

}

1;
