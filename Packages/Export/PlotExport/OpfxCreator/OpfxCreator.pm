#-------------------------------------------------------------------------------------------#
# Description: Class responsible for creation opfx files
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::PlotExport::OpfxCreator::OpfxCreator;
use base('Packages::ItemResult::ItemEventMngr');

#3th party library
use strict;
use warnings;
use File::Copy;

#local library
use aliased 'Helpers::JobHelper';
use aliased 'Packages::Export::PlotExport::Enums';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamHelper';
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
use aliased 'Packages::CAM::FeatureFilter::Enums' => "FilterEnums";
use aliased 'Helpers::FileHelper';
use aliased 'CamHelpers::CamMatrix';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $self = $class->SUPER::new(@_);
	bless $self;

	$self->{"inCAM"}         = shift;
	$self->{"jobId"}         = shift;    #board layers
	$self->{"sendToPlotter"} = shift;

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

	# Delete plot step
	if ( CamHelper->StepExists( $inCAM, $jobId, $self->{"plotStep"} ) ) {

		$inCAM->COM( "delete_entity", "job" => $jobId, "type" => "step", "name" => $self->{"plotStep"} );
	}

}

# 1) Flattern layer
# 2) Rotate, mirror, compensate
# 3) Return name of new layer
sub __PrepareLayer {
	my $self      = shift;
	my $plotSet   = shift;
	my $plotLayer = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $lName = GeneralHelper->GetGUID();
	$plotLayer->{"outputLayer"} = $lName;

	$inCAM->COM( 'flatten_layer', "source_layer" => $plotLayer->GetName(), "target_layer" => $lName );

	# Select pom layer as work
	CamLayer->WorkLayer( $inCAM, $lName );

	# 1) Do solid line, from profile to "layer limits" (limits are given by small or big frame)
	# Only mask layer
	if ( $plotLayer->GetName() =~ /m[cs]$/ ) {

		# Compute margin of filling from pcb profile
		my %pLim = CamJob->GetProfileLimits2( $inCAM, $jobId, $self->{"plotStep"} );
		my $pW   = abs( $pLim{"xMax"} - $pLim{"xMin"} );
		my $pH   = abs( $pLim{"yMax"} - $pLim{"yMin"} );

		my $marginX = abs( $pW - $plotLayer->GetWidth() );
		my $marginY = abs( $pH - $plotLayer->GetHeight() );

		# Do fill
		$inCAM->COM(
					 "sr_fill",
					 "type"            => "solid",
					 "solid_type"      => "surface",
					 "step_margin_x"   => -$marginX,
					 "step_margin_y"   => -$marginY,
					 "step_max_dist_x" => 0,
					 "step_max_dist_y" => 0,
					 "consider_feat"   => "yes",
					 "feat_margin"     => "0",
					 "dest"            => "layer_name",
					 "layer"           => $lName
		);
	}

	# 2) Find Olec marks and move them by 0.03 mm towards the nearest corner. Request by Temny
	foreach my $plnPlace ( ( "left-top", "right-top", "right-bot", "left-bot" ) ) {

		my $f = FeatureFilter->new( $inCAM, $self->{"jobId"}, $lName );
		$f->AddIncludeAtt( ".geometry",  "*olec*" );
		$f->AddIncludeAtt( ".pnl_place", "*$plnPlace*" );

		if ( $f->Select() ) {

			if ( $plnPlace eq ("left-top") ) {
				$inCAM->COM( "sel_transform", "x_offset" => -0.03, "y_offset" => 0.03, "mode" => "axis" );
			}
			elsif ( $plnPlace eq ("right-top") ) {
				$inCAM->COM( "sel_transform", "x_offset" => 0.03, "y_offset" => 0.03, "mode" => "axis" );
			}
			elsif ( $plnPlace eq ("right-bot") ) {
				$inCAM->COM( "sel_transform", "x_offset" => 0.03, "y_offset" => -0.03, "mode" => "axis" );
			}
			elsif ( $plnPlace eq ("left-bot") ) {
				$inCAM->COM( "sel_transform", "x_offset" => -0.03, "y_offset" => -0.03, "mode" => "axis" );
			}
		}
	}

	# 3) Copy all "camera" marks to separate layer. We want to avoid resizing
	my $marksSeparated = 0;    # if marks separated, store layer name

	my $f = FeatureFilter->new( $inCAM, $self->{"jobId"}, $lName );
	$f->AddIncludeAtt( ".geometry", "*olec*" );
	$f->AddIncludeAtt( ".geometry", "*centre-moire*" );
	$f->SetIncludeAttrCond( FilterEnums->Logic_OR );

	if ( $plotLayer->GetComp() != 0 && $f->Select() ) {
		$marksSeparated = GeneralHelper->GetGUID();
		CamLayer->MoveSelOtherLayer( $inCAM, $marksSeparated );
	}

	# 4) Remove frame

	CamLayer->ClipLayerData( $inCAM, $lName, $plotLayer->GetLimits() );

	# 5) Optimize lazer in order contain only one level of features

	if ( $plotLayer->GetName() =~ /^c$/ || $plotLayer->GetName() =~ /^s$/ || $plotLayer->GetName() =~ /^v\d$/ ) {

		CamLayer->OptimizeLevels( $self->{"inCAM"}, $lName, 1 );
		CamLayer->WorkLayer( $self->{"inCAM"}, $lName );
	}

	# 6) Compensate layer
	if ( $plotLayer->GetComp() != 0 ) {

		my $comp = $plotLayer->GetComp();

		# Before optimiyation, countourize data in matrix negative layers (in other case "sliver fills" are broken during data compensation)
		# If compensation is less than 0, it means matrix layer is negative
		if ( $comp < 0 ) {
			CamLayer->Contourize( $self->{"inCAM"}, $lName );
			CamLayer->WorkLayer( $self->{"inCAM"}, $lName );
		}

		CamLayer->CompensateLayerData( $inCAM, $lName, $plotLayer->GetComp() );
	}
	
	# return back markings
	if ( $marksSeparated ) {
		
		CamLayer->WorkLayer( $inCAM, $marksSeparated );
		CamLayer->MoveSelOtherLayer( $inCAM, $lName );
		CamMatrix->DeleteLayer($inCAM, $jobId,$marksSeparated);
		CamLayer->WorkLayer( $inCAM, $lName );
	}
	

	# 7) change polarity

	my $plotPolar = $plotSet->GetPolarity();
	if ( $plotPolar eq "mixed" && $plotLayer->GetPolarity() eq "negative" ) {

		CamLayer->NegativeLayerData( $inCAM, $lName, $plotLayer->{"pcbLimits"} );
	}

	# 7) Rotate layer
	if ( $plotSet->GetOrientation() eq Enums->Ori_HORIZONTAL ) {

		CamLayer->RotateLayerData( $inCAM, $lName, 270 );
	}

	# 8) Mirror layer
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

	my $outputLName = $plotSet->GetOutputLayerName();

	# Delete if exist
	if ( CamHelper->LayerExists( $inCAM, $jobId, $outputLName ) ) {

		$inCAM->COM( "delete_layer", "layer" => $outputLName );
	}

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

		#if($plotL)

		# Layer limits
		my %lLim = CamJob->GetLayerLimits( $inCAM, $jobId, $self->{"plotStep"}, $plotL->{"outputLayer"} );
		my %source = ( "x" => $lLim{"xmin"}, "y" => $lLim{"ymin"} );
		my %target = ( "x" => $startX, "y" => $startY );

		# move layer
		CamLayer->WorkLayer( $inCAM, $plotL->{"outputLayer"} );
		CamLayer->MoveSelSameLayer( $inCAM, $plotL->{"outputLayer"}, \%source, \%target );

		# merge layer to final output layer
		$inCAM->COM( "merge_layers", "source_layer" => $plotL->{"outputLayer"}, "dest_layer" => $outputLName );

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

	my $archive     = JobHelper->GetJobArchive($jobId);
	my $output      = JobHelper->GetJobOutput($jobId);
	my $archivePath = $archive . "zdroje";

	#delete old opfx form archive
	$self->__DeleteOldFiles();

	#$inCAM->COM( "set_subsystem", "name" => "Output" );

	# Add output device
	$inCAM->COM( "output_add_device", "type" => "format", "name" => "LP7008" );

	# Plot each set
	foreach my $plotSet ( @{ $self->{"plotSets"} } ) {

		my $filmSize      = $plotSet->GetFilmSizeInch();
		my $outputL       = $plotSet->GetOutputLayerName();
		my $sendToPlotter = $self->{"sendToPlotter"} ? "yes" : "no";

		# Compute pripority in queue, get highest
		my $priority = 5;

		my @cores = grep { $_->GetName() =~ /^v\d+$/ } $plotSet->GetLayers();
		if ( scalar(@cores) ) {
			$priority = 4;
		}

		# Reset settings of device
		$inCAM->COM( "output_reload_device", "type" => "format", "name" => "LP7008" );

		# Udate settings o device
		$inCAM->COM(
			"output_update_device",
			"type"          => "format",
			"name"          => "LP7008",
			"dir_path"      => $archivePath,
			"format_params" => "(film_size=$filmSize)(break_sr=yes)(break_symbols=yes)(send_to_plotter="
			  . $sendToPlotter
			  . ")(local_copy=yes)(iol_opfx_allow_out_limits=yes)(iol_opfx_use_profile_limits=no)(iol_surface_check=yes)(entry_num=$priority)"

		);

		# Filter only layer, which we want to output
		$inCAM->COM( "output_device_set_lyrs_filter", "type" => "format", "name" => "LP7008", "layers_filter" => $outputL );

		my $polarity = $plotSet->GetPolarity();

		if ( $polarity eq "mixed" ) {
			$polarity = "positive";
		}

		# Necessery set layer, otherwise
		$inCAM->COM(
			"image_set_elpd2",
			"job"         => $jobId,
			"step"        => $plotPanel,
			"layer"       => $outputL,
			"device_type" => "LP7008",
			"polarity"    => $polarity,
			"xstretch"    => "100.000",    # magic constant, given historicaly
			"ystretch"    => "100.013"
		);

		$inCAM->COM( "output_device_select_reset", "type" => "format", "name" => "LP7008" );    #toto tady musi byt, nevim proc

		$inCAM->COM( "output_device_select", "type" => "format", "name" => "LP7008" );

		my $resultItemPlot = $self->_GetNewItem( $plotSet->GetOutputItemName() );
		$resultItemPlot->SetGroup("Films");

		# START HANDLE EXCEPTION IN INCAM
		$inCAM->HandleException(1);

		my $plotResult = $inCAM->COM(
									  "output_device",
									  "type"                 => "format",
									  "name"                 => "LP7008",
									  "overwrite"            => "yes",
									  "overwrite_ext"        => "",
									  "on_checkout_by_other" => "output_anyway"
		);

		# STOP HANDLE EXCEPTION IN INCAM
		$inCAM->HandleException(0);

		if ( $plotResult > 0 ) {
			$resultItemPlot->AddError( $inCAM->GetExceptionError() );
		}

		# test if file was outputed

		my $fileExist = FileHelper->GetFileNameByPattern( $archivePath . "\\", $plotSet->GetOutputFileName() );
		unless ($fileExist) {

			my $stampt = GeneralHelper->GetGUID();

			#$inCAM->PutStampToLog($stampt);
			$resultItemPlot->AddError(
								 "Failed to create OPFX file: " . $archivePath . "\\" . $plotSet->GetOutputFileName() . ".\nExceptionId:" . $stampt );
		}

		$self->_OnItemResult($resultItemPlot);
	}

	# return to default subsystem
	#$inCAM->COM( "set_subsystem", "name" => "1-Up-Edit" );

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

sub __DeleteOldFiles {
	my $self = shift;

	my $jobId       = $self->{"jobId"};
	my $archivePath = JobHelper->GetJobArchive($jobId) . "zdroje";

	my @filesToDel = ();

	# Delete all files, which contain layer name from layer set
	foreach my $plotSet ( @{ $self->{"plotSets"} } ) {

		foreach my $layer ( $plotSet->GetLayers() ) {

			my $name = $layer->GetName();
			my @f    = FileHelper->GetFilesNameByPattern( $archivePath, "$jobId@" . $name . "v?_" );     # when single layer on film
			my @f2   = FileHelper->GetFilesNameByPattern( $archivePath, "$jobId@.*-" . $name . "_" );    # when two layer on films
			push( @filesToDel, ( @f, @f2 ) );
		}
	}

	foreach my $f (@filesToDel) {
		unlink $f;
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#my $self             = shift;
	#	my $inCAM            = shift;

	#use aliased 'HelperScripts::DirStructure';

	#DirStructure->Create();

}

1;
