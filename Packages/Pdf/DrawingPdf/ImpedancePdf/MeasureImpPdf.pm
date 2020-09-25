
#-------------------------------------------------------------------------------------------#
# Description: Export impedance measurement PDF
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::DrawingPdf::ImpedancePdf::MeasureImpPdf;
use base('Packages::ItemResult::ItemEventMngr');

#3th party library
use strict;
use warnings;
use PDF::API2;

#local library
use aliased 'Enums::EnumsImp';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::ItemResult::ItemResult';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamFilter';
use aliased 'CamHelpers::CamSymbol';
use aliased 'CamHelpers::CamStepRepeatPnl';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Packages::CAM::InStackJob::InStackJob';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Helpers::ValueConvertor';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class = shift;

	my $self = $class->SUPER::new(@_);
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	$self->{"outputPath"} = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".pdf";    # place where pdf is created

	return $self;
}

sub Create {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @outputPaths = ();

	# Impedance job
	my $inStackJob = InStackJob->new($jobId);
	my $stackup    = Stackup->new($inCAM, $jobId);

	# get impedance steps

	my @steps = CamStepRepeatPnl->GetUniqueNestedStepAndRepeat( $inCAM, $jobId );

	my @constr = sort { $a->GetTrackLayer(1) cmp $b->GetTrackLayer(1) } $inStackJob->GetConstraints();

	#my $impExist = 0;
	for ( my $i = 0 ; $i < scalar(@constr) ; $i++ ) {

		my $c = $constr[$i];
		foreach my $step (@steps) {

			my %attHist = CamHistogram->GetAttHistogram( $inCAM, $jobId, $step->{"stepName"}, $c->GetTrackLayer(1), 0 );

			if ( $attHist{".imp_constraint_id"} ) {
				
				my $resultItem = $self->_GetNewItem( "Impedance id: ".$c->GetId() );
				$resultItem->SetGroup("Impedance pdf:");

				CamHelper->SetStep( $inCAM, $step->{"stepName"} );

				my $dataLayer = $self->__PrepareDataLayer($c);
				my $impLayer = $self->__PrepareImpLayer( $step->{"stepName"}, $c, $i + 1, scalar(@constr), $stackup );

				push( @outputPaths, $self->__ImgPreviewOut( $step->{"stepName"}, $dataLayer, $impLayer ) );
				
				$self->_OnItemResult($resultItem);
			}
		}
	}

	# Merge all pdf file
	$self->__MergeAndImgPreviewOut(\@outputPaths);


	return 1;
}

# Return all stacku paths
sub GetPdfOutput {
	my $self = shift;

	return $self->{"outputPath"};
}

#-------------------------------------------------------------------------------------------#
# Private methods
#-------------------------------------------------------------------------------------------#

sub __PrepareDataLayer {
	my $self       = shift;
	my $constraint = shift;
	my $trackLayer = $constraint->GetTrackLayer(1);

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $lName = GeneralHelper->GetGUID();
	$inCAM->COM( "merge_layers",    "source_layer" => $trackLayer, "dest_layer" => $lName );
	$inCAM->COM( "profile_to_rout", "layer"        => $lName,      "width"      => "300" );

	return $lName;
}

sub __PrepareImpLayer {
	my $self           = shift;
	my $step           = shift;
	my $constraint     = shift;
	my $constrOrder    = shift;
	my $constraintsCnt = shift;
	my $stackup        = shift;

	my $trackLayer = $constraint->GetTrackLayer(1);

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $lName = GeneralHelper->GetGUID();

	CamLayer->WorkLayer( $inCAM, $trackLayer );

	# prepare pads

	if ( CamFilter->SelectBySingleAtt( $inCAM, $jobId, ".imp_constraint_id", { "min" => $constraint->GetId(), "max" => $constraint->GetId() } ) ) {

		CamLayer->CopySelOtherLayer( $inCAM, [$lName] );

	}
	else {

		die "No impedance lines selected (.imp_constraint_id = " . $constraint->GetId() . ")";
	}

	# prepare title
	CamLayer->WorkLayer( $inCAM, $lName );
	my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $step );

	my $l0Text = uc($jobId);
	CamSymbol->AddText( $inCAM, $l0Text, { "x" => $lim{"xMin"}, "y" => $lim{"yMax"} + 30 }, 4, undef, 1.5 );

	my $l1Text = " Impedance measurement $constrOrder/$constraintsCnt";
	CamSymbol->AddText( $inCAM, $l1Text, { "x" => $lim{"xMin"}, "y" => $lim{"yMax"} + 24 }, 4, undef, 1.5 );

	my $l2Text = "Layer     : $trackLayer; base Cu = " . $stackup->GetCuLayer($trackLayer)->GetThick() . "um";
	CamSymbol->AddText( $inCAM, $l2Text, { "x" => $lim{"xMin"}, "y" => $lim{"yMax"} + 18 }, 2, undef, 1.0 );

	my $l3Text = "Type      : " . ValueConvertor->GetImpedanceType( $constraint->GetType() );
	CamSymbol->AddText( $inCAM, $l3Text, { "x" => $lim{"xMin"}, "y" => $lim{"yMax"} + 14 }, 2, undef, 1.0 );

	my $l4Text = "Parameters: ";
	$l4Text .= "w = " . sprintf( "%.0f", $constraint->GetParamDouble("WB") ) . "um";

	if ( $constraint->GetType() eq EnumsImp->Type_DIFF || $constraint->GetType() eq EnumsImp->Type_CODIFF ) {
		$l4Text .= "; s = " . sprintf( "%.0f", $constraint->GetParamDouble("S") ) . "um";
	}
	CamSymbol->AddText( $inCAM, $l4Text, { "x" => $lim{"xMin"}, "y" => $lim{"yMax"} + 10 }, 2, undef, 1.0 );
	
	my $l5Text = "InStack id: " .  ( $constraint->GetId() );
	CamSymbol->AddText( $inCAM, $l5Text, { "x" => $lim{"xMin"}, "y" => $lim{"yMax"} + 6 }, 2, undef, 1.0 );

	return $lName;
}

sub __ImgPreviewOut {
	my $self      = shift;
	my $step      = shift;
	my $dataLayer = shift;
	my $impLayer  = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $layerStr = $dataLayer . ";" . $impLayer;

	my $pdfFile = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".pdf";
	$pdfFile =~ s/\\/\//g;

	CamHelper->SetStep( $inCAM, $step );

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
				 top_margin        => '5',
				 bottom_margin     => '5',
				 left_margin       => '5',
				 right_margin      => '5',
				 "x_spacing"       => '0',
				 "y_spacing"       => '0',
				 "color1"          => '808080',
				 "color2"          => '990000'
	);

	$inCAM->COM( 'delete_layer', "layer" => $dataLayer );
	$inCAM->COM( 'delete_layer', "layer" => $impLayer );

	return $pdfFile;
}


sub __MergeAndImgPreviewOut {
	my $self    = shift;
	my @inFiles = @{ shift(@_) };
	 
	my $resultItem = $self->_GetNewItem( "Impedance pdf merge" ); 
	 

	# the output file
	my $pdf_out = PDF::API2->new( -file => $self->{"outputPath"} );

	my $pagesTotal = 1;

	foreach my $input_file (@inFiles) {
		my $pdf_in   = PDF::API2->open($input_file);
		my @numpages = ( 1 .. $pdf_in->pages() );

		foreach my $numpage (@numpages) {

			my $page_in = $pdf_in->openpage($numpage);

			#
			#		#
			#		# create a new page
			#		#
			my $page_out = $pdf_out->page(0);

			#
			my @mbox = $page_in->get_mediabox;
			$page_out->mediabox(@mbox);

			#
			my $xo = $pdf_out->importPageIntoForm( $pdf_in, $numpage );

			#
			#		#
			#		# lay up the input page in the output page
			#		# note that you can adjust the position and scale, if required
			#		#
			my $gfx = $page_out->gfx;

			#
			$gfx->formimage(
				$xo,
				0, 0,    # x y
				1
			);           # scale
 
			$pagesTotal++;

		}
	}

	$pdf_out->save();
	
	
	# remove tmp files
	foreach my $f ( @inFiles ) {
		unlink($f);
	}
	
	$self->_OnItemResult($resultItem);
}


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Pdf::DrawingPdf::ImpedancePdf::MeasureImpPdf';

	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "d291827";

	my $export = MeasureImpPdf->new( $inCAM, $jobId );
	$export->Create();

}

1;

