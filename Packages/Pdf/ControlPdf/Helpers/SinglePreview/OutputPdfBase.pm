
#-------------------------------------------------------------------------------------------#
# Description: Responsible o create single pdf from prepared LayerDataList strucure
# Author:SPR
#-------------------------------------------------------------------------------------------#
package  Packages::Pdf::ControlPdf::Helpers::SinglePreview::OutputPdfBase;

#3th party library
use strict;
use warnings;
use PDF::API2;
use POSIX;
use List::Util qw[max min];

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Pdf::ControlPdf::PcbControlPdf::SinglePreview::Enums';
use aliased 'Packages::CAMJob::OutputData::Enums' => "OutputEnums";
use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamSymbol';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamHelper';

#-------------------------------------------------------------------------------------------#
# Public method
#-------------------------------------------------------------------------------------------#

use constant mm => 25.4 / 72;
use constant in => 1 / 72;
use constant pt => 1;

use constant a4H => 297;
use constant a4W => 210;

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}      = shift;
	$self->{"jobId"}      = shift;
	$self->{"sourceStep"} = shift;    # contain information about SR while pdfStep don't have to
	$self->{"pdfStep"}    = shift;
	$self->{"lang"}       = shift;
	$self->{"outputPath"} = shift;

	# page margins
	$self->{"margin"}->{"top"}   = 45;    # top page margin [mm] which creates space for title
	$self->{"margin"}->{"bot"}   = 15;
	$self->{"margin"}->{"left"}  = 15;
	$self->{"margin"}->{"right"} = 15;
	$self->{"imgSpaxeH"}         = 5;     # horizontal space betwwen single preview image
	$self->{"imgSpaxeV"}         = 15;    # vertical  space betwwen single preview image

	$self->{"profileLim"} = undef;

	return $self;
}

sub Output {
	my $self           = shift;
	my $layerList      = shift;
	my $multiplX       = shift;
	my $multiplY       = shift;
	my $drawProfile    = shift // 1;
	my $drawProfile1Up = shift // 0;
	my $profColor      = shift // [ 255, 0, 0 ];
	my $prof1UpColor   = shift // [ 0, 255, 0 ];
	my $profWidth      = shift // 500;             # µm
	my $profWidth1Up   = shift // 200;             # µm

	if ( $multiplX < 1 ) {
		die "Multiplicity of image in X axis has to by at least 1";
	}

	if ( $multiplY < 1 ) {
		die "Multiplicity of image in Y axis has to by at least 1";
	}

	my %lim = CamJob->GetProfileLimits( $self->{"inCAM"}, $self->{"jobId"}, $self->{"pdfStep"} );
	$self->{"profileLim"} = \%lim;

	# 1) Prepare profile layers
	my ( $profL, $prof1UpL, $profSpecL, $prof1UpSpecL ) = $self->__PrepareProfiles( $drawProfile, $drawProfile1Up, $profWidth, $profWidth1Up );

	# 2) Optimiye prepared layers (add nageative frame in order to set propar image dim ratio)
	$self->__OptimizeLayers( $layerList, $multiplX, $multiplY, $profL, $prof1UpL, $profSpecL, $prof1UpSpecL );

	# 3) Output pdf form InCAM (plus merge layers with profiles)

	my $pathPdf = $self->__OutputRawPdf( $layerList, $multiplX, $multiplY, $profL, $prof1UpL, $profSpecL, $prof1UpSpecL, $profColor, $prof1UpColor );

	# 4) Addd info boxes ot each image
	$self->__AddTextPdf( $layerList, $multiplX, $multiplY, $pathPdf );

	$self->{"outputPath"} = $pathPdf;

}

sub GetOutput {
	my $self = shift;

	return $self->{"outputPath"};
}

#-------------------------------------------------------------------------------------------#
# Private method
#-------------------------------------------------------------------------------------------#

sub __PrepareProfiles {
	my $self           = shift;
	my $drawProfile    = shift;
	my $drawProfile1Up = shift;
	my $profWidth      = shift // 500;    # 300µm
	my $profWidth1Up   = shift // 100;    # 100µm thinner than score line etc (not entirely cover lazer data)

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $profL        = undef;
	my $prof1UpL     = undef;
	my $profSpecL    = undef;
	my $prof1UpSpecL = undef;

	if ($drawProfile) {
		$profL = GeneralHelper->GetGUID();
		CamMatrix->CreateLayer( $inCAM, $jobId, $profL, "document", "positive", 0 );
		$inCAM->COM( "profile_to_rout", "layer" => $profL, "width" => $profWidth );
		CamLayer->WorkLayer( $inCAM, $profL );
		$inCAM->COM( "sel_design2rout", "rad_tol" => 100 );
		$inCAM->COM( "sel_line2dash", "seg_len" => 1000, "gap_len" => 1000 );
		CamLayer->ClearLayers( $inCAM, $profL );

	}

	if ($drawProfile1Up) {
		$prof1UpL = GeneralHelper->GetGUID();
		CamMatrix->CreateLayer( $inCAM, $jobId, $prof1UpL, "document", "positive", 0 );

		#$inCAM->COM( "profile_to_rout", "layer" => $prof1UpL, "width" => ( $profWidth * 1000 ) );

		die "No step and repeats exist at step:" . $self->{"sourceStep"}
		  if ( $drawProfile1Up && !CamStepRepeat->ExistStepAndRepeats( $inCAM, $jobId, $self->{"sourceStep"} ) );

		my @steps = map { $_->{"stepName"} } CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobId, $self->{"sourceStep"} );

		for ( my $i = 0 ; $i < scalar(@steps) ; $i++ ) {

			my $s = $steps[$i];

			my $name = "1up" . ( scalar(@steps) > 1 ? "(type: " . ( $i + 1 ) . ")" : "" );

			CamHelper->SetStep( $inCAM, $s );
			$inCAM->COM( "profile_to_rout", "layer" => $prof1UpL, "width" => $profWidth1Up );
			CamLayer->WorkLayer( $inCAM, $prof1UpL );
			#$inCAM->COM( "sel_design2rout", "rad_tol" => 100 );
			#$inCAM->COM( "sel_line2dash", "seg_len" => 2000, "gap_len" => 3000 );

			$inCAM->COM(
						 "sr_fill",
						 "type"                    => "predefined_pattern",
						 "cut_prims"               => "no",
						 "predefined_pattern_type" => "lines",
						 "indentation"             => "even",
						 "lines_angle"             => 45,
						 "lines_witdh"             => $profWidth1Up,
						 "lines_dist"              => 4000,
						 "step_margin_x"           => "0",
						 "step_margin_y"           => "0",
						 "step_max_dist_x"         => 1000,
						 "step_max_dist_y"         => 1000,
						 "consider_feat"           => "yes",
						 "feat_margin"             => "1",
						 "dest"                    => "layer_name",
						 "layer"                   => $prof1UpL
			);

			#

		}

		CamHelper->SetStep( $inCAM, $self->{"sourceStep"} );
		CamLayer->FlatternLayer( $inCAM, $jobId, $self->{"sourceStep"}, $prof1UpL );
		CamMatrix->CopyLayer( $inCAM, $jobId, $prof1UpL, $self->{"sourceStep"}, $prof1UpL, $self->{"pdfStep"} );
		CamLayer->ClearLayers( $inCAM, $profL );
		CamHelper->SetStep( $inCAM, $self->{"pdfStep"} );
	}

	if ($drawProfile) {
		$profSpecL = GeneralHelper->GetGUID();
		CamMatrix->CopyLayer( $inCAM, $jobId, $profL, $self->{"pdfStep"}, $profSpecL, $self->{"pdfStep"} );
	}

	if ($drawProfile1Up) {

		$prof1UpSpecL = GeneralHelper->GetGUID();
		CamMatrix->CopyLayer( $inCAM, $jobId, $prof1UpL, $self->{"pdfStep"}, $prof1UpSpecL, $self->{"pdfStep"} ) if ($drawProfile1Up);
	}

	return ( $profL, $prof1UpL, $profSpecL, $prof1UpSpecL );

}

sub __OptimizeLayers {
	my $self         = shift;
	my $layerList    = shift;
	my $multiplX     = shift;
	my $multiplY     = shift;
	my $profL        = shift;
	my $prof1UpL     = shift;
	my $profSpecL    = shift;
	my $prof1UpSpecL = shift;

	my $inCAM  = $self->{"inCAM"};
	my @layers = $layerList->GetLayers();

	# Create border around layer data. Border ratio depands on number of images per page.
	my ( $imgHRatio, $imgWRatio ) = $self->__GetImageSizeByMultipl( $multiplX, $multiplY );

	# 1) Process layers which ARE NOT types: Type_NCDEPTHLAYERS; Type_DRILLMAP (layer data are not behind profile)

	my %lim = CamJob->GetProfileLimits( $inCAM, $self->{"jobId"}, $self->{"pdfStep"} );

	my $x = abs( $lim{"xmax"} - $lim{"xmin"} );
	my $y = abs( $lim{"ymax"} - $lim{"ymin"} );

	my @l = ( grep { $_->GetType() ne OutputEnums->Type_NCDEPTHLAYERS && $_->GetType() ne OutputEnums->Type_DRILLMAP } @layers );
	@l = map { $_->GetOutput() } @l;

	push( @l, $profL )    if ( defined $profL );
	push( @l, $prof1UpL ) if ( defined $prof1UpL );

	$self->__AddFrame( \@l, \%lim, $imgHRatio, $imgWRatio );

	# 2) Process layers which ARE types: Type_NCDEPTHLAYERS; Type_DRILLMAP (layer data are behind profile)
	my %limSpec = ();
	my @lSpec = ( grep { $_->GetType() eq OutputEnums->Type_NCDEPTHLAYERS || $_->GetType() eq OutputEnums->Type_DRILLMAP } @layers );
	@lSpec = map { $_->GetOutput() } @lSpec;

	push( @lSpec, $profSpecL )    if ( defined $profSpecL );
	push( @lSpec, $prof1UpSpecL ) if ( defined $prof1UpSpecL );

	foreach my $l (@lSpec) {

		my %limL = CamJob->GetLayerLimits( $inCAM, $self->{"jobId"}, $self->{"pdfStep"}, $l );

		$limSpec{"xmin"} = $limL{"xmin"} if ( !defined $limSpec{"xmin"} || $limSpec{"xmin"} > $limL{"xmin"} );
		$limSpec{"xmax"} = $limL{"xmax"} if ( !defined $limSpec{"xmax"} || $limSpec{"xmax"} < $limL{"xmax"} );
		$limSpec{"ymin"} = $limL{"ymin"} if ( !defined $limSpec{"ymin"} || $limSpec{"ymin"} > $limL{"ymin"} );
		$limSpec{"ymax"} = $limL{"ymax"} if ( !defined $limSpec{"ymax"} || $limSpec{"ymax"} < $limL{"ymax"} );
	}

	$self->__AddFrame( \@lSpec, \%limSpec, $imgHRatio, $imgWRatio );

	# 3) All layers are printed to single pdf and orientation of "frame" must be equal
	# If oreintation of special layer is different from standard layers, rotate 90°°
	if (@lSpec) {
		my %limStd  = CamJob->GetLayerLimits2( $inCAM, $self->{"jobId"}, $self->{"pdfStep"}, $l[0] );
		my %limSpec = CamJob->GetLayerLimits2( $inCAM, $self->{"jobId"}, $self->{"pdfStep"}, $lSpec[0] );

		my $stdX = abs( $limStd{"xMax"} - $limStd{"xMin"} );
		my $stdY = abs( $limStd{"yMax"} - $limStd{"yMin"} );

		my $specX = abs( $limSpec{"xMax"} - $limSpec{"xMin"} );
		my $specY = abs( $limSpec{"yMax"} - $limSpec{"yMin"} );

		if ( ( $stdX > $stdY && $specX < $specY ) || ( $stdX < $stdY && $specX > $specY ) ) {
			CamLayer->AffectLayers( $inCAM, \@lSpec );
			$inCAM->COM( "sel_transform", "oper" => "rotate", "angle" => 90, "direction" => "ccw" );
			CamLayer->ClearLayers($inCAM);
		}

	}
}

sub __AddFrame {
	my $self      = shift;
	my $layers    = shift;
	my %lim       = %{ shift(@_) };
	my $imgHRatio = shift;
	my $imgWRatio = shift;

	my $inCAM = $self->{"inCAM"};
	my $x     = abs( $lim{"xmax"} - $lim{"xmin"} );
	my $y     = abs( $lim{"ymax"} - $lim{"ymin"} );
	my ( $newX, $newY ) = undef;

	if ( max( $x, $y ) == $x ) {
		$newX = $x;
		$newY = $x / max( $imgHRatio, $imgWRatio ) * min( $imgHRatio, $imgWRatio );
		if ( $newY < $y ) {

			my $d = $y / $newY;
			$newY *= $d;
			$newX *= $d;
		}
	}
	elsif ( max( $x, $y ) == $y ) {
		$newY = $y;
		$newX = $y / max( $imgHRatio, $imgWRatio ) * min( $imgHRatio, $imgWRatio );
		if ( $newX < $x ) {

			my $d = $x / $newX;
			$newX *= $d;
			$newY *= $d;
		}
	}

	# compute min x length

	$lim{"xmin"} -= ( ( $newX - $x ) / 2 );
	$lim{"xmax"} += ( ( $newX - $x ) / 2 );

	$lim{"ymin"} -= ( ( $newY - $y ) / 2 );
	$lim{"ymax"} += ( ( $newY - $y ) / 2 );

	my $maxMill = 3;
	my %c1      = ( "x" => $lim{"xmin"} - $maxMill, "y" => $lim{"ymin"} - $maxMill );
	my %c2      = ( "x" => $lim{"xmax"} + $maxMill, "y" => $lim{"ymin"} - $maxMill );
	my %c3      = ( "x" => $lim{"xmax"} + $maxMill, "y" => $lim{"ymax"} + $maxMill );
	my %c4      = ( "x" => $lim{"xmin"} - $maxMill, "y" => $lim{"ymax"} + $maxMill );
	my @coord   = ( \%c1, \%c2, \%c3, \%c4 );

	CamLayer->ClearLayers($inCAM);

	CamLayer->AffectLayers( $inCAM, $layers );

	CamSymbol->AddPolyline( $inCAM, \@coord, "r1", "negative", 1 );

	CamLayer->ClearLayers($inCAM);
}

# Do output pdf of expor tlayers
sub __OutputRawPdf {
	my $self         = shift;
	my $layerList    = shift;
	my $multiplX     = shift;
	my $multiplY     = shift;
	my $profL        = shift;
	my $prof1UpL     = shift;
	my $profSpecL    = shift;
	my $prof1UpSpecL = shift;
	my $profColor    = shift;
	my $profColor1Up = shift;
	my $titleMargin  = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# 1) Output one pdf per layer

	my $layerStr = join( ";", map { $_->GetOutput() } $layerList->GetLayers() );
	my $sourcePdfPath = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".pdf";
	$sourcePdfPath =~ s/\\/\//g;

	# here was problem, when there is lots of layer, each layer has long name: fdfsd-df78f7d-f7d8f-f7d8f78d
	# Than incam command lenght was long and it doeasnt work
	# So layer are now named as ten position number

	$inCAM->COM(
		'print',
		layer_name        => "$layerStr",
		mirrored_layers   => '',
		draw_profile      => 'no',
		drawing_per_layer => 'yes',
		label_layers      => 'no',
		dest              => 'pdf_file',
		num_copies        => '1',
		dest_fname        => $sourcePdfPath,
		paper_size        => 'A4',

		#		paper_size        => 'custom',
		#		paper_width        => 100,
		#		paper_height        => 100,
		#		paper_units        => 'mm',
		#		scale_to=>0

		nx            => 1,
		ny            => 1,
		orient        => 'none',
		top_margin    => '0',
		bottom_margin => '0',
		left_margin   => '0',
		right_margin  => '0',
		"x_spacing"   => '0',
		"y_spacing"   => '0',

	);

	# 2) output profiles
	my $profPdf        = undef;
	my $prof1UpPdf     = undef;
	my $profSpecPdf    = undef;
	my $prof1UpSpecPdf = undef;

	if ( defined $profL ) {
		my $path = $self->__OutputProfilePdf( $profL, $profColor );
		CamMatrix->DeleteLayer( $inCAM, $jobId, $profL );
		$profPdf = PDF::API2->open($path);

		unlink($path);
	}

	if ( defined $prof1UpL ) {
		my $path = $self->__OutputProfilePdf( $prof1UpL, $profColor1Up );
		CamMatrix->DeleteLayer( $inCAM, $jobId, $prof1UpL );
		$prof1UpPdf = PDF::API2->open($path);
		unlink($path);
	}

	if ( defined $profSpecL ) {
		my $path = $self->__OutputProfilePdf( $profSpecL, $profColor );
		CamMatrix->DeleteLayer( $inCAM, $jobId, $profSpecL );
		$profSpecPdf = PDF::API2->open($path);

		unlink($path);
	}

	if ( defined $prof1UpSpecL ) {
		my $path = $self->__OutputProfilePdf( $prof1UpSpecL, $profColor1Up );
		CamMatrix->DeleteLayer( $inCAM, $jobId, $prof1UpSpecL );
		$prof1UpSpecPdf = PDF::API2->open($path);
		unlink($path);
	}

	# 2) merge page together by page multiplicity

	my $mergedPdf = PDF::API2->new();
	my $sourcePdf = PDF::API2->open($sourcePdfPath);

	unlink($sourcePdfPath);
	my ( $imgHeight, $imgWidth ) = $self->__GetImageSizeByMultipl( $multiplX, $multiplY );

	my $scale = min( $imgHeight / a4H, $imgWidth / a4W );

	my @layers    = $layerList->GetLayers();
	my $lDataCnt  = scalar(@layers);
	my $currLData = 0;

	while ( $currLData < $lDataCnt ) {

		# Create nex page
		my $page = $mergedPdf->page();
		$page->mediabox( a4W / mm, a4H / mm );
		my $gfx = $page->gfx();

		my $posX = $self->{"margin"}->{"left"} / mm;
		my $posY =
		  ( $self->{"margin"}->{"bot"} / mm + ( $multiplY - 1 ) * $self->{"imgSpaxeV"} / mm ) + ( $multiplY - 1 ) * $imgHeight / mm;

		for ( my $r = 0 ; $r < $multiplY ; $r++ ) {

			for ( my $c = 0 ; $c < $multiplX ; $c++ ) {

				my $specProf = $layers[$currLData]->GetType() eq OutputEnums->Type_NCDEPTHLAYERS
				  || $layers[$currLData]->GetType() eq OutputEnums->Type_DRILLMAP ? 1 : 0;

				# 1) Add source layer 
				my $xData = $mergedPdf->importPageIntoForm( $sourcePdf, $currLData + 1 );
				$gfx->formimage( $xData, $posX, $posY, $scale );

				# 2) Add nested  1up steps profiles (above data layer)
				if ( defined $prof1UpL && defined $prof1UpSpecL ) {
					my $xp1Up = $mergedPdf->importPageIntoForm( $specProf ? $prof1UpSpecPdf : $prof1UpPdf, 1 );
					$gfx->formimage( $xp1Up, $posX, $posY, $scale );
				}

				# 3) Add step profile (above data layer)
				if ( defined $profL && defined $profSpecL ) {
					my $xp = $mergedPdf->importPageIntoForm( $specProf ? $profSpecPdf : $profPdf, 1 );
					$gfx->formimage( $xp, $posX, $posY, $scale );
				}

				# Add cover frame
				my $cvrLine = $page->gfx;

				$cvrLine->strokecolor('white');
				$cvrLine->linewidth( 4 / mm );
				$cvrLine->translate( $posX, $posY );
				$cvrLine->scale( $scale, $scale );

				# left vertical
				$cvrLine->move( 0, 0 );
				$cvrLine->line( 0, a4H / mm );
				$cvrLine->stroke;

				# top vertical
				$cvrLine->move( 0, a4H / mm );
				$cvrLine->line( a4W / mm, a4H / mm );
				$cvrLine->stroke;

				# top vertical
				$cvrLine->move( a4W / mm, a4H / mm );
				$cvrLine->line( a4W / mm, 0 );
				$cvrLine->stroke;

				# top vertical
				$cvrLine->move( a4W / mm, 0 );
				$cvrLine->line( 0, 0 );
				$cvrLine->stroke;

				$cvrLine->scale( 1 / $scale, 1 / $scale );
				$cvrLine->translate( -$posX, -$posY );

				#$cvrLine->scale( 1, 1 );
				#$cvrLine->translate( 0, 0 );

				$currLData++;

				last if ( $currLData == $lDataCnt );

				$posX += $imgWidth / mm + $self->{"imgSpaxeH"} / mm;

			}

			last if ( $currLData == $lDataCnt );

			$posY -= ( $imgHeight / mm + $self->{"imgSpaxeV"} / mm );
			$posX = $self->{"margin"}->{"left"} / mm;

		}

	}

	my $outputPdf = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".pdf";
	$mergedPdf->saveas($outputPdf);

	return $outputPdf;
}

sub __OutputProfilePdf {
	my $self  = shift;
	my $profL = shift;
	my $color = shift;

	my $profPdfPath = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".pdf";
	$profPdfPath =~ s/\\/\//g;

	my $inCAM = $self->{"inCAM"};

	$inCAM->COM(
		'print',
		layer_name        => "$profL",
		mirrored_layers   => '',
		draw_profile      => 'no',
		drawing_per_layer => 'no',
		label_layers      => 'no',
		dest              => 'pdf_file',
		num_copies        => '1',
		dest_fname        => $profPdfPath,
		paper_size        => 'A4',
		orient            => 'none',
		top_margin        => '0',                             # margin for page title
		bottom_margin     => '0',
		left_margin       => '0',
		right_margin      => '0',
		"x_spacing"       => '0',
		"y_spacing"       => '0',
		"color1"          => $self->__ConvertColor($color),
	);

	return $profPdfPath;

}

# add title and description to each pdf page for each layer
sub __AddTextPdf {
	my $self        = shift;
	my $layerList   = shift;
	my $multiplX    = shift;
	my $multiplY    = shift;
	my $infile      = shift;
	my $titleMargin = shift;

	unless ( -e $infile ) {
		die "Pdf file doesn't exist $infile.\n";
	}

	my $inCAM = $self->{"inCAM"};

	my $sourcePdf = PDF::API2->open($infile);

	my $imgHeight = ( a4H - $self->{"margin"}->{"top"} - $self->{"margin"}->{"bot"} - ( ( $multiplY - 1 ) * $self->{"imgSpaxeV"} ) ) / $multiplY;
	my $imgWidth =
	  ( a4W - $self->{"margin"}->{"left"} - $self->{"margin"}->{"right"} - ( ( $multiplX - 1 ) * $self->{"imgSpaxeH"} ) ) / $multiplX;
	my $scale = min( $imgHeight / a4H, $imgWidth / a4W );

	my @layers    = $layerList->GetLayers();
	my $lDataCnt  = scalar(@layers);
	my $currLData = 0;
	my $pageIdx   = 1;
	while ( $currLData < $lDataCnt ) {

		# Create nex page
		my $page = $sourcePdf->openpage($pageIdx);

		my $posX = $self->{"margin"}->{"left"} / mm;
		my $posY =
		  ( $self->{"margin"}->{"bot"} / mm + ( $multiplY - 1 ) * $self->{"imgSpaxeV"} / mm ) + ($multiplY) * $imgHeight / mm;

		for ( my $r = 0 ; $r < $multiplY ; $r++ ) {

			for ( my $c = 0 ; $c < $multiplX ; $c++ ) {

				my $l     = $layers[$currLData];
				my $tit   = $l->GetTitle( $self->{"lang"} );
				my $inf   = $l->GetInfo( $self->{"lang"} );
				my $lType = $l->GetOriLayer()->{"gROWlayer_type"};

				my %inf = ( "title" => $tit, "info" => $inf, "lType" => $lType );

				$self->__DrawInfoTable( $posX, $posY, $imgWidth / mm, \%inf, $page, $sourcePdf );

				$currLData++;

				last if ( $currLData == $lDataCnt );
				$posX += $imgWidth / mm + $self->{"imgSpaxeH"} / mm;

			}

			last if ( $currLData == $lDataCnt );
			$posY -= ( $imgHeight / mm + $self->{"imgSpaxeV"} / mm );
			$posX = $self->{"margin"}->{"left"} / mm;
		}

		$pageIdx++;

	}

	#		my $coverLine = $page_out->gfx;
	#		$coverLine->strokecolor('white');
	#		$coverLine->linewidth( 2 / mm );
	#
	#		# left vertical
	#		$coverLine->move( $titleMargin / 2, 0 );
	#		$coverLine->line( $titleMargin / 2, a4H );
	#		$coverLine->stroke;
	#
	#		# middle vertical
	#		$coverLine->move( a4W / 2, 0 );
	#		$coverLine->line( a4W / 2, a4H );
	#		$coverLine->stroke;
	#
	#		# middle vertical
	#		$coverLine->move( a4W - $titleMargin / 2, 0 );
	#		$coverLine->line( a4W - $titleMargin / 2, a4H );
	#		$coverLine->stroke;
	#
	#		# top horizontal
	#		$coverLine->move( 0, a4H - $titleMargin - 4 / mm );
	#		$coverLine->line( a4W, a4H - $titleMargin - 4 / mm );
	#		$coverLine->stroke;
	#
	#		# middle top horizontal
	#		$coverLine->move( 0, a4H - $titleMargin - 123 / mm );
	#		$coverLine->line( a4W, a4H - $titleMargin - 123 / mm );
	#		$coverLine->stroke;
	#
	#		# middle bot horizontal
	#		$coverLine->move( 0, a4H - $titleMargin - 132 / mm );
	#		$coverLine->line( a4W, a4H - $titleMargin - 132 / mm );
	#		$coverLine->stroke;
	#
	#		# middle bot horizontal
	#		$coverLine->move( 0, 4 / mm );
	#		$coverLine->line( a4W, 4 / mm );
	#		$coverLine->stroke;

	$sourcePdf->update();

}

sub __GetPageData {
	my $self      = shift;
	my $layerList = shift;
	my $pageNum   = shift;
	my $cnt       = shift;    # number of page datas (multiplicitz layers per page)

	my @data = ();

	my @layers = $layerList->GetLayers();
	my $start  = ( $pageNum - 1 ) * $cnt;

	for ( my $i = 0 ; $i < $cnt ; $i++ ) {

		my $lData = $layers[ $start + $i ];

		if ($lData) {

			my $tit   = $lData->GetTitle( $self->{"lang"} );
			my $inf   = $lData->GetInfo( $self->{"lang"} );
			my $lType = $lData->GetOriLayer()->{"gROWlayer_type"};

			my %inf = ( "title" => $tit, "info" => $inf, "lType" => $lType );
			push( @data, \%inf );
		}

	}

	return @data;

}

sub __DrawInfoTable {
	my $self     = shift;
	my $xPos     = shift;
	my $yPos     = shift;
	my $tabWidth = shift;
	my $data     = shift;
	my $page     = shift;
	my $pdf      = shift;

	#my $leftClmnW  = 15 / mm;
	#my $rightClmnW = 73 / mm;
	my $leftClmnW  = 14 / mm;
	my $rightClmnW = $tabWidth - $leftClmnW;
	my $topRowH    = 15;
	my $botRowH    = 15;

	# draw frame
	#	my $frame = $page_out->gfx;
	#	$frame->fillcolor('#E5E5E5');
	#	$frame->rect(
	#				  $xPos - 0.5,                     # left
	#				  $yPos - 0.5,                     # bottom
	#				  $leftCellW + $rightCellW + 1,    # width
	#				  $leftCellH + 1                   # height
	#	);

	#	$frame->fill;

	# draw top row
	my $tCell = $page->gfx;
	$tCell->fillcolor('#C9101A');
	$tCell->rect( $xPos, $yPos + $botRowH, $leftClmnW + $rightClmnW, $topRowH );
	$tCell->fill;

	# draw bot row - left cell
	my $lbCell = $page->gfx;
	$lbCell->fillcolor('#F5F5F5');
	$lbCell->rect( $xPos, $yPos, $leftClmnW, $botRowH );
	$lbCell->fill;

	# draw bot row - right cell
	my $rbCell = $page->gfx;
	$rbCell->fillcolor('white');
	$rbCell->rect( $xPos + $leftClmnW, $yPos, $rightClmnW, $botRowH );
	$rbCell->fill;

	#	# draw crosst cell
	#	my $lineV = $page_out->gfx;
	#	$lineV->fillcolor('#E5E5E5');
	#	$lineV->rect(
	#				  $xPos + $leftCellW,          # left
	#				  $yPos,                       # bottom
	#				  0.5,                         # width
	#				  $rightCellH                  # height
	#	);
	#	$lineV->fill;

	#	my $lineH = $page_out->gfx;
	#	$lineH->fillcolor('#E5E5E5');
	#	$lineH->rect(
	#				  $xPos,                       # left
	#				  $yPos + $rightCellH / 2,     # bottom
	#				  $rightCellW + $leftCellW,    # width
	#				  0.5                          # height
	#	);
	#	$lineH->fill;

	my $txtSize   = 3 / mm;
	my $txtMargin = 1.5 / mm;

	# add text title

	my $txtTitle = $page->text;
	$txtTitle->translate( $xPos + $txtMargin, $yPos + $botRowH + $txtMargin );
	my $font = $pdf->ttfont( GeneralHelper->Root() . '\Packages\Pdf\ControlPdf\Helpers\Resources\arial.ttf' );
	$txtTitle->font( $font, $txtSize );
	$txtTitle->fillcolor("white");

	$txtTitle->text( $data->{"title"} );

	# circel
	my $fillColor = '#9800DF';    # special layers are purple

	if ( $data->{"lType"} eq "signal" || $data->{"lType"} eq "power_ground" || $data->{"lType"} eq "mixed" ) {
		$fillColor = "#AE392F";

	}
	elsif ( $data->{"lType"} eq "solder_mask" ) {

		$fillColor = "#3B7129";

	}
	elsif ( $data->{"lType"} eq "silk_screen" ) {

		$fillColor = "#FFFFFF";

	}
	elsif ( $data->{"lType"} eq "coverlay" ) {

		$fillColor = "#FFD319";

	}
	elsif ( $data->{"lType"} eq "drill" || $data->{"lType"} eq "rout" ) {

		$fillColor = "#4E4E4E";
	}

	my $tTag = $page->gfx;

	# Add extra black border
	if ( $data->{"lType"} eq "silk_screen" ) {
		$tTag->fillcolor('#000000');
		$tTag->circle( $xPos + 3 / mm, $yPos + 2.5 / mm, ( 2 * 1.05 ) / mm );
		$tTag->fill;
	}

	$tTag->fillcolor($fillColor);
	$tTag->circle( $xPos + 3 / mm, $yPos + 2.5 / mm, 2 / mm );
	$tTag->fill;

	# add info

	my $txtInf = $page->text;

	#$txtInf->translate( $xPos + $txtMargin, $yPos + $txtMargin );
	$txtInf->translate( $xPos + $txtMargin + 5 / mm, $yPos + $txtMargin );
	$txtInf->font( $font, $txtSize );
	$txtInf->fillcolor("black");

	if ( $self->{"lang"} eq "cz" ) {
		$txtInf->text('Pozn.');
	}
	else {
		$txtInf->text('Note');
	}

	# add info text

	my $txtInfTxt = $page->text;

	#$txtInf->translate( $xPos + $txtMargin, $yPos + $txtMargin );
	$txtInfTxt->translate( $xPos + $txtMargin + $leftClmnW, $yPos + $txtMargin );

	if ( $txtSize * length( $data->{"info"} ) > $rightClmnW ) {

		$txtSize = $rightClmnW / length( $data->{"info"} ) * 2.2;

	}

	$txtInfTxt->font( $font, $txtSize );
	$txtInfTxt->fillcolor("black");

	$txtInfTxt->text( $data->{"info"} );

}

sub __ConvertColor {
	my $self = shift;
	my ( $r, $g, $b ) = @{ shift(@_) };

	my $clr = sprintf( "%.2d", 99 * $r / 255 ) . sprintf( "%.2d", 99 * $g / 255 ) . sprintf( "%.2d", 99 * $b / 255 );

	return $clr

}

sub __GetImageSizeByMultipl {
	my $self     = shift;
	my $multiplX = shift;
	my $multiplY = shift;

	my $imgHRatio = ( a4H - $self->{"margin"}->{"top"} - $self->{"margin"}->{"bot"} - ( ( $multiplY - 1 ) * $self->{"imgSpaxeV"} ) ) / $multiplY;
	my $imgWRatio =
	  ( a4W - $self->{"margin"}->{"left"} - $self->{"margin"}->{"right"} - ( ( $multiplX - 1 ) * $self->{"imgSpaxeH"} ) ) / $multiplX;

	return ( $imgHRatio, $imgWRatio );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

