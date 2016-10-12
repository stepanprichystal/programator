#-------------------------------------------------------------------------------------------#
# Description: Wrapper for operations connected with inCam attributes
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Packages::Export::PlotExport::OpfxCreator::OpfxCreator;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::JobHelper';
use aliased 'Packages::Export::PlotExport::Enums';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamHelper';
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamJob';
use File::Copy;

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;    #board layers

	$self->{"plotStep"} = "plot_export";

	my @plotSets = ();
	$self->{"plotSets"} = \@plotSets;

	return $self;
}

sub AddPlotSet {
	my $self    = shift;
	my $plotSet = shift;

	push( @{ $self->{"plotSets"} }, $plotSet );

}

sub Export {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# Create plot step
	$self->__CreatePlotStep();

	# Export single plot sets

	foreach my $plotSet ( @{ $self->{"plotSets"} } ) {

		# Select layer by layer
		foreach my $plotL ( $plotSet->GetLayers() ) {

			# Prepare final layer for output on film
			$self->__PrepareLayer( $plotSet, $plotL );
		}

		# Prepare (merge if more layers) final layer for plotter set
		$self->__PrepareOutputLayer($plotSet);

	}

	# Final output of prepared plot sets
	$self->__OutputPlotSets();

}

# 1) Flattern layer
# 2) Rotate, mirror, compensate
# 3) Return name of new layer
sub __PrepareLayer {
	my $self      = shift;
	my $plotSet   = shift;
	my $plotLayer = shift;

	my $inCAM = $self->{"inCAM"};

	my $lName = GeneralHelper->GetGUID();
	$plotLayer->{"outputLayer"} = $lName;

	$inCAM->COM( 'flatten_layer', "source_layer" => $plotLayer->GetName(), "target_layer" => $lName );

	# Select pom layer as work
	CamLayer->WorkLayer( $inCAM, $lName );

	# Remove frame

	CamLayer->ClipLayerData( $inCAM, $lName, $plotLayer->GetLimits() );

	# Compensate layer
	if ( $plotLayer->GetComp() > 0 ) {

		CamLayer->CompensateLayerData( $inCAM, $lName, $plotLayer->GetComp() );
	}

	# Rotate layer
	if ( $plotSet->GetOrientation() eq Enums->Ori_HORIZONTAL ) {

		CamLayer->RotateLayerData( $inCAM, $lName, 90 );
	}

	# Mirror layer
	if ( $plotLayer->Mirror() ) {

		CamLayer->MirrorLayerData( $inCAM, $lName, "y" );
	}

}

# Create special layer, which will be outputed
# Merge all another layer into
sub __PrepareOutputLayer {
	my $self    = shift;
	my $plotSet = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $filmSize = $plotSet->GetFilmSize();
	my $filmWidth;
	my $filmHeight;

	if ( $filmSize eq Enums->FilmSize_Small ) {

		$filmWidth  = Enums->FilmSize_SmallX;
		$filmHeight = Enums->FilmSize_SmallY;

	}
	elsif ( $filmSize eq Enums->FilmSize_Big ) {

		$filmWidth  = Enums->FilmSize_BigX;
		$filmHeight = Enums->FilmSize_BigY;
	}

	#compute start position of films
	my $startY = 0;
	my $startX = ( $filmWidth - $plotSet->GetFilmsWidth() ) / 2;

	foreach my $plotL ( $plotSet->GetLayers() ) {

		# Layer limits
		my %lLim = CamJob->GetLayerLimits( $inCAM, $jobId, $self->{"plotStep"}, $plotL->{"outputLayer"} );
		my %source = ( "x" => $lLim{"xmin"}, "y" => $lLim{"ymin"} );
		my %target = ( "x" => $startX, "y" => $startY );

		# move layer
		CamLayer->MoveLayerData( $inCAM, $plotL->{"outputLayer"}, \%source, \%target );

		# merge layer to final output layer
		$inCAM->COM( "merge_layers", "source_layer" => $plotL->{"outputLayer"}, "dest_layer" => $plotSet->GetOutputLayerName() );

		$inCAM->COM( "delete_layer", "layer" => $plotL->{"outputLayer"} );

		if ( $plotSet->GetOrientation() eq Enums->Ori_VERTICAL ) {

			$startY = 0;
			$startX += $plotL->GetWidth();

		}
		elsif ( $plotSet->GetOrientation() eq Enums->Ori_HORIZONTAL ) {

			$startY += $plotL->GetHeight();
			$startX = 0;
		}
	}
}

sub __OutputPlotSets {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $plotPanel = $self->{"plotStep"};

	my $archive    = JobHelper->GetJobArchive($jobId);
	my $output     = JobHelper->GetJobOutput($jobId);
	my $archivePath = $archive."zdroje";
	#$archivePath =~ s/\\$//; # remove last slash
	
	$inCAM->COM( "set_subsystem", "name" => "Output" );

	# Add output device
	$inCAM->COM( "output_add_device", "type" => "format", "name" => "LP7008" );

	foreach my $plotSet ( @{ $self->{"plotSets"} } ) {

		my $filmSize = $plotSet->GetFilmSizeInch();
		my $outputL  = $plotSet->GetOutputLayerName();

		# Set properly output device
		$inCAM->COM( "output_reload_device", "type" => "format", "name" => "LP7008" );


		my $name = $plotSet->GetOutputFileName();
		$inCAM->COM(
			"output_update_device",
			"type"   => "format",
			"name"   => "LP7008",
			"suffix" => "qqqq",
			"prefix" => "aaaaa",
			"dir_path" => $archivePath,
			"format_params" =>
			  "(break_sr=yes)(break_symbols=yes)(send_to_plotter=no)(local_copy=yes)(iol_opfx_allow_out_limits=yes)(iol_opfx_use_profile_limits=no)"

		);

			$inCAM->COM( "output_device_set_lyrs_filter", "type" => "format", "name" => "LP7008", "layers_filter" => $outputL );

			$inCAM->COM("output_device","type" => "format","name" => "LP7008","overwrite" => "yes","overwrite_ext" => "","on_checkout_by_other" => "output_anyway");

		$inCAM->COM(
					 "output_update_device_layer",
					 "type"       => "format",
					 "name"       => "LP7008",
					 "layer"      => $outputL,
					 "angle"      => "0",
					 "x_mirror"   => "no",
					 "y_mirror"   => "no",
					 "x_scale"    => "1",
					 "y_scale"    => "1",
					 "comp"       => "0",
					 "polarity"   => "positive",
					 "line_units" => "inch"
		);

		#		$inCAM->COM("output_update_device", "type"  => "format", "name"=> "LP7008", "suffix" => "_opfx",
		#			"format_params" => "(break_sr=yes)(break_symbols=yes)(send_to_plotter=no)
		#			(local_copy=yes)(film_size=$filmSize)(iol_surface_check=yes)
		#			(iol_opfx_use_profile_limits=no)"
		#		);



		print $inCAM->COM(
						   "output_device",
						   "type"                 => "format",
						   "name"                 => "LP7008",
						   "overwrite"            => "yes",
						   "overwrite_ext"        => "",
						   "on_checkout_by_other" => "output_anyway"
		);

		# after export, move to archive
		#copy( $output . $plotSet->GetOutputLayerName(), $archive . $plotSet->GetOutputFileName() ) or die "Copy failed: $!";
		rename( $archivePath . $plotSet->GetOutputLayerName(), $archivePath . $plotSet->GetOutputFileName() ) or die "Copy failed: $!";

	}

	# return to default subsystem
	$inCAM->COM( "set_subsystem", "name" => "1-Up-Edit" );

}

sub __CreatePlotStep {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $plotPanel = $self->{"plotStep"};

	#CamHelper->OpenJob( $inCAM, $jobId );
	# Set step panel
	$inCAM->COM( "set_step", "name" => "panel" );

	#delete if step already exist
	if ( CamHelper->StepExists( $inCAM, $jobId, $plotPanel ) ) {
		$inCAM->COM( "delete_entity", "job" => $jobId, "name" => $plotPanel, "type" => "step" );
	}

	# Copy step
	$inCAM->COM(
				 'copy_entity',
				 type             => 'step',
				 source_job       => $jobId,
				 source_name      => "panel",
				 dest_job         => $jobId,
				 dest_name        => $plotPanel,
				 dest_database    => "",
				 "remove_from_sr" => "yes"
	);

	# Set step panel ploter
	$inCAM->COM( "set_step", "name" => $plotPanel );

}

1;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#my $self             = shift;
	#	my $inCAM            = shift;

	use aliased 'HelperScripts::DirStructure';

	DirStructure->Create();

}

1;
