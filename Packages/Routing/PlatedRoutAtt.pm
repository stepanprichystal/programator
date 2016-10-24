#-------------------------------------------------------------------------------------------#
# Description: Contain special function, which work with routing
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::PlatedRoutAtt;

#3th party library
use strict;
use warnings;
use Math::Polygon;
use List::Util qw[max];

#local library

use aliased 'CamHelpers::CamHelper';

use aliased 'CamHelpers::CamDrilling';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamStep';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

# 1) Add attribute plated rout area to step o,o+1 to all plated rout layers
# 2) Delete smd attributes from pads, where is plated rout
sub SetRoutPlated {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;

	my @steps = CamStep->GetAllStepNames( $inCAM, $jobId );

	my $o1Exist = scalar( grep { $_ =~ /o+1/ } @steps );

	unless ( !( scalar(@steps) > 1 && $o1Exist ) ) {

		return 0;
	}

	my @res = CamDrilling->GetNCLayersByType( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_plt_nMill );


	foreach my $layer (@res) {

		#CamHelper->SetStep( $inCAM, $jobId, $steps[0] );
		$self->SetRoutPlatedByStep( $inCAM, $jobId, $steps[0], $layer->{"gROWname"} );

		#CamHelper->SetStep( $inCAM, $jobId, "o+1" );
		$self->SetRoutPlatedByStep( $inCAM, $jobId, "o+1", $layer->{"gROWname"} );

		$self->DeleteSmdWhereRoutPlated( $inCAM, $jobId, $layer->{"gROWname"} )

	}

}

#Set atributte "plated rout" to all shape in "r" layer
# and delete SMD attribute under route plated pads
sub SetRoutPlatedByStep {

	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $stepName  = shift;
	my $layerName = shift;

	#set rout plated attribute to all shape in layer "R"

	CamHelper->SetStep( $inCAM, $stepName );

	$inCAM->COM( 'affected_layer', 'affected' => 'no', 'mode' => 'all' );
	$inCAM->COM(
				 'display_layer',
				 'name'    => $layerName,
				 'display' => 'yes',
				 'number'  => '1'
	);
	$inCAM->COM( 'work_layer', 'name' => $layerName );
	$inCAM->COM('cur_atr_reset');
	$inCAM->COM( 'cur_atr_set',    'attribute' => '.rout_plated' );
	$inCAM->COM( 'sel_change_atr', 'mode'      => 'add' );
	$inCAM->COM('sel_clear_feat');
	$inCAM->COM('cur_atr_reset');
	$inCAM->COM( 'affected_layer', 'affected' => 'no', 'mode' => 'all' );

}

#Delete SMD attribute where is plated rout
sub DeleteSmdWhereRoutPlated {
	my $self       = shift;
	my $inCAM      = shift;
	my $jobId      = shift;
	my $layerName  = shift;
	my $secondStep = 'o+1';

	CamHelper->SetStep( $inCAM, $secondStep );

	$inCAM->COM( 'affected_layer', 'affected' => 'no', 'mode' => 'all' );
	$inCAM->COM(
				 'display_layer',
				 'name'    => 'c',
				 'display' => 'yes',
				 'number'  => '1'
	);
	$inCAM->COM( 'work_layer', 'name' => 'c' );

	$inCAM->INFO(
				  entity_type => 'layer',
				  entity_path => "$jobId/o+1/s",
				  data_type   => 'exists'
	);
	if ( $inCAM->{doinfo}{gEXISTS} eq "yes" ) {
		$inCAM->COM(
					 'affected_layer',
					 'name'     => 's',
					 'mode'     => 'single',
					 'affected' => 'yes'
		);
	}
	$inCAM->COM( 'filter_reset', 'filter_name' => 'popup' );
	$inCAM->COM(
				 'filter_set',
				 'filter_name'  => 'popup',
				 'update_popup' => 'no',
				 'feat_types'   => 'pad',
				 'polarity'     => 'positive'
	);

	$inCAM->COM(
				 'sel_ref_feat',
				 'layers'   => $layerName,
				 'use'      => 'filter',
				 'mode'     => 'touch',
				 'pads_as'  => 'shape',
				 'f_types'  => 'line\;pad\;surface\;arc\;text',
				 'polarity' => 'positive'
	);
	$inCAM->COM( 'sel_delete_atr', 'attributes'  => '.smd' );
	$inCAM->COM( 'filter_reset',   'filter_name' => 'popup' );
	$inCAM->COM( 'affected_layer', 'affected'    => 'no', 'mode' => 'all' );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {


	


}

1;
