
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for AOI files creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Scheme::SchemeFrame::SchemeFrame;

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
	$self->{"step"}  = "panel";

	return $self;
}

# Test if  pattern frame
sub ExistFrame {
	my $self      = shift;
	my $lName     = shift;
	my $frameName = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	CamLayer->WorkLayer( $inCAM, $lName );    # select tmp

	# select old frame and delete
	my $count = CamFilter->SelectBySingleAtt( $inCAM, $jobId, $frameName, "" );

	# clear layers
	$inCAM->COM( 'affected_layer', mode => 'all', affected => 'no' );
	$inCAM->COM('clear_layers');

	if ($count) {
		return 1;
	}
	else {
		return 0;
	}
}

# Add pattern frame
sub DeleteFrame {
	my $self      = shift;
	my $lName     = shift;
	my $frameName = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	CamLayer->WorkLayer( $inCAM, $lName );    # select tmp

	# select old frame and delete
	my $count = CamFilter->SelectBySingleAtt( $inCAM, $jobId, $frameName, "" );
	if ($count) {
		$inCAM->COM("sel_delete");
	}

	# clear layers
	$inCAM->COM( 'affected_layer', mode => 'all', affected => 'no' );
	$inCAM->COM('clear_layers');

}

# Add pattern frame
sub AddFrame {
	my $self      = shift;
	my $lName     = shift;
	my $frameName = shift;    # frame features will be signed by this name
	my $schema    = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $lExist = CamHelper->LayerExists( $inCAM, $self->{"jobId"}, $lName );

	unless ($lExist) {
		return 0;
	}

	CamLayer->WorkLayer( $inCAM, $lName );    # select layer and copy to help layer

	#my $lTmp = GeneralHelper->GetGUID();
	#$inCAM->COM( "merge_layers", "source_layer" => $lName, "dest_layer" => $lTmp );

	#CamLayer->WorkLayer($inCAM, $lTmp);  # select tmp

	# 1) Set indicator, which mark all actual szmbol in layer
	CamAttributes->SetFeatuesAttribute( $inCAM, ".string", "signed" );

	# 2) Place pattern schema to layer

	# Set attrinute to layer, schema will be placed to layer which has this attribute
	CamAttributes->SetLayerAttribute( $inCAM, "add_schema", "yes", $jobId, $self->{"step"}, $lName );

	# put pattern frame
	$inCAM->COM( 'autopan_run_scheme', job => $jobId, panel => EnumsProducPanel->PANEL_NAME, pcb => 'o+1', scheme => $schema );

	#set $value for attribute on specific layer
	CamAttributes->SetLayerAttribute( $inCAM, "add_schema", "no", $jobId, $self->{"step"}, $lName );

	# 3) This actions, set attribute pattern_frame to new added symbols(pattern frame)
	CamLayer->WorkLayer( $inCAM, $lName );    # select layer and copy to help layer

	CamFilter->SelectBySingleAtt( $inCAM, $jobId, ".string", "signed" );
	$inCAM->COM("sel_reverse");

	CamAttributes->SetFeatuesAttribute( $inCAM, $frameName, "" );

	CamAttributes->DelFeatuesAttribute( $inCAM, ".string", "signed" );

	# clear layers
	$inCAM->COM( 'affected_layer', mode => 'all', affected => 'no' );
	$inCAM->COM('clear_layers');

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

