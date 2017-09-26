
#-------------------------------------------------------------------------------------------#
# Description: Prepare stencil layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::StencilCreator::Helpers::Output;

#3th party library
use threads;
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Programs::StencilCreator::Helpers::DataHelper';
use aliased 'Programs::StencilCreator::Enums';
use aliased 'Helpers::CamHelpers';
use aliased 'CamHelpers::CamStepRepeat';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}       = shift;
	$self->{"jobId"}       = shift;
	$self->{"dataMngr"}    = shift;
	$self->{"stencilMngr"} = shift;
	
	# PROPERTIES
	$self->{"stencilStep"} = "o+1_";

	return $self;
}

sub PrepareLayer {
	my $self      = shift;
	my $layerList = shift;

	my %layers = $self->__PrepareOriLayers();
	
	#
	$self->__PrepareFinalLayer(\%layers);
	
}

# Prepare source paste layers in ori step
sub __PrepareOriLayers {
	my $self = shift;

	my $inCAM       = $self->{"inCAM"};
	my $jobId       = $self->{"jobId"};
	my $dataMngr    = $self->{"dataMngr"};
	my $stencilMngr = $self->{"stencilMngr"};

	my $step = $self->{"dataMngr"}->GetStencilStep();
	CamHelpers->SetStep( $self->{"inCAM"}, $sourceStep );
	my $srExist = CamStepRepeat->ExistStepAndRepeats( $inCAM, $jobId, $step );

	my %layers = ();

	if ( $dataMngr->GetStencilType() eq Enums->StencilType_TOP ) {

		my %inf = ( "ori" => DataHelper->GetStencilOriLayer( $inCAM, $jobId, "top" ), "prepared" => GeneralHelper->GetGUID() );
		$layers{"top"} = \%inf;

	}
	elsif ( $dataMngr->GetStencilType() eq Enums->StencilType_BOT ) {

		my %inf = ( "ori" => DataHelper->GetStencilOriLayer( $inCAM, $jobId, "bot" ), "prepared" => GeneralHelper->GetGUID() );
		$layers{"bot"} = \%inf;
	}
	elsif ( $dataMngr->GetStencilType() eq Enums->StencilType_TOPBOT ) {

		my %inf = ( "ori" => DataHelper->GetStencilOriLayer( $inCAM, $jobId, "top" ), "prepared" => GeneralHelper->GetGUID() );
		$layers{"top"} = \%inf;
		my %inf2 = ( "ori" => DataHelper->GetStencilOriLayer( $inCAM, $jobId, "bot" ), "prepared" => GeneralHelper->GetGUID() );
		$layers{"bot"} = \%inf2;
	}

	# prepare

	foreach my $lType ( keys %layers ) {

		my $oriLayer = $layers{$lType}->{"ori"};
		my $prepared = $layers{$lType}->{"prepared"};

		my $pcbProf = $lType eq "top" ? $stencilMngr->GetTopProfile() : $stencilMngr->GetBotProfile();

		# 1) flatten layer in needed
		if ($srExist) {
			$inCAM->COM( 'flatten_layer', "source_layer" => $oriLayer, "target_layer" => $prepared );

		}
		else {

			# only copy to targer layer
			$inCAM->COM( "merge_layers", "source_layer" => $oriLayer, "dest_layer" => $prepared );
		}

		# 2) Move to zero, test if left down corner is in zero
		CamLayer->WorkLayer( $inCAM, $prepared );

		my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $step, 1 );

		if ( int( $lim{"xMin"} ) != 0 || int( $lim{"yMin"} ) != 0 ) {

			# move to zero
			$inCAM->COM(
						 "sel_transform",
						 "oper"      => "",
						 "x_anchor"  => "0",
						 "y_anchor"  => "0",
						 "angle"     => "0",
						 "direction" => "ccw",
						 "x_scale"   => "1",
						 "y_scale"   => "1",
						 "x_offset"  => -$lim{"xMin"},
						 "y_offset"  => -$lim{"yMin"},
						 "mode"      => "anchor",
						 "duplicate" => "no"
			);

		}

		# 3) mirror layer by y axis profile
		if ( $dataMngr->GetStencilType() eq Enums->StencilType_TOPBOT && $lType eq "bot" ) {

			CamLayer->MirrorLayerByProfCenter( $inCAM, $jobId, $step, $prepared, "y" );
		}

		# 4) Rotate data 90° CW
		if ( $pcbProf->GetIsRotated() ) {

			CamLayer->RotateLayerData( $inCAM, $prepared, 270 );    # rotated about left-down corner CCW
			my %source = ( "x" => 0, "y" => 0 );
			my %target = ( "x" => 0, "y" => $pcbProf->GetHeight() );    # move to zero again
			CamLayer->MoveLayerData( $inCAM, $prepared, \%source, \%target );
		}

	}

	return %layers;

}

# Create final stencil layer intended for export
sub __PrepareFinalLayer {
	my $self = shift;
	my %layers = %{shift(@_)};

	my $inCAM       = $self->{"inCAM"};
	my $jobId       = $self->{"jobId"};
	my $dataMngr    = $self->{"dataMngr"};
	my $stencilMngr = $self->{"stencilMngr"};
	
	
 foreach my $lType ( keys %layers ) {

		my $oriLayer = $layers{$lType}->{"ori"};
		my $prepared = $layers{$lType}->{"prepared"};
	 
		# copy to final step
		$self->{"stencilStep"}
	copy_layer
	
		$inCAM->COM(
				 "sel_copy_other",
				 "dest"         => "layer_name",
				 "target_layer" => $layerStr,
				 "invert"       => $invert ? "yes" : "no",
				 "dx"           => "0",
				 "dy"           => "0",
				 "size"         => $resize ? $resize : 0,
				 "x_anchor"     => "0",
				 "y_anchor"     => "0 "
	);
 
}


sub __PrepareSchema{
	
	
	
}

sub __PcbNumber{
	
	
	
}


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
