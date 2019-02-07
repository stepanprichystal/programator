
#-------------------------------------------------------------------------------------------#
# Description: Export pad info PDF
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ImpedancePdf::MeasureImpPdf;
use base('Packages::ItemResult::ItemEventMngr');

#3th party library
use strict;
use warnings;

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
	my $self         = shift;
	my $step         = shift;
	my $stencilLayer = shift;
	my $feats        = shift;                                                                        # array of feat id
	my $title        = shift;                                                                        # text placed under stencil data

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# Impedance job
	my $inStackJob = InStackJob->new($jobId);
	my $stackup = Stackup->new($jobId);

	# get impedance steps

	my @steps = CamStepRepeatPnl->GetUniqueNestedStepAndRepeat( $inCAM, $jobId );

	my @constr = sort { $a->GetTrackLayer(1) <=> $b->GetTrackLayer(1) } $inStackJob->GetConstraints();

	#my $impExist = 0;

	foreach my $c (@constr) {

		foreach my $step (@steps) {

			my %attHist = CamHistogram->GetAttHistogram( $inCAM, $jobId, $step->{"stepName"}, $c->GetTrackLayer(1) );

			if ( $attHist{".imp_constraint_id"} ) {

				CamHelper->SetStep( $inCAM, $step );

				my $dataLayer = $self->__PrepareDataLayer($c);
				my $impLayer  = $self->__PrepareImpLayer($c, $stackup);

				$self->__OutputPdf( $step, $dataLayer, $padLayer );
			}
		}
	}

	#splice @steps, $i, 1 unless ( scalar @{ $steps[$i]->{"impLayers"} } );

	#$inCAM->COM( 'delete_layer', layer => $dataLayer );
	#$inCAM->COM( 'delete_layer', layer => $padLayer );

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
	my $self       = shift;
	my $constraint = shift;
	my $stackup = shift;

	my $trackLayer = $constraint->GetTrackLayer(1);

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $lName = GeneralHelper->GetGUID();

	CamLayer->WorkLayer( $inCAM, $trackLayer );

	# prepare pads

	if ( CamFilter->SelectBySingleAtt( $inCAM, $jobId, ".imp_constraint_id", $constraint->GetId() ) ) {

		CamLayer->CopySelOtherLayer( $inCAM, [$lName] );

	}
	else {

		die "No impedance lines selected (.imp_constraint_id = ".$constraint->GetId().")";
	}

	# prepare title
	CamLayer->WorkLayer( $inCAM, $lName );
	my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $step );

	my $l1Text = "$jobId Impedance measurement";
	CamSymbol->AddText( $inCAM, $l1Text, { "x" => $lim{"xMin"}, "y" => $lim{"yMax"} + 20 }, 4, undef, 1.5 );
	
	my $l2Text = "Layer: $trackLayer, ". $stackup->GetThickByLayerName($trackLayer). "um";
	CamSymbol->AddText( $inCAM, $l2Text, { "x" => $lim{"xMin"}, "y" => $lim{"yMax"} + 14 }, 4, undef, 1.5 );

	my $l3Text = "Type: ".ValueConvertor->GetImpedanceType($constraint->GetType());
	CamSymbol->AddText( $inCAM, $l3Text, { "x" => $lim{"xMin"}, "y" => $lim{"yMax"} + 8 }, 4, undef, 1.5 );
	
	
	my $l4Text = "Parameters: ";
	$l4Text .= "w = ".sprintf( "%.0f", $constraint->GetOption( "CALCULATION_REQ_TRACE_WIDTH", 1 ) );
	
	if($constraint->GetType() eq EnumsImp->Type_DIFF || $constraint->GetType() eq EnumsImp->Type_CODIFF ){
			$l4Text .= "s = ".sprintf( "%.0f", $constraint->GetOption( "CALCULATION_REQ_TRACE_WIDTH", 1 ) );
	}

	
	my $l4Text = "Parameters: ".ValueConvertor->GetImpedanceType($constraint->GetType());
	CamSymbol->AddText( $inCAM, $l4Text, { "x" => $lim{"xMin"}, "y" => $lim{"yMax"} + 8 }, 4, undef, 1.5 );

	return $lName;
}

sub __OutputPdf {
	my $self      = shift;
	my $step      = shift;
	my $dataLayer = shift;
	my $padLayer  = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $layerStr = $dataLayer . ";" . $padLayer;

	my $pdfFile = $self->{"outputPath"};
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
				 top_margin        => '0',
				 bottom_margin     => '0',
				 left_margin       => '0',
				 right_margin      => '0',
				 "x_spacing"       => '0',
				 "y_spacing"       => '0',
				 "color1"          => '707070',
				 "color2"          => '990000'
	);

	$inCAM->COM( 'delete_layer', "layer" => $dataLayer );
	$inCAM->COM( 'delete_layer', "layer" => $padLayer );

	return $pdfFile;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Export::StnclExport::DataOutput::ExportDrill';

	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "f13610";

	my $export = ExportDrill->new( $inCAM, $jobId );
	$export->Output();

}

1;

