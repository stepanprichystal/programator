#-------------------------------------------------------------------------------------------#
# Description: Wrapper for operations connected with inCam features filter
# Author:SPR
#-------------------------------------------------------------------------------------------#

package CamHelpers::CamFilter;

#3th party library
use strict;
use warnings;

#loading of locale modules

#use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamHelper';
#use aliased 'CamHelpers::CamJob';
#use aliased 'CamHelpers::CamCopperArea';
#use aliased 'Connectors::HeliosConnector::HegMethods';
#use aliased 'Helpers::GeneralHelper';


#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#
 
# Select all attributes of step in hash
# Return count of celected features
sub SelectBySingleAtt {
	my $self  = shift;
	my $inCAM = shift;
	my $att = shift;
	my $attValue = shift;
	
	my $polarity = shift; # not implemented yet
	my $symbol = shift;  # not implemented yet
	
	 
	$inCAM->COM( 'filter_reset', filter_name => 'popup' );
 
	$self->__AddFilterAtt($inCAM,  $att, $attValue );
 
	#$inCAM->COM( 'set_filter_and_or_logic', filter_name => 'popup', criteria => 'inc_attr', logic => 'or' );
	$inCAM->COM('filter_area_strt');
	$inCAM->COM( 'filter_area_end', filter_name => 'popup', operation => 'select' );
	
	
	
	$inCAM->COM( 'filter_reset', filter_name => 'popup' );
	
	$inCAM->COM('get_select_count');
	
	return $inCAM->GetReply()
}
 

sub __AddFilterAtt {
	my $self    = shift;
	my $inCAM = shift;
	my $attName = shift;
	my $attVal  = shift;

	$inCAM->COM(
				 'set_filter_attributes',
				 filter_name        => 'popup',
				 exclude_attributes => 'no',
				 condition          => 'yes',
				 attribute          => $attName,
				 min_int_val        => 0,
				 max_int_val        => 0,
				 min_float_val      => 0,
				 max_float_val      => 0,
				 option             => '',
				 text               => $attVal
	);

}


# Select all attributes of step in hash
# Return count of celected features
sub BySingleSymbol {
	my $self  = shift;
	my $inCAM = shift;
	my $symbol = shift;
 
	
	 
	$inCAM->COM( 'filter_reset', filter_name => 'popup' );
	
 	$inCAM->COM("set_filter_symbols","filter_name" => "","exclude_symbols" => "no","symbols" => $symbol);
	 
	#$inCAM->COM( 'set_filter_and_or_logic', filter_name => 'popup', criteria => 'inc_attr', logic => 'or' );
	$inCAM->COM('filter_area_strt');
	$inCAM->COM( 'filter_area_end', filter_name => 'popup', operation => 'select' );
	

	
	 
	
	$inCAM->COM('get_select_count');
	
	return $inCAM->GetReply()
}
 
 
 
sub BySurfaceArea {
	my $self  = shift;
	my $inCAM = shift;
	my $minArea = shift; 
	my $maxArea = shift; 
	
	
	unless($minArea){
		$minArea = 0;
	}
	
	unless($maxArea){
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
	return  $inCAM->GetReply();
	
}
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) { 
 
 		use aliased 'CamHelpers::CamFilter';
	use aliased 'Packages::InCAM::InCAM';

		my $inCAM = InCAM->new();
		my $jobId = "f52457";
	#my $step  = "mpanel_10up";

	my $result = CamFilter->BySingleSymbol( $inCAM,  "r4000" );

	#my $self             = shift;
	
}

1;
