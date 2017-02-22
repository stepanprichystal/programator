
#-------------------------------------------------------------------------------------------#
# Description: Responsible o create single pdf from prepared LayerDataList strucure
# Author:SPR
#-------------------------------------------------------------------------------------------#
package  Packages::Pdf::ControlPdf::SinglePreview::OutputPdf;

#3th party library
use strict;
use warnings;
use PDF::API2;
use POSIX;
use List::Util qw[max min];

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Pdf::ControlPdf::SinglePreview::Enums';
use aliased ' Packages::Gerbers::OutputData::Enums' => "OutputEnums";
use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamSymbol';
use aliased 'CamHelpers::CamJob';

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
	$self->{"lang"}    = shift;

	$self->{"outputPath"} = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".pdf";

	$self->{"profileLim"} = undef;

	return $self;
}

sub Output {
	my $self      = shift;
	my $layerList = shift;

	my %lim = CamJob->GetProfileLimits( $self->{"inCAM"}, $self->{"jobId"}, $self->{"pdfStep"} );

	$self->{"profileLim"} = \%lim;

	#$self->__PrepareLayers($layerList);

	$self->__OptimizeLayers($layerList);
	#$self->__OptimizeDrillMapLayers($layerList);

	my $pathPdf = $self->__OutputRawPdf($layerList);

	$self->__AddTextPdf( $layerList, $pathPdf );

}

sub GetOutput {
	my $self = shift;

	return $self->{"outputPath"};
}

## Do necessarary adjustment in InCAM with layers
## And prepare each export layer by LayerData strucutre
#sub __PrepareLayers {
#	my $self      = shift;
#	my $layerList = shift;
#
#	foreach my $lData ( $layerList->GetLayers() ) {
#
#		if ( $lData->GetType() eq Enums->LayerData_STANDARD ) {
#
#			$self->__PrepareSTANDARD($lData);
#
#		}
#		elsif ( $lData->GetType() eq Enums->LayerData_DRILLMAP ) {
#
#			$self->__PrepareDRILLMAP($lData);
#
#		}
#	}
#
#}


# Clip all exported layer, add thin frame around data
# Frame keep right ratio of exported data
# Ratio mast be 290:305 in order to fit layer data to pdf page and text around
sub __OptimizeStandardLayers {
	my $self      = shift;
	my $layerList = shift;

	my $inCAM  = $self->{"inCAM"};
	my @layers = $layerList->GetLayers();

	CamLayer->ClearLayers($inCAM);

	# affect all layers
	foreach my $l (@layers) {

		# drillm map  and layer with depth contains features behind profile
		if ( $l->GetType() ne OutputEnums->Type_NCDEPTHLAYERS &&  $l->GetType() ne OutputEnums->Type_DRILLMAP) {
			
			$inCAM->COM( "affected_layer", "name" => $l->GetOutput(), "mode" => "single", "affected" => "yes" );
			
		}
	}

	# clip area around profile
	$inCAM->COM(
				 "clip_area_end",
				 "layers_mode" => "affected_layers",
				 "layer"       => "",
				 "area"        => "profile",
				 "area_type"   => "rectangle",
				 "inout"       => "outside",
				 "contour_cut" => "yes",
				 "margin"      => "+2000",
				 "feat_types"  => "line\;pad;surface;arc;text",
				 "pol_types"   => "positive\;negative"
	);

	my $lName = GeneralHelper->GetGUID();

	# Create border around layer data. Border has to has ratio min 290:305 because of right place in pdf
	# if not, pcb layer would be covered by table with title and description of layer

	my %lim = %{ $self->{"profileLim"} };

	my $x = abs( $lim{"xmax"} - $lim{"xmin"} );
	my $y = abs( $lim{"ymax"} - $lim{"ymin"} );

	if ( min( $x, $y ) / max( $x, $y ) < 290 / 305 ) {

		# prepare coordination for frame

		if ( min( $x, $y ) == $x ) {

			# compute min x length
			my $newX = ( $y / 305 ) * 290;
			$lim{"xmin"} -= ( ( $newX - $x ) / 2 );
			$lim{"xmax"} += ( ( $newX - $x ) / 2 );

		}
		elsif ( min( $x, $y ) == $y ) {

			# compute min x length
			my $newY = ( $x / 305 ) * 290;
			$lim{"ymin"} -= ( ( $newY - $y ) / 2 );
			$lim{"ymax"} += ( ( $newY - $y ) / 2 );
		}

		$inCAM->COM( 'create_layer', layer => $lName, context => 'misc', type => 'document', polarity => 'positive', ins_layer => '' );

		CamLayer->WorkLayer( $inCAM, $lName );

		my %c1 = ( "x" => $lim{"xmin"}, "y" => $lim{"ymin"} );
		my %c2 = ( "x" => $lim{"xmax"}, "y" => $lim{"ymin"} );
		my %c3 = ( "x" => $lim{"xmax"}, "y" => $lim{"ymax"} );
		my %c4 = ( "x" => $lim{"xmin"}, "y" => $lim{"ymax"} );
		my @coord = ( \%c1, \%c2, \%c3, \%c4 );

		#
		CamSymbol->AddPolyline( $inCAM, \@coord, "r1", "negative" );

	}
	else {

		# frmae ratio is ok, do frame from profile
		$inCAM->COM( "profile_to_rout", "layer" => $lName, "width" => "1" );
		CamLayer->WorkLayer( $inCAM, $lName );
		$inCAM->COM("sel_invert");
	}

	$self->__CopyFrame( $lName, \@layers );
}

# Create drill maps
sub __OptimizeLayers {
	my $self      = shift;
	my $layerList = shift;

	my $inCAM  = $self->{"inCAM"};
	my @layers = $layerList->GetLayers();

	CamLayer->ClearLayers($inCAM);

	# Create border around layer data. Border has to has ratio min 290:305 because of right place in pdf
	# if not, pcb layer would be covered by table with title and description of layer

	#for each layer own border

	# affect all layers
	foreach my $l (@layers) {

		my $lName = GeneralHelper->GetGUID();
		
		$inCAM->COM( "profile_to_rout", "layer" => $l->GetOutput(), "width" => 1 );

		my %lim = CamJob->GetLayerLimits( $inCAM, $self->{"jobId"}, $self->{"pdfStep"}, $l->GetOutput() );

		my $x = abs( $lim{"xmax"} - $lim{"xmin"} );
		my $y = abs( $lim{"ymax"} - $lim{"ymin"} );

		# prepare coordination for frame

		if ( min( $x, $y ) == $x ) {

			# compute min x length
			my $newX = ( $y / 305 ) * 290;
			$lim{"xmin"} -= ( ( $newX - $x ) / 2 );
			$lim{"xmax"} += ( ( $newX - $x ) / 2 );

		}
		elsif ( min( $x, $y ) == $y ) {

			# compute min x length
			my $newY = ( $x / 305 ) * 290;
			$lim{"ymin"} -= ( ( $newY - $y ) / 2 );
			$lim{"ymax"} += ( ( $newY - $y ) / 2 );
		}

		#$inCAM->COM( 'create_layer', layer => $lName, context => 'misc', type => 'document', polarity => 'positive', ins_layer => '' );

		CamLayer->WorkLayer( $inCAM, $l->GetOutput() );

		my %c1 = ( "x" => $lim{"xmin"}, "y" => $lim{"ymin"} );
		my %c2 = ( "x" => $lim{"xmax"}, "y" => $lim{"ymin"} );
		my %c3 = ( "x" => $lim{"xmax"}, "y" => $lim{"ymax"} );
		my %c4 = ( "x" => $lim{"xmin"}, "y" => $lim{"ymax"} );
		my @coord = ( \%c1, \%c2, \%c3, \%c4 );

		#
		CamSymbol->AddPolyline( $inCAM, \@coord, "r1", "negative" );
		
		

		#my @list = ($l);

		#$self->__CopyFrame( $lName, \@list );
	}

}

sub __CopyFrame {
	my $self   = shift;
	my $lName  = shift;
	my @layers = @{ shift(@_) };

	my $inCAM = $self->{"inCAM"};

	CamLayer->WorkLayer( $inCAM, $lName );

	# affect all layers
	foreach my $l (@layers) {

		$inCAM->COM( "affected_layer", "name" => $l->GetOutput(), "mode" => "single", "affected" => "yes" );

	}

	my @layerStr = map { $_->GetOutput() } @layers;
	my $layerStr = join( "\\;", @layerStr );
	$inCAM->COM(
		"sel_copy_other",
		"dest"         => "affected_layers",
		"target_layer" => $lName . "\\;" . $layerStr,
		"invert"       => "no"

	);

	$inCAM->COM( "affected_layer", "mode" => "all", "affected" => "no" );
	$inCAM->COM( 'delete_layer', "layer" => $lName );

}

# Do output pdf of expor tlayers
sub __OutputRawPdf {
	my $self      = shift;
	my $layerList = shift;

	my $inCAM = $self->{"inCAM"};

	my @layers = $layerList->GetLayers();

	my @layerStr = map { $_->GetOutput() } @layers;
	my $layerStr = join( "\\;", @layerStr );

	my $outputPdf = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".pdf";

	$outputPdf =~ s/\\/\//g;

	# here was problem, when there is lots of layer, each layer has long name: fdfsd-df78f7d-f7d8f-f7d8f78d
	# Than incam command lenght was long and it doeasnt work
	# So layer are now named as ten position number

	$inCAM->COM(
		'print',

		#title             => '',

		layer_name        => "$layerStr",
		mirrored_layers   => '',
		draw_profile      => 'yes',
		drawing_per_layer => 'yes',
		label_layers      => 'no',
		dest              => 'pdf_file',
		num_copies        => '1',
		dest_fname        => $outputPdf,

		paper_size => 'A4',

		#scale_to          => '0.0',
		nx     => '2',
		ny     => '2',
		orient => 'none',

		#paper_orient => 'best',

		#paper_width   => 260,
		#paper_height  => 260,
		#auto_tray     => 'no',
		top_margin    => '0',
		bottom_margin => '0',
		left_margin   => '0',
		right_margin  => '0',
		"x_spacing"   => '0',
		"y_spacing"   => '0',

		#3color1        => $self->__ConvertColor( $l->GetColor()
	);

	# delete created layers
#	foreach my $lData (@layers) {
#
#		$inCAM->COM( 'delete_layer', "layer" => $lData->GetOutput() );
#	}

	return $outputPdf;

}

# add title and description to each pdf page for each layer
sub __AddTextPdf {
	my $self      = shift;
	my $layerList = shift;
	my $infile    = shift;

	unless ( -e $infile ) {
		die "Pdf file doesn't exiswt $infile.\n";
	}

	my $inCAM = $self->{"inCAM"};

	my $pdf_in  = PDF::API2->open($infile);
	my $pdf_out = PDF::API2->new;

	foreach my $pagenum ( 1 .. $pdf_in->pages ) {

		my $page_in = $pdf_in->openpage($pagenum);

		#
		# copy page content
		#
		my $page_out = $pdf_out->page(0);
		my @mbox     = $page_in->get_mediabox;
		$page_out->mediabox(@mbox);
		my $xo = $pdf_out->importPageIntoForm( $pdf_in, $pagenum );
		my $gfx = $page_out->gfx;

		$gfx->formimage(
			$xo,
			0, 0,    # x y
			1
		);           # scale

		# draw info tables

		my @data = $layerList->GetPageData($pagenum);

		for ( my $i = 0 ; $i < scalar(@data) ; $i++ ) {

			if ( $i == 0 ) {
				my $d = $data[$i];
				$self->__DrawInfoTable( 15, 430, $d, $page_out, $pdf_out );
			}
			elsif ( $i == 1 ) {
				my $d = $data[$i];
				$self->__DrawInfoTable( 15, 23, $d, $page_out, $pdf_out );
			}
			elsif ( $i == 2 ) {
				my $d = $data[$i];
				$self->__DrawInfoTable( 310, 430, $d, $page_out, $pdf_out );
			}
			elsif ( $i == 3 ) {
				my $d = $data[$i];
				$self->__DrawInfoTable( 310, 23, $d, $page_out, $pdf_out );
			}
		}

	}

	$pdf_out->saveas( $self->{"outputPath"} );

	unlink($infile);

}
 
sub __DrawInfoTable {
	my $self     = shift;
	my $xPos     = shift;
	my $yPos     = shift;
	my $data     = shift;
	my $page_out = shift;
	my $pdf_out  = shift;

	my $leftCellW  = 20;
	my $leftCellH  = 25;
	my $rightCellW = 250;
	my $rightCellH = 25;

	# draw frame
	my $frame = $page_out->gfx;
	$frame->fillcolor('#E5E5E5');
	$frame->rect(
				  $xPos - 0.5,                     # left
				  $yPos - 0.5,                     # bottom
				  $leftCellW + $rightCellW + 1,    # width
				  $leftCellH + 1                   # height
	);

	$frame->fill;

	# draw left cell
	my $lCell = $page_out->gfx;
	$lCell->fillcolor('#F5F5F5');
	$lCell->rect(
				  $xPos,                           # left
				  $yPos,                           # bottom
				  $leftCellW,                      # width
				  $leftCellH                       # height
	);

	$lCell->fill;

	# draw right cell
	my $rCell = $page_out->gfx;
	$rCell->fillcolor('#FFFFFF');
	$rCell->rect(
				  $xPos + $leftCellW,              # left
				  $yPos,                           # bottom
				  $rightCellW,                     # width
				  $rightCellH                      # height
	);

	$rCell->fill;

	# draw crosst cell
	my $lineV = $page_out->gfx;
	$lineV->fillcolor('#E5E5E5');
	$lineV->rect(
				  $xPos + $leftCellW,              # left
				  $yPos,                           # bottom
				  0.5,                             # width
				  $rightCellH                      # height
	);
	$lineV->fill;

	my $lineH = $page_out->gfx;
	$lineH->fillcolor('#E5E5E5');
	$lineH->rect(
				  $xPos,                           # left
				  $yPos + $rightCellH / 2,         # bottom
				  $rightCellW + $leftCellW,        # width
				  0.5                              # height
	);
	$lineH->fill;

	my $txtSize = 6;

	# add text title

	my $txtTitle = $page_out->text;
	$txtTitle->translate( $xPos + 2, $yPos + $rightCellH - 10 );
	my $font = $pdf_out->ttfont( GeneralHelper->Root() . '\Packages\Pdf\ControlPdf\HtmlTemplate\arial.ttf' );
	$txtTitle->font( $font, $txtSize );
	$txtTitle->fillcolor("black");

	if ( $self->{"lang"} eq "cz" ) {
		$txtTitle->text( 'Název    ' . $data->{"title"} );
	}
	else {
		$txtTitle->text( 'Name    ' . $data->{"title"} );
	}

	# add text title

	my $txtInf = $page_out->text;
	$txtInf->translate( $xPos + 2, $yPos + 3 );
	$txtInf->font( $font, $txtSize );
	$txtInf->fillcolor("black");

	if ( $self->{"lang"} eq "cz" ) {
		$txtInf->text( 'Pozn.    ' . $data->{"info"} );
	}
	else {
		$txtInf->text( 'Info       ' . $data->{"info"} );
	}

}

sub __PrepareSTANDARD {
	my $self      = shift;
	my $layerData = shift;

	my $inCAM = $self->{"inCAM"};
	my $lName = GeneralHelper->GetNumUID();
	$inCAM->COM( 'create_layer', layer => $lName, context => 'misc', type => 'document', polarity => 'positive', ins_layer => '' );

	foreach my $sL ( $layerData->GetSingleLayers() ) {

		if ( $sL->{"gROWlayer_type"} eq "rout" ) {

			CamLayer->WorkLayer( $inCAM, $sL->{"gROWname"} );
			my $lComp = CamLayer->RoutCompensation( $inCAM, $sL->{"gROWname"}, "document" );
			$inCAM->COM( "merge_layers", "source_layer" => $lComp, "dest_layer" => $lName );

			$inCAM->COM( 'delete_layer', "layer" => $lComp );

			#CamLayer->WorkLayer( $inCAM, $lMatrix->{"gROWname"}, 1);

		}
		else {

			$inCAM->COM( "merge_layers", "source_layer" => $sL->{"gROWname"}, "dest_layer" => $lName );
		}

	}

	$layerData->SetOutputLayer($lName);
}

sub __PrepareDRILLMAP {
	my $self      = shift;
	my $layerData = shift;

	my $inCAM = $self->{"inCAM"};
	my $lName = GeneralHelper->GetNumUID();

	my @singleL = $layerData->GetSingleLayers();
	my $sL      = $singleL[0];

	# change layer to drill if needed
	my $typeChanged = 0;
	if ( $sL->{"gROWlayer_type"} eq "rout" ) {
		CamLayer->SetLayerTypeLayer( $inCAM, $self->{"jobId"}, $sL->{"gROWname"}, "drill" );
		$typeChanged = 1;
	}

	# compute table position
	my $tablePos = undef;

	my %lim = %{ $self->{"profileLim"} };

	my $x = abs( $lim{"xmax"} - $lim{"xmin"} );
	my $y = abs( $lim{"ymax"} - $lim{"ymin"} );
	if ( $x <= $y ) {
		$tablePos = "right";
	}
	else {
		$tablePos = "top";
	}

	$inCAM->COM(
		"cre_drills_map",
		"layer"           => $sL->{"gROWname"},
		"map_layer"       => $lName,
		"preserve_attr"   => "no",
		"draw_origin"     => "no",
		"define_via_type" => "no",
		"units"           => "mm",
		"mark_dim"        => "2000",
		"mark_line_width" => "400",
		"mark_location"   => "center",
		"sr"              => "no",
		"slots"           => "no",
		"columns"         => "Count\;Type\;Finish",
		"notype"          => "plt",
		"table_pos"       => "right",                 # alwazs right, because another option not work
		"table_align"     => "bottom"
	);

	if ($typeChanged) {
		CamLayer->SetLayerTypeLayer( $inCAM, $self->{"jobId"}, $sL->{"gROWname"}, "rout" );
	}

	$layerData->SetOutputLayer($lName);
}

sub __OutputLayer {
	my $self   = shift;
	my @layers = @{ shift(@_) };

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

