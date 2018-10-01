
#-------------------------------------------------------------------------------------------#
# Description: Modul is responsible for creation pdf pressfit
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::DrillMapPdf::DrillMapPdf;

#3th party library
use strict;
use warnings;
use English;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamSymbol';
use aliased 'CamHelpers::CamDTM';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamFilter';
use aliased 'CamHelpers::CamDrilling';
use aliased 'Enums::EnumsGeneral';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	my @paths = ();
	$self->{"outputPaths"} = \@paths;

	return $self;
}

sub CreatePressfitMeasure {
	my $self = shift;
	my $step = shift;

	my @layers = CamDrilling->GetNCLayersByTypes( $self->{"inCAM"}, $self->{"jobId"}, [ EnumsGeneral->LAYERTYPE_plt_nDrill ] );
	my $title  = uc( $self->{"jobId"} ) . " - Measurement of PLT pressfit tolerances [mm]";
	my $note   = "For measurement use the column 'Finish'";

	$self->Create( $step, \@layers, $title, $note, "hole", "plated", "press_fit", 1 );
}

sub CreateToleranceMeasure {
	my $self = shift;
	my $step = shift;

	my @layers = CamDrilling->GetNCLayersByTypes( $self->{"inCAM"}, $self->{"jobId"},
												  [ EnumsGeneral->LAYERTYPE_nplt_nDrill, EnumsGeneral->LAYERTYPE_nplt_nMill ] );
	my $title = uc( $self->{"jobId"} ) . " - Measurement of NPLT tolerances [mm]";
	my $note  = "For measurement use the column 'Finish'";

	$self->Create( $step, \@layers, $title, $note, "hole", "non_plated", "standard", 1 );
}

sub Create {
	my $self      = shift;
	my $step      = shift;
	my $layers    = shift;    # inspected layers
	my $titleText = shift;    # titles
	my $noteText  = shift;    # note under drill table

	my $shape      = shift;   # hole, slot
	my $type1      = shift;   # plated, non_plated, via
	my $type2      = shift;   # standard, press_fit
	my $tolerances = shift;   # 1/0

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @paths = ();
	$self->{"outputPaths"} = \@paths;

	# 1) choose which step and layers prepare for pressfit

	my @drillMaps = ();

	my @steps = CamStepRepeat->GetUniqueNestedStepAndRepeat( $inCAM, $jobId, $step );

	foreach my $l ( @{$layers} ) {
		push( @drillMaps, $self->__PrepareDrillMapsLayer( \@steps, $l->{"gROWname"}, $titleText, $noteText, $shape, $type1, $type2, $tolerances ) );
	}

	# 2) Output pdf

	# choose background layer
	my $backgroundLayer = undef;

	if ( CamHelper->LayerExists( $inCAM, $jobId, "c" ) ) {
		$backgroundLayer = "c";
	}

	foreach my $m (@drillMaps) {

		push( @paths, $self->__OutputPdf( $m, $backgroundLayer ) );
	}

	return 1;
}

# Return all stacku paths
sub GetPdfPaths {
	my $self = shift;

	return @{ $self->{"outputPaths"} };
}

sub __OutputPdf {
	my $self       = shift;
	my $drillMap   = shift;
	my $background = shift;

	my $inCAM = $self->{"inCAM"};

	my $layerStr = $drillMap->{"layer"};

	if ($background) {
		$layerStr = $background . "\\;" . $layerStr;
	}

	my $pdfFile = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".pdf";
	$pdfFile =~ s/\\/\//g;

	CamHelper->SetStep( $inCAM, $drillMap->{"step"} );

	$inCAM->COM(
				 'print',
				 layer_name        => $layerStr,
				 mirrored_layers   => '',
				 draw_profile      => 'no',
				 drawing_per_layer => 'no',
				 label_layers      => 'no',
				 dest              => 'pdf_file',
				 num_copies        => '1',
				 dest_fname        => $pdfFile,
				 paper_size        => 'A4',
				 orient            => 'none',
				 auto_tray         => 'no',
				 top_margin        => '0',
				 bottom_margin     => '0',
				 left_margin       => '0',
				 right_margin      => '0',
				 "x_spacing"       => '0',
				 "y_spacing"       => '0',
				 "color1"          => '909090',
				 "color2"          => '990000'
	);

	$inCAM->COM( 'delete_layer', "layer" => $drillMap->{"layer"} );

	return $pdfFile;
}

sub __PrepareDrillMapsLayer {
	my $self      = shift;
	my @steps     = @{ shift(@_) };
	my $layer     = shift;
	my $titleText = shift;            # titles
	my $noteText  = shift;            # note under drill table

	my $shape      = shift;           # hole, slot
	my $type1      = shift;           # plated, non_plated, via
	my $type2      = shift;           # standard, press_fit
	my $tolerances = shift;           # 1/0

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @drillMapLayers = ();

	foreach my $step (@steps) {

		# filter holes

		my @tools = CamDTM->GetDTMTools( $inCAM, $jobId, $step->{"stepName"}, $layer, 0 );

		if ( defined $shape ) {

			@tools = grep { $_->{"gTOOLshape"} eq $shape } @tools;
		}

		if ( defined $type1 ) {

			@tools = grep { $_->{"gTOOLtype"} eq $type1 } @tools;
		}

		if ( defined $type2 ) {

			@tools = grep { $_->{"gTOOLtype2"} eq $type2 } @tools;
		}

		if ( defined $tolerances ) {

			@tools = grep { $_->{"gTOOLmin_tol"} > 0 || $_->{"gTOOLmax_tol"} > 0 } @tools;
		}

		if ( scalar(@tools) ) {

			$self->__CheckTools( \@tools );

			CamHelper->SetStep( $inCAM, $step->{"stepName"} );

			my %inf = ( "step" => $step->{"stepName"} );
			$inf{"layer"} = $self->__PrepareDrillMaps( $step->{"stepName"}, $layer, \@tools, $titleText, $noteText );

			push( @drillMapLayers, \%inf );

		}
	}

	return @drillMapLayers;

}

sub __PrepareDrillMaps {
	my $self      = shift;
	my $step      = shift;
	my $layer     = shift;
	my @tools     = @{ shift(@_) };
	my $titleText = shift;            # titles
	my $noteText  = shift;            # note under drill table

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $lPressfit = GeneralHelper->GetGUID();
	my $lDrillMap = GeneralHelper->GetGUID();

	#$inCAM->COM( "merge_layers", "source_layer" => $layer, "dest_layer" => $lPressfit );

	$inCAM->COM(
		"copy_layer",
		"source_job"   => $jobId,
		"source_step"  => $step,
		"source_layer" => $layer,
		"dest"         => "layer_name",
		"dest_step"    => $step,
		"dest_layer"   => $lPressfit,
		"mode"         => "append",

		"copy_lpd"     => "new_layers_only",
		"copy_sr_feat" => "no"
	);

	CamLayer->SetLayerTypeLayer( $inCAM, $jobId, $lPressfit, "drill" );
	CamLayer->WorkLayer( $inCAM, $lPressfit );

	# 1) keep only pressfit hole in layer

	my @symb = map { "r" . $_->{"gTOOLdrill_size"} } @tools;
	my $result = CamFilter->BySymbols( $inCAM, \@symb );

	#my $result = CamFilter->SelectBySingleAtt( $inCAM, $jobId, ".plated_type", "press_fit" );

	$inCAM->COM("sel_reverse");
	$inCAM->COM("get_select_count");

	if ( $self->{"inCAM"}->GetReply() > 0 ) {

		$inCAM->COM("sel_delete");
	}

	# 2) create drill map
	$inCAM->COM(
				 "cre_drills_map",
				 "layer"           => $lPressfit,
				 "map_layer"       => $lDrillMap,
				 "preserve_attr"   => "no",
				 "draw_origin"     => "no",
				 "define_via_type" => "no",
				 "units"           => "mm",
				 "mark_dim"        => "2000",
				 "mark_line_width" => "400",
				 "mark_location"   => "center",
				 "sr"              => "no",
				 "slots"           => "no",
				 "columns"         => "Count\;Type\;+Tol\;-Tol\;Finish",
				 "notype"          => "abort",
				 "table_pos"       => "right",
				 "table_align"     => "bottom"
	);

	$inCAM->COM( 'delete_layer', "layer" => $lPressfit );

	# 3) Add text job id to layer

	CamLayer->WorkLayer( $inCAM, $lDrillMap );

	my %profileLim = CamJob->GetProfileLimits2( $self->{"inCAM"}, $self->{"jobId"}, $step, 1 );

	my %positionTit = ( "x" => $profileLim{"xMin"}, "y" => $profileLim{"yMax"} + 10 );

	CamSymbol->AddText( $inCAM, $titleText, \%positionTit, 5, undef, 2 );

	my %positionInf = ( "x" => $profileLim{"xMax"} + 2, "y" => $profileLim{"yMin"} - 5 );

	#CamSymbol->AddText( $inCAM, "For pressfit measurements use the column 'Finish'", \%positionInf, 2, undef, 0.5 );

	CamSymbol->AddText( $inCAM, $noteText, \%positionInf, 2, undef, 0.5 );

	$inCAM->COM( "profile_to_rout", "layer" => $lDrillMap, "width" => "200" );

	return $lDrillMap;

}

# check if tool has finis size and tolerance
sub __CheckTools {
	my $self  = shift;
	my @tools = @{ shift(@_) };

	foreach my $t (@tools) {

		# test on finish size
		if ( !defined $t->{"gTOOLfinish_size"} || $t->{"gTOOLfinish_size"} == 0 || $t->{"gTOOLfinish_size"} eq "" || $t->{"gTOOLfinish_size"} eq "?" )
		{

			die "Pressfit tool: " . $t->{"gTOOLdrill_size"} . "µm has no finish size.\n";
		}

		if ( $t->{"gTOOLmin_tol"} == 0 && $t->{"gTOOLmax_tol"} == 0 ) {

			die "Measured tool: " . $t->{"gTOOLdrill_size"} . "µm has not defined tolerance.\n";
		}
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Pdf::DrillMapPdf::DrillMapPdf';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "d152457";
	my $presss = DrillMapPdf->new( $inCAM, $jobId );
	$presss->CreateToleranceMeasure("panel");

}

1;

