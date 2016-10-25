
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for AOI files creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::PreExport::LayerInvert;

#3th party library
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamHelper';
use aliased 'Enums::EnumsProducPanel';
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamFilter';
use aliased 'CamHelpers::CamAttributes';
#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	return $self;
}



# Add pattern frame
sub ExistPatternFrame {
	my $self  = shift;
	my $lName = shift;
	
	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	
	

	CamLayer->WorkLayer($inCAM, $lName);  # select tmp
 
	# select old frame and delete
	my $count = CamFilter->SelectBySingleAtt($inCAM, ".string", "pattern_frame");
	
	if($count){
		return 1;
	}else{
		return 0;
	}	
}

# Add pattern frame
sub DelPatternFrame {
	my $self  = shift;
	my $lName = shift;
	
	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	
	
	CamLayer->WorkLayer($inCAM, $lName);  # select tmp
 
	# select old frame and delete
	my $count = CamFilter->SelectBySingleAtt($inCAM, ".string", "pattern_frame");
	if($count){
		$inCAM->COM("sel_delete");	
	}
	
}


# Add pattern frame
sub AddPatternFrame {
	my $self  = shift;
	my $lName = shift;
	my $schema = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $lExist = CamHelper->LayerExists( $inCAM, $self->{"jobId"}, $lName );

	unless ($lExist) {
		return 0;
	}
	
 
	CamLayer->WorkLayer($inCAM, $lName);  # select layer and copy to help layer
	
	#my $lTmp = GeneralHelper->GetGUID();
	#$inCAM->COM( "merge_layers", "source_layer" => $lName, "dest_layer" => $lTmp );
	
	#CamLayer->WorkLayer($inCAM, $lTmp);  # select tmp
	
	# Set indicator for later delete
	CamAttributes->SetFeatuesAttribute($inCAM, ".string", "signed");
	
	
	# put pattern frame
	$inCAM->COM ('autopan_run_scheme',job=>$jobId, panel=>EnumsProducPanel->PANEL_NAME,pcb=>'o+1',scheme=>$schema);
	
 
	CamFilter->SelectBySingleAtt($inCAM, ".string", "signed");
	$inCAM->COM("sel_reverse");
	
	CamAttributes->SetFeatuesAttribute($inCAM, ".string", "pattern_frame");
	
	CamAttributes->DelFeatuesAttribute($inCAM, ".string", "signed");
	
	 
#	
#	$inCAM->COM("sel_delete");
#	
#	# Set indicator, this is pattern frame
#	CamAttributes->SetFeatuesAttribute($inCAM, ".string", "pattern_frame");
#	
#	$inCAM->COM( "merge_layers", "source_layer" => $lTmp, "dest_layer" => $lName );
#	
#	# clear affected layers
#	$inCAM->COM( 'affected_layer', name => "", mode => "all", affected => "no" );
#	$inCAM->COM('clear_layers');
#	
# 
 
}


# Changes layer mark polarity
sub ChangeMarkPolarity {
	my $self  = shift;
	my $lName = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $lExist = CamHelper->LayerExists( $inCAM, $self->{"jobId"}, $lName );

	unless ($lExist) {

		return 0;
	}

	$inCAM->COM('clear_layers');
	$inCAM->COM( 'filter_reset', filter_name => 'popup' );

	CamLayer->WorkLayer( $inCAM, $lName );

	$self->__AddFilterAtt(  '.geometry', 'centre*' );
	$self->__AddFilterAtt(  '.geometry', 'OLEC*' );
	$self->__AddFilterAtt(  '.geometry', 'punch*' );

	$inCAM->COM( 'set_filter_and_or_logic', filter_name => 'popup', criteria => 'inc_attr', logic => 'or' );
	$inCAM->COM('filter_area_strt');
	$inCAM->COM( 'filter_area_end', filter_name => 'popup', operation => 'select' );
	$inCAM->COM('get_select_count');
	if ( $inCAM->GetReply() > 0 ) {
		$inCAM->COM('sel_invert');
	}
	$inCAM->COM( 'display_layer', name => $lName, display => 'no', number => '1' );
	$inCAM->COM( 'filter_reset', filter_name => 'popup' );
	$inCAM->COM( 'affected_layer', mode => 'all', affected => 'no' );
	$inCAM->COM('clear_layers');

}

sub __AddFilterAtt {
	my $self    = shift;
	my $attName = shift;
	my $attVal  = shift;

	$self->{"inCAM"}->COM(
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

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Packages::Export::PlotExport::PlotMngr';
	#
	#	use aliased 'Packages::InCAM::InCAM';
	#
	#	my $inCAM = InCAM->new();
	#
	#	my $jobId = "f13609";
	#
	#	my @layers = CamJob->GetBoardBaseLayers( $inCAM, $jobId );
	#
	#	foreach my $l (@layers) {
	#
	#		$l->{"polarity"} = "positive";
	#
	#		if ( $l->{"gROWname"} =~ /pc/ ) {
	#			$l->{"polarity"} = "negative";
	#		}
	#
	#		$l->{"mirror"} = 0;
	#		if ( $l->{"gROWname"} =~ /c/ ) {
	#			$l->{"mirror"} = 1;
	#		}
	#
	#		$l->{"compensation"} = 30;
	#		$l->{"name"}         = $l->{"gROWname"};
	#	}
	#
	#	@layers = grep { $_->{"name"} =~ /p[cs]/ } @layers;
	#
	#	my $mngr = PlotMngr->new( $inCAM, $jobId, \@layers );
	#	$mngr->Run();
}

1;

