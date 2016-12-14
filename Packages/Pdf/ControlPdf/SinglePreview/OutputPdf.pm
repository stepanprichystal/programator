
#-------------------------------------------------------------------------------------------#
# Description: TifFile - interface for signal layers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package  Packages::Pdf::ControlPdf::SinglePreview::OutputPdf;

#3th party library
use strict;
use warnings;
use PDF::API2;
 use POSIX;
 
#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Pdf::ControlPdf::SinglePreview::Enums';
use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamLayer';

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

	$self->{"outputPath"} = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".pdf";

	return $self;
}

sub Output {
	my $self      = shift;
	my $layerList = shift;

	$self->__PrepareLayers($layerList);

	$self->__OptimizeLayers($layerList);

	my $pathPdf = $self->__OutputRawPdf($layerList);

	$self->__AddTextPdf( $layerList, $pathPdf );

	return 1;

}

sub __PrepareLayers {
	my $self      = shift;
	my $layerList = shift;

	foreach my $lData ( $layerList->GetLayers() ) {

		if ( $lData->GetType() eq Enums->LayerData_STANDARD ) {

			$self->__PrepareSTANDARD($lData);

		}
		elsif ( $lData->GetType() eq Enums->LayerData_DRILLMAP ) {

			$self->__PrepareDRILLMAP($lData);

		}
	}
}

sub __OptimizeLayers {
	my $self      = shift;
	my $layerList = shift;

	my $inCAM  = $self->{"inCAM"};
	my @layers = $layerList->GetLayers();

	my $lName = GeneralHelper->GetGUID();

	# create border around profile
	$inCAM->COM( "profile_to_rout", "layer" => $lName, "width" => "10" );
	CamLayer->WorkLayer( $inCAM, $lName );

	$inCAM->COM("sel_invert");

	# copy border to all output layers

	foreach my $l (@layers) {

		$inCAM->COM( "affected_layer", "name" => $l->GetOutputLayer(), "mode" => "single", "affected" => "yes" );

	}

	my @layerStr = map { $_->GetOutputLayer() } @layers;
	my $layerStr = join( "\\;", @layerStr );
	$inCAM->COM(
		"sel_copy_other",
		"dest" => "affected_layers",

		"target_layer" => $lName . "\\;" . $layerStr,
		"invert"       => "no"

	);

	$inCAM->COM( "affected_layer", "mode" => "all", "affected" => "no" );
	$inCAM->COM( 'delete_layer', "layer" => $lName );

}

sub __OutputRawPdf {
	my $self      = shift;
	my $layerList = shift;

	my $inCAM = $self->{"inCAM"};

	my @layers = $layerList->GetLayers();

	my @layerStr = map { $_->GetOutputLayer() } @layers;
	my $layerStr = join( "\\;", @layerStr );

	my $outputPdf = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".pdf";

#my $str = '5D032ED7-6CCB-1014-ACAE-F93E6DB4D31D\;5D080830-6CCB-1014-ACAE-F93E6DB4D31D\;5D0B5C4D-6CCB-1014-ACAE-F93E6DB4D31D\;5D1003CF-6CCB-1014-ACAE-F93E6DB4D31D\;5D1316DD-6CCB-1014-ACAE-F93E6DB4D31D\;5D164EAA-6CCB-1014-ACAE-F93E6DB4D31D\;5D1AB504-6CCB-1014-ACAE-F93E6DB4D31D\;5D1CD02A-6CCB-1014-ACAE-F93E6DB4D31D\;5D1EFEC3-6CCB-1014-ACAE-F93E6DB4D31D\;5D212CDD-6CCB-1014-ACAE-F93E6DB4D31D\;5D232E19-6CCB-1014-ACAE-F93E6DB4D31D\;5D25A1B2-6CCB-1014-ACAE-F93E6DB4D31D\;5D27CD6C-6CCB-1014-ACAE-F93E6DB4D31D\;5D2A27C2-6CCB-1014-ACAE-F93E6DB4D31D\;5D2C27A7-6CCB-1014-ACAE-F93E6DB4D31D\;5D2E0580-6CCB-1014-ACAE-F93E6DB4D31D\;5D2F8DBF-6CCB-1014-ACAE-F93E6DB4D31D\;5D316CAE-6CCB-1014-ACAE-F93E6DB4D31D\;5D3354FB-6CCB-1014-ACAE-F93E6DB4D31D\;5D358317-6CCB-1014-ACAE-F93E6DB4D31D\;5D3764D1-6CCB-1014-ACAE-F93E6DB4D31D\;5D396710-6CCB-1014-ACAE-F93E6DB4D31D\;5D3B4654-6CCB-1014-ACAE-F93E6DB4D31D';
	$outputPdf =~ s/\\/\//g;

	$inCAM->COM(
		'print',

		#title             => '',

		layer_name        => $layerStr,
		mirrored_layers   => '',
		draw_profile      => 'no',
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
	foreach my $lData (@layers) {

		$inCAM->COM( 'delete_layer', "layer" => $lData->GetOutputLayer() );
	}

	return $outputPdf;

}

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
				$self->__DrawInfoTable( 20, 435, $d, $page_out, $pdf_out);
			}
			elsif ( $i == 1 ) {
				my $d = $data[$i];
				$self->__DrawInfoTable( 20, 25, $d, $page_out, $pdf_out );
			}
			elsif ( $i == 2 ) {
				my $d = $data[$i];
				$self->__DrawInfoTable( 315, 435, $d, $page_out, $pdf_out );
			}
			elsif ( $i == 3 ) {
				my $d = $data[$i];
				$self->__DrawInfoTable( 315, 25, $d, $page_out, $pdf_out );
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
	my $pdf_out = shift;

	my $leftCellW  = 20;
	my $leftCellH  = 30;
	my $rightCellW = 240;
	my $rightCellH = 30;

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
	my $font = $pdf_out->corefont('arial');
	$txtTitle->font( $font, $txtSize );
	$txtTitle->fillcolor("black");
	$txtTitle->text( 'Title:     ' . $data->{"title"} );

	# add text title

	my $txtInf = $page_out->text;
	$txtInf->translate( $xPos + 2, $yPos + 2 );
	$txtInf->font( $font, $txtSize );
	$txtInf->fillcolor("black");
	$txtInf->text( 'Info:    ' . $data->{"info"} );

}

sub __PrepareSTANDARD {
	my $self      = shift;
	my $layerData = shift;

	my $inCAM = $self->{"inCAM"};
	my $lName = GeneralHelper->GetGUID();
	$inCAM->COM( 'create_layer', layer => $lName, context => 'misc', type => 'document', polarity => 'positive', ins_layer => '' );

	foreach my $sL ( $layerData->GetSingleLayers() ) {

		my $lMatrix = $sL->GetLayer();

		if ( $lMatrix->{"gROWlayer_type"} eq "rout" ) {

			CamLayer->WorkLayer( $inCAM, $lMatrix->{"gROWname"} );
			my $lComp = CamLayer->RoutCompensation( $inCAM, $lMatrix->{"gROWname"}, "document" );
			$inCAM->COM( "merge_layers", "source_layer" => $lComp, "dest_layer" => $lName );

			$inCAM->COM( 'delete_layer', "layer" => $lComp );

		}
		else {

			$inCAM->COM( "merge_layers", "source_layer" => $lMatrix->{"gROWname"}, "dest_layer" => $lName );
		}

	}

	$layerData->SetOutputLayer($lName);
}

sub __PrepareDRILLMAP {
	my $self      = shift;
	my $layerData = shift;

	my $inCAM = $self->{"inCAM"};
	my $lName = GeneralHelper->GetGUID();

	my @singleL = $layerData->GetSingleLayers();
	my $lMatrix = $singleL[0]->GetLayer();

	#CamLayer->SetLayerTypeLayer( $inCAM, $self->{"jobId"}, $lMatrix->{"gROWname"}, "drill" );

	$inCAM->COM(
				 "cre_drills_map",
				 "layer"           => $lMatrix->{"gROWname"},
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
				 "columns"         => "Count\;Type;Finish;Des",
				 "notype"          => "plt",
				 "table_pos"       => "right",
				 "table_align"     => "bottom"
	);

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

