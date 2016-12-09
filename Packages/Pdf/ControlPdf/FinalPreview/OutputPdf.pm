
#-------------------------------------------------------------------------------------------#
# Description: TifFile - interface for signal layers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::FinalPreview::OutputPdf;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Pdf::ControlPdf::Enums';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}   = shift;
	$self->{"jobId"}   = shift;
	$self->{"pdfStep"} = shift;
	
	$self->{"outputPath"}  = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID().".pdf";

	return $self;
}

sub Output {
	my $self      = shift;
	my $layerList = shift;

	$self->__PrepareLayers($layerList);

	$self->__OutputPdf($layerList);
	
	return 1;

}

sub GetOutput{
	my $self      = shift;

	return $self->{"outputPath"};
}

sub __OutputPdf {
	my $self      = shift;
	my $layerList = shift;

	my @lNames = ();
	my @colors = ();

	foreach my $l ( $layerList->GetLayers() ) {

		push( @lNames, $l->GetOutputLayer() );
		push( @colors, $self->__ConvertColor( $l->GetColor() ) );
	}
 
	$inCAM->COM(
		'print',
		title             => '',
		layer_name        => join("\;", @lNames),
		mirrored_layers   => '',
		draw_profile      => 'no',
		drawing_per_layer => 'no',
		label_layers      => 'no',
		dest              => 'pdf_file',
		num_copies        => '1',
		dest_fname        => $self->{"outputPath"},

		paper_size => 'A4',

		#scale_to          => '0.0',
		#nx                => '1',
		#ny                => '1',
		orient => 'none',

		#paper_orient      => 'best',
		#paper_width   => 260,
		#paper_height  => 260,
		auto_tray     => 'no',
		top_margin    => '0',
		bottom_margin => '0',
		left_margin   => '0',
		right_margin  => '0',
		"x_spacing"   => '0',
		"y_spacing"   => '0',
		color1        => $colors[0],
		color2        => $colors[1],
		color3        => $colors[2],
		color4        => $colors[3],
		color5        => $colors[4],
		color6        => $colors[5],
		color7        => $colors[6]
	);
}

sub __PrepareLayers {
	my $self      = shift;
	my $layerList = shift;

	$self->__PreparePCBMAT( $layerList->GetLayerByType( Enums->Type_PCBMAT ) );
	$self->__PrepareOUTERCU( $layerList->GetLayerByType( Enums->Type_OUTERCU ) );
	$self->__PrepareMASK( $layerList->GetLayerByType( Enums->Type_MASK ) );
	$self->__PrepareSILK( $layerList->GetLayerByType( Enums->Type_SILK ) );
	$self->__PreparePLTDEPTHNC( $layerList->GetLayerByType( Enums->Type_PLTDEPTHNC ) );
	$self->__PrepareNPLTDEPTHNC( $layerList->GetLayerByType( Enums->Type_NPLTDEPTHNC ) );
	$self->__PrepareTHROUGHNC( $layerList->GetLayerByType( Enums->Type_THROUGHNC ) );

}

# Create layer and fill profile - simulate pcb material
sub __PreparePCBMAT {
	my $self  = shift;
	my $layer = shift;

	my $inCAM = $self->{"inCAM"};
	my $lName = GeneralHelper->GetGUID();

	$inCAM->COM( 'create_layer', layer => $lName, context => 'misc', type => 'document', polarity => 'positive', ins_layer => '' );

	$inCAM->COM(
				 "sr_fill",
				 "type"          => "solid",
				 "solid_type"    => "surface",
				 "min_brush"     => "25.4",
				 "cut_prims"     => "no",
				 "polarity"      => "positive",
				 "consider_rout" => "no",
				 "dest"          => "layer_name",
				 "layer"         => $lName,
				 "stop_at_steps" => ""
	);

	$layer->SetOutputLayer($lName);
}

# Dont do nothing and export cu layer as is
sub __PrepareOUTERCU {
	my $self  = shift;
	my $layer = shift;

	my @layers = $layer->GetSingleLayers();

	if ( $layers[0] ) {

		$layer->SetOutputLayer( $layers[0]->{"gROWname"} );
	}
}

# Invert solder mask
sub __PrepareMASK {
	my $self  = shift;
	my $layer = shift;

	my $inCAM  = $self->{"inCAM"};
	my @layers = $layer->GetSingleLayers();

	if ( $layers[0] ) {
		my $lName = GeneralHelper->GetGUID();

		my $maskLayer = $layers[0]->{"gROWname"};

		# Select layer as work

		CamLayer->WorkLayer( $inCAM, $maskLayer );

		$inCAM->COM( "merge_layers", "source_layer" => $maskLayer, "dest_layer" => $lName );

		CamLayer->WorkLayer( $inCAM, $lName );

		my %lim = CamJob->GetProfileLimits( $self->{"inCAM"}, $self->{"jobId"}, $self->{"pdfStep"} );

		%lim{"xMin"} = %lim{"xmin"};
		%lim{"xMax"} = %lim{"xmax"};
		%lim{"yMin"} = %lim{"ymin"};
		%lim{"yMax"} = %lim{"ymax"};

		CamLayer->NegativeLayerData( $self->{"inCAM"}, $lName, \%lim );

		$layer->SetOutputLayer($lName);
	}
}

# Dont do nothing and export silk as is
sub __PrepareSILK {
	my $self  = shift;
	my $layer = shift;

	my @layers = $layer->GetSingleLayers();

	if ( $layers[0] ) {

		$layer->SetOutputLayer( $layers[0]->{"gROWname"} );
	}
}

# Compensate this layer and resize about 100µm (plating)
sub __PreparePLTDEPTHNC {
	my $self  = shift;
	my $layer = shift;

	my $inCAM  = $self->{"inCAM"};
	my @layers = $layer->GetSingleLayers();
	my $lName  = GeneralHelper->GetGUID();

	$inCAM->COM( 'create_layer', layer => $lName, context => 'misc', type => 'document', polarity => 'positive', ins_layer => '' );

	# compensate
	foreach my $l (@layers) {

		if ( $l->{"layer_type"} eq "rout" ) {
			CamLayer->WorkLayer( $inCAM, $l->{"gROWname"} );
			my $lComp = CamLayer->RoutCompensation( $inCAM, $l->{"gROWname"} );
			$inCAM->COM( "merge_layers", "source_layer" => $lComp, "dest_layer" => $lName );
		}
		else {

			$inCAM->COM( "merge_layers", "source_layer" => $l->{"gROWname"}, "dest_layer" => $lName );
		}

	}

	# resize
	CamLayer->WorkLayer( $inCAM, $lName );
	$inCAM->COM( "sel_resize", "size" => -100, "corner_ctl" => "no" );

	$layer->SetOutputLayer($lName);

}

# Compensate this layer and resize about 100µm (plating)
sub __PrepareNPLTDEPTHNC {
	my $self  = shift;
	my $layer = shift;

	my $inCAM  = $self->{"inCAM"};
	my @layers = $layer->GetSingleLayers();
	my $lName  = GeneralHelper->GetGUID();

	$inCAM->COM( 'create_layer', layer => $lName, context => 'misc', type => 'document', polarity => 'positive', ins_layer => '' );

	# compensate
	foreach my $l (@layers) {

		if ( $l->{"layer_type"} eq "rout" ) {
			CamLayer->WorkLayer( $inCAM, $l->{"gROWname"} );
			my $lComp = CamLayer->RoutCompensation( $inCAM, $l->{"gROWname"} );
			$inCAM->COM( "merge_layers", "source_layer" => $lComp, "dest_layer" => $lName );
		}
		else {

			$inCAM->COM( "merge_layers", "source_layer" => $l->{"gROWname"}, "dest_layer" => $lName );
		}
	}

	$layer->SetOutputLayer($lName);

}

# Compensate this layer and resize about 100µm (plating)
sub __PrepareTHROUGHNC {
	my $self  = shift;
	my $layer = shift;

	my $inCAM  = $self->{"inCAM"};
	my @layers = $layer->GetSingleLayers();
	my $lName  = GeneralHelper->GetGUID();

	$inCAM->COM( 'create_layer', layer => $lName, context => 'misc', type => 'document', polarity => 'positive', ins_layer => '' );

	# compensate
	foreach my $l (@layers) {

		if ( $l->{"layer_type"} eq "rout" ) {

			CamLayer->WorkLayer( $inCAM, $l->{"gROWname"} );
			my $lComp = CamLayer->RoutCompensation( $inCAM, $l->{"gROWname"} );

			#			# if plated -> resiye -100µm
			#			if($l->{"type"} ){
			#				CamLayer->WorkLayer( $inCAM, $lComp );
			#				$inCAM->COM( "sel_resize", "size" => -100, "corner_ctl" => "no" );
			#			}
			#

			$inCAM->COM( "merge_layers", "source_layer" => $lComp, "dest_layer" => $lName );

		}
		else {

			$inCAM->COM( "merge_layers", "source_layer" => $l->{"gROWname"}, "dest_layer" => $lName );
		}

	}

	$layer->SetOutputLayer($lName);

}

sub __ConvertColor {
	my $self   = shift;
	my $rgbStr = shift;

	my @rgb = split( ","$rgbStr );

	my $clr = sprintf( "%02d", ( 99 * $rgb[0] ) / 255 ) . sprintf( "%02d", ( 99 * $rgb[1] ) / 255 ) . sprintf( "%02d", ( 99 * $rgb[2] ) / 255 );

	return $clr;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

