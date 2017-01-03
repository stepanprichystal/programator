
#-------------------------------------------------------------------------------------------#
# Description: TifFile - interface for signal layers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::FinalPreview::OutputPdf;

#3th party library
use threads;
use strict;
use warnings;
use PDF::API2;
use List::Util qw[max min];
use Math::Trig;
use Image::Size;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::Pdf::ControlPdf::FinalPreview::Enums';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamToolDepth';
use aliased 'CamHelpers::CamFilter';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::SystemCall::SystemCall';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"viewType"} = shift;
	$self->{"inCAM"}    = shift;
	$self->{"jobId"}    = shift;
	$self->{"pdfStep"}  = shift;

	$self->{"outputPath"} = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".jpeg";

	return $self;
}

sub Output {
	my $self      = shift;
	my $layerList = shift;

	$self->__PrepareLayers($layerList);
	$self->__OptimizeLayers($layerList);
	$self->__OutputPdf($layerList);

}

sub GetOutput {
	my $self = shift;

	return $self->{"outputPath"};
}

sub __OutputPdf {
	my $self      = shift;
	my $layerList = shift;

	my $result = 1;

	my $inCAM = $self->{"inCAM"};

	my @layers = $layerList->GetLayers(1);

	my $dirPath = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . "\\";
	mkdir($dirPath) or die "Can't create dir: " . $dirPath . $_;

	my @layerStr = map { $_->GetOutputLayer() } @layers;
	my $layerStr = join( "\\;", @layerStr );

	my $multiPdf = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".pdf";

	$multiPdf =~ s/\\/\//g;

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
		dest_fname        => $multiPdf,

		paper_size => 'A4',

		#scale_to          => '0.0',
		#nx                => '1',
		#ny                => '1',
		orient => 'none',

		#paper_orient => 'best',

		#paper_width   => 260,
		#paper_height  => 260,
		auto_tray     => 'no',
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

	$self->__SplitMultiPdf( $layerList, $multiPdf, $dirPath );
	$self->__CreatePng( $layerList, $dirPath );

	# use threads;
	#$thr1 = threads->create('msc', 'perl 1.pl');
	#$thr2 = threads->create('msc', 'perl 2.pl');
	#
	#$thr1->join();
	#$thr2->join();
	#
	#sub msc{ ## make system call
	#  system( @_ );
	#}

	# print layer one by one

	# merge all png to one
	# order of merging

	my @layerStr2 = map { $dirPath . $_->GetOutputLayer() . ".png" } @layers;
	my $layerStr2 = join( " ", @layerStr2 );

	my $outputTmp = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".jpg";

	my @cmd = ( EnumsPaths->InCAM_3rdScripts . "im\\convert.exe" );
	push( @cmd, $layerStr2 );

	push( @cmd, "-flatten" );
	push( @cmd, "-trim" );
	push( @cmd, "-blur 0.2x0.2 -quality 90%" );
	push( @cmd, $outputTmp );

	my $cmdStr = join( " ", @cmd );

	my $systeMres = system($cmdStr);

	# Adjust image to ratio 3:5

	#    # Get the size of globe.gif
	( my $x, my $y ) = imgsize($outputTmp);

	my $rotate = $x < $y ? 1 : 0;

	# we want to longer side was width
	if ($rotate) {
		my $pom = $y;
		my $y   = $x;
		my $x   = $pom;
	}

	my $ratio = min( $x, $y ) / max( $x, $y );

	# compute new image resolution
	my $dimW = 0;
	my $dimH = 0;

	# compute new height
	if ( $ratio <= 3 / 5 ) {

		$dimW = max( $x, $y );
		$dimH = int( ( $dimW / 5 ) * 3 );

	}
	else {

		# compute new width

		$dimH = min( $x, $y );
		$dimW = int( ( $dimH / 3 ) * 5 );

	}

	my @cmd2 = ( EnumsPaths->InCAM_3rdScripts . "im\\convert.exe" );
	push( @cmd2, $outputTmp );
	if ($rotate) {
		push( @cmd2, "-rotate 90" );
	}

	push( @cmd2, "-gravity center -background white" );
	push( @cmd2, "-extent " . $dimW . "x" . $dimH );

	push( @cmd2, $self->{"outputPath"} );

	my $cmdStr2 = join( " ", @cmd2 );

	my $systeMres2 = system($cmdStr2);

	foreach my $l (@layers) {
		if ( -e $dirPath . $l->GetOutputLayer() . ".png" ) {
			unlink( $dirPath . $l->GetOutputLayer() . ".png" );
		}
		if ( -e $dirPath . $l->GetOutputLayer() . ".pdf" ) {
			unlink( $dirPath . $l->GetOutputLayer() . ".pdf" );
		}
	}

	rmdir($dirPath);

	unlink($outputTmp);

}

sub __CreatePng {
	my $self      = shift;
	my $layerList = shift;
	my $dirPath   = shift;

	my @layers = $layerList->GetLayers(1);

	#my @threads;
	my @allCmds = ();
	$self->{"inCAM"}->{"childThread"} = 1;

	my @fileToDel = ();

	foreach my $l (@layers) {

		# merge all png to one
		my $result = 1;

		my @cmds = ();

		# get brightness

		my $brightness = "";
		$brightness = " -brightness-contrast " . $l->GetBrightness() if ( defined $l->GetBrightness() );

		if ( defined $l->GetTexture() ) {

			my $backg = "black";

			if ( $l->GetTexture() eq Enums->Texture_GOLD ) {

				$backg = "gold3";
			}
			elsif ( $l->GetTexture() eq Enums->Texture_CU ) {

				$backg = "tan2";
			}
			elsif ( $l->GetTexture() eq Enums->Texture_CHEMTINALU || $l->GetTexture() eq Enums->Texture_HAL ) {

				$backg = "snow3";
			}

			my $texturPath = GeneralHelper->Root() . "\\Resources\\Textures\\" . $l->GetTexture() . ".jpeg";

			# 1 cast

			my $tmpImg = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".png";

			push( @fileToDel, $tmpImg );

			my @cmd1 = ( EnumsPaths->InCAM_3rdScripts . "im\\convert.exe" );
			push( @cmd1, "-resize 3000 -density 300" );

			#push( @cmd, "-transparent white" );
			push( @cmd1, $dirPath . $l->GetOutputLayer() . ".pdf" );
			push( @cmd1, "-flatten  +level-colors $backg," );
			push( @cmd1, "-fuzz 20% -transparent $backg $tmpImg" );
			#push( @cmd1, "-flatten  -fuzz 30% -transparent black $tmpImg" );
			my $cmdStr = join( " ", @cmd1 );

			#my $systeMres = system($cmdStr_);
			push( @cmds, $cmdStr );

			# 2 cast

			my @cmd = ( EnumsPaths->InCAM_3rdScripts . "im\\convert.exe" );
			push( @cmd, "$texturPath $tmpImg -flatten  -transparent white" );
			push( @cmd, "-shave 20x20 -trim -shave 5x5" );
			push( @cmd, $brightness );

			#push( @cmd, "-transparent white" );
			my $pngOutput = $dirPath . $l->GetOutputLayer() . ".pdf";
			$pngOutput =~ s/pdf/png/;
			push( @cmd, $pngOutput );

			my $cmdStr2 = join( " ", @cmd );
			push( @cmds, $cmdStr2 );
			
			push( @allCmds, \@cmds );

		}
		else {

			#		c: \Export \report > convert -density 300 test . pdf -shave 20 x 20 -trim -shave 5 x 5 + l evel-colors green,
			#		white -fuzz 20 % -transparent white result . png
			#
			#		  c : \Export \report > convert -density 300 test . pdf -shave 20 x 20 -trim -shave 5 x 5 + l evel-colors green,
			#		white -alpha on -channel a -evaluate set 50 % -fuzz 50 % -trans parent white result2 . png

			my $flatten = "";
			$flatten = "-flatten" if ( $l->GetType() eq Enums->Type_MASK );

			my $backg = "white";

			if ( $l->GetTransparency() < 100 && $l->GetColor() eq "250,250,250" ) {
				$backg = "orange";
			}

			my @cmd = ( EnumsPaths->InCAM_3rdScripts . "im\\convert.exe" );
			push( @cmd, "-resize 3000 -density 300" );

			#push( @cmd, "-transparent white" );
			push( @cmd, $dirPath . $l->GetOutputLayer() . ".pdf" );

			push( @cmd, "$flatten -shave 20x20 -trim -shave 5x5" );
			push( @cmd, "+level-colors " . $self->__ConvertColor( $l->GetColor(), ) . ",$backg" );

			if ( $l->GetTransparency() < 100 ) {

				push( @cmd, "-alpha on -channel a -evaluate set " . $l->GetTransparency() . "%" );
				push( @cmd, "-fuzz 30% -transparent $backg" );

			}
			else {
				push( @cmd, "-transparent $backg" );

			}

			#smayat
			#		if($l->GetType() eq Enums->Type_OUTERCU){
			#			push( @cmd, "+noise Gaussian -evaluate add 5% -blur 0x0.5" );
			#		}
			#
			#		if($l->GetType() eq Enums->Type_MASK){
			#			push( @cmd, "+noise Gaussian -evaluate add 5% -blur 0x1.2" );
			#		}
			push( @cmd, $brightness );

			my $pngOutput = $dirPath . $l->GetOutputLayer() . ".pdf";
			$pngOutput =~ s/pdf/png/;
			push( @cmd, $pngOutput );

			my $cmdStr = join( " ", @cmd );
			push( @cmds, $cmdStr );
			
		    push( @allCmds, \@cmds );

		}

		 # $self->__ConvertToPng( \@cmds )  ;

		#my $thr1 = threads->create( sub { $self->__ConvertToPng( \@cmds ) } );

		#push( @threads, $thr1 );
		print STDERR "threat created \n";

	}
	
 	my $script =  GeneralHelper->Root() . "\\Packages\\Pdf\\ControlPdf\\FinalPreview\\CreatePng.pl";
	
	my $createPngCall = SystemCall->new($script, \@allCmds);
	unless($createPngCall->Run()){
		
		die "When convert pdf to png.\n";
	}
	

#	foreach (@threads) {
#
#		$_->join();
#	}

	foreach my $f (@fileToDel) {

		if ( -e $f ) {
			unlink($f);
		}

	}

	$self->{"inCAM"}->{"childThread"} = 0;

	print STDERR "threats done \n";

}

sub __ConvertToPng {
	my $self = shift;
	my @cmds = @{ shift(@_) };

	foreach my $cmd (@cmds) {

		my $systeMres = system($cmd);

	}

}

sub __SplitMultiPdf {
	my $self      = shift;
	my $layerList = shift;
	my $pdfOutput = shift;
	my $dirPath   = shift;

	my @layers = $layerList->GetLayers(1);

	my $pdf_in = PDF::API2->open($pdfOutput);

	foreach my $pagenum ( 1 .. $pdf_in->pages ) {

		my $pdf_out = PDF::API2->new;

		my $page_in = $pdf_in->openpage($pagenum);

		#
		# create a new page
		#
		my $page_out = $pdf_out->page(0);

		my @mbox = $page_in->get_mediabox;
		$page_out->mediabox(@mbox);

		my $xo = $pdf_out->importPageIntoForm( $pdf_in, $pagenum );

		my $gfx = $page_out->gfx;

		$gfx->formimage(
			$xo,
			0, 0,    # x y
			1
		);           # scale

		my $out = $dirPath . $layers[ $pagenum - 1 ]->GetOutputLayer() . ".pdf";

		$pdf_out->saveas($out);

	}

	unlink($pdfOutput);
}

#}

sub __OptimizeLayers {
	my $self      = shift;
	my $layerList = shift;

	my $inCAM  = $self->{"inCAM"};
	my @layers = $layerList->GetLayers(1);

	my $lName = GeneralHelper->GetGUID();

	# create border around profile
	$inCAM->COM( "profile_to_rout", "layer" => $lName, "width" => "10" );
	CamLayer->WorkLayer( $inCAM, $lName );

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

	# clip area around profile
	$inCAM->COM(
		"clip_area_end",
		"layers_mode" => "affected_layers",
		"layer"       => "",
		"area"        => "profile",

		#"area_type"   => "rectangle",
		"inout"       => "outside",
		"contour_cut" => "yes",
		"margin"      => "-2",
		"feat_types"  => "line\;pad;surface;arc;text",
		"pol_types"   => "positive\;negative"
	);
	$inCAM->COM( "affected_layer", "mode" => "all", "affected" => "no" );
	$inCAM->COM( 'delete_layer', "layer" => $lName );

	# if preview from BOT mirror all layers
	if ( $self->{"viewType"} eq Enums->View_FROMBOT ) {

		my $rotateBy = undef;

		my %lim = CamJob->GetProfileLimits( $inCAM, $self->{"jobId"}, $self->{"pdfStep"} );

		my $x = abs( $lim{"xmax"} - $lim{"xmin"} );
		my $y = abs( $lim{"ymax"} - $lim{"ymin"} );

		if ( $x <= $y ) {

			$rotateBy = "y";
		}
		else {

			$rotateBy = "x";
		}

		foreach my $l (@layers) {

			CamLayer->WorkLayer( $inCAM, $l->GetOutputLayer() );
			CamLayer->MirrorLayerData( $inCAM, $l->GetOutputLayer(), $rotateBy );
		}
	}

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
	$self->__PreparePLTTHROUGHNC( $layerList->GetLayerByType( Enums->Type_PLTTHROUGHNC ) );
	$self->__PrepareNPLTTHROUGHNC( $layerList->GetLayerByType( Enums->Type_NPLTTHROUGHNC ) );

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

	unless ( $layer->HasLayers() ) {
		return 0;
	}

	my $inCAM  = $self->{"inCAM"};
	my @layers = $layer->GetSingleLayers();

	if ( $layers[0] ) {

		my $lName = GeneralHelper->GetGUID();

		$inCAM->COM( "merge_layers", "source_layer" => $layers[0]->{"gROWname"}, "dest_layer" => $lName );

		$layer->SetOutputLayer($lName);
	}
}

# Invert solder mask
sub __PrepareMASK {
	my $self  = shift;
	my $layer = shift;

	unless ( $layer->HasLayers() ) {
		return 0;
	}

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

		$lim{"xMin"} = $lim{"xmin"};
		$lim{"xMax"} = $lim{"xmax"};
		$lim{"yMin"} = $lim{"ymin"};
		$lim{"yMax"} = $lim{"ymax"};

		CamLayer->NegativeLayerData( $self->{"inCAM"}, $lName, \%lim );

		$layer->SetOutputLayer($lName);

		#if white, opaque high
		if ( $layer->GetColor() eq "250,250,250" ) {
			$layer->SetTransparency(92);
		}
		else {
			$layer->SetTransparency(80);
		}

	}
}

# Dont do nothing and export silk as is
sub __PrepareSILK {
	my $self  = shift;
	my $layer = shift;

	unless ( $layer->HasLayers() ) {
		return 0;
	}

	my $inCAM  = $self->{"inCAM"};
	my @layers = $layer->GetSingleLayers();

	if ( $layers[0] ) {

		my $lName = GeneralHelper->GetGUID();

		$inCAM->COM( "merge_layers", "source_layer" => $layers[0]->{"gROWname"}, "dest_layer" => $lName );

		$layer->SetOutputLayer($lName);
	}
}

# Compensate this layer and resize about 100µm (plating)
sub __PreparePLTDEPTHNC {
	my $self  = shift;
	my $layer = shift;

	unless ( $layer->HasLayers() ) {
		return 0;
	}

	my $inCAM  = $self->{"inCAM"};
	my @layers = $layer->GetSingleLayers();

	my $lName = GeneralHelper->GetGUID();

	$inCAM->COM( 'create_layer', layer => $lName, context => 'misc', type => 'document', polarity => 'positive', ins_layer => '' );

	# compensate
	foreach my $l (@layers) {

		if ( $l->{"gROWlayer_type"} eq "rout" ) {
			CamLayer->WorkLayer( $inCAM, $l->{"gROWname"} );
			my $lComp = CamLayer->RoutCompensation( $inCAM, $l->{"gROWname"}, "document" );

			# check for special rout 6.5mm with depth
			$self->__CheckCountersink( $l, $lComp );

			$inCAM->COM( "merge_layers", "source_layer" => $lComp, "dest_layer" => $lName );
			$inCAM->COM( 'delete_layer', "layer" => $lComp );

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

	unless ( $layer->HasLayers() ) {
		return 0;
	}

	my $inCAM  = $self->{"inCAM"};
	my @layers = $layer->GetSingleLayers();
	my $lName  = GeneralHelper->GetGUID();

	$inCAM->COM( 'create_layer', layer => $lName, context => 'misc', type => 'document', polarity => 'positive', ins_layer => '' );

	# compensate
	foreach my $l (@layers) {

		if ( $l->{"gROWlayer_type"} eq "rout" ) {
			CamLayer->WorkLayer( $inCAM, $l->{"gROWname"} );
			my $lComp = CamLayer->RoutCompensation( $inCAM, $l->{"gROWname"}, "document" );

			# check for special rout 6.5mm with depth
			$self->__CheckCountersink( $l, $lComp );

			$inCAM->COM( "merge_layers", "source_layer" => $lComp, "dest_layer" => $lName );
			$inCAM->COM( 'delete_layer', "layer" => $lComp );
		}
		else {

			$inCAM->COM( "merge_layers", "source_layer" => $l->{"gROWname"}, "dest_layer" => $lName );
		}
	}

	$layer->SetOutputLayer($lName);

}

# Compensate this layer and resize about 100µm (plating)
sub __PreparePLTTHROUGHNC {
	my $self  = shift;
	my $layer = shift;

	unless ( $layer->HasLayers() ) {
		return 0;
	}

	my $inCAM  = $self->{"inCAM"};
	my @layers = $layer->GetSingleLayers();
	my $lName  = GeneralHelper->GetGUID();

	$inCAM->COM( 'create_layer', layer => $lName, context => 'misc', type => 'document', polarity => 'positive', ins_layer => '' );

	# compensate
	foreach my $l (@layers) {

		if ( $l->{"gROWlayer_type"} eq "rout" ) {

			CamLayer->WorkLayer( $inCAM, $l->{"gROWname"} );
			my $lComp = CamLayer->RoutCompensation( $inCAM, $l->{"gROWname"}, "document" );

			$inCAM->COM( "merge_layers", "source_layer" => $lComp, "dest_layer" => $lName );

			$inCAM->COM( 'delete_layer', "layer" => $lComp );

		}
		else {

			$inCAM->COM( "merge_layers", "source_layer" => $l->{"gROWname"}, "dest_layer" => $lName );
		}

	}

	CamLayer->WorkLayer( $inCAM, $lName );
	$inCAM->COM( "sel_resize", "size" => -100, "corner_ctl" => "no" );

	$layer->SetOutputLayer($lName);

}

# Compensate this layer and resize about 100µm (plating)
sub __PrepareNPLTTHROUGHNC {
	my $self  = shift;
	my $layer = shift;

	unless ( $layer->HasLayers() ) {
		return 0;
	}

	my $inCAM  = $self->{"inCAM"};
	my @layers = $layer->GetSingleLayers();
	my $lName  = GeneralHelper->GetGUID();

	$inCAM->COM( 'create_layer', layer => $lName, context => 'misc', type => 'document', polarity => 'positive', ins_layer => '' );

	# compensate
	foreach my $l (@layers) {

		if ( $l->{"gROWlayer_type"} eq "rout" ) {

			CamLayer->WorkLayer( $inCAM, $l->{"gROWname"} );
			my $lComp = CamLayer->RoutCompensation( $inCAM, $l->{"gROWname"}, "document" );

			$inCAM->COM( "merge_layers", "source_layer" => $lComp, "dest_layer" => $lName );

			$inCAM->COM( 'delete_layer', "layer" => $lComp );

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

	#	my $alpha = shift;
	#
	#	if($alpha < 100){
	#		$rgbStr = "\"rgba(" . $rgbStr . ", ".($alpha/100).")\"";
	#
	#	}else{
	#		$rgbStr = "'rgb(" . $rgbStr . ")'";
	#	}

	$rgbStr = "'rgb(" . $rgbStr . ")'";

	return $rgbStr;

}

sub __CheckCountersink {
	my $self      = shift;
	my $layer     = shift;
	my $layerComp = shift;

	if (    $layer->{"type"} ne EnumsGeneral->LAYERTYPE_plt_bMillTop
		 && $layer->{"type"} ne EnumsGeneral->LAYERTYPE_nplt_bMillTop
		 && $layer->{"type"} ne EnumsGeneral->LAYERTYPE_plt_bMillBot
		 && $layer->{"type"} ne EnumsGeneral->LAYERTYPE_nplt_bMillBot )
	{
		return 0;
	}

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $stepName = $self->{"pdfStep"};
	$stepName =~ s/pdf_//;
	my $lName = $layer->{"gROWname"};

	my $result = 1;

	#get depths for all diameter
	my @toolDepths = CamToolDepth->GetToolDepths( $inCAM, $jobId, $stepName, $lName );

	$inCAM->INFO(
				  units       => 'mm',
				  entity_type => 'layer',
				  entity_path => "$jobId/$stepName/$lName",
				  data_type   => 'TOOL',
				  parameters  => 'drill_size+shape',
				  options     => "break_sr"
	);
	my @toolSize  = @{ $inCAM->{doinfo}{gTOOLdrill_size} };
	my @toolShape = @{ $inCAM->{doinfo}{gTOOLshape} };

	# 2) check if tool depth is set
	for ( my $i = 0 ; $i < scalar(@toolSize) ; $i++ ) {

		my $tSize = $toolSize[$i];

		#for each hole diameter, get depth (in mm)
		my $tDepth;

		if ( $tSize == 6500 ) {
			my $prepareOk = CamToolDepth->PrepareToolDepth( $tSize, \@toolDepths, \$tDepth );

			unless ($prepareOk) {

				die "$tSize doesn't has set deep of milling/drilling.\n";
			}

			#vypocitej realne odebrani materialu na zaklade hloubkz pojezdu/vrtani
			# TODO tady se musi dotahnout skutecnz uhel, ne jen 90 stupnu pokazde - ceka az budou kompletne funkcni vrtacky
			my $toolAngl = 90;

			my $newDiameter = tan( deg2rad( $toolAngl / 2 ) ) * $tDepth;
			$newDiameter *= 2;       #whole diameter
			$newDiameter *= 1000;    #um
			$newDiameter = int($newDiameter);

			# now change 6.5mm to new diameter
			CamLayer->WorkLayer( $inCAM, $layerComp );
			CamFilter->BySingleSymbol( $inCAM, "r6500" );
			$inCAM->COM( "sel_change_sym", "symbol" => "r" . $newDiameter, "reset_angle" => "no" );
		}
	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
