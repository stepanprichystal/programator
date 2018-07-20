
#-------------------------------------------------------------------------------------------#
# Description: Export pad info PDF
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::StnclExport::MeasureData::MeasureDataPdf;
use base('Packages::ItemResult::ItemEventMngr');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::ItemResult::ItemResult';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamFilter';
use aliased 'CamHelpers::CamSymbol';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class = shift;

	my $self = $class->SUPER::new(@_);
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	$self->{"step"} = "panel";    # step which stnecil data are exported from

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

	my @paths = ();
	$self->{"outputPaths"} = \@paths;

	CamHelper->SetStep( $inCAM, $step );

	my $dataLayer = $self->__PrepareDataLayer($stencilLayer);
	my $padLayer = $self->__PreparePadLayer( $step, $stencilLayer, $feats, $title );
	$self->__OutputPdf( $step, $dataLayer, $padLayer );
	
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
	my $self         = shift;
	my $stencilLayer = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $lName = GeneralHelper->GetGUID();
	$inCAM->COM( "merge_layers",    "source_layer" => $stencilLayer, "dest_layer" => $lName );
	$inCAM->COM( "profile_to_rout", "layer"        => $lName,        "width"      => "300" );

	return $lName;
}

sub __PreparePadLayer {
	my $self         = shift;
	my $step         = shift;
	my $stencilLayer = shift;
	my @featsId      = @{ shift(@_) };
	my $title        = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $lName = GeneralHelper->GetGUID();

	CamLayer->WorkLayer( $inCAM, $stencilLayer );

	# prepare pads

	if ( CamFilter->SelectByFeatureIndexes( $inCAM, $jobId, \@featsId ) ) {

		CamLayer->CopySelOtherLayer( $inCAM, [$lName] );

	}
	else {

		die "No pad features selected";
	}

	# prepare title
	CamLayer->WorkLayer( $inCAM, $lName );
	my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $step );

	CamSymbol->AddText( $inCAM, $title, { "x" => $lim{"xMin"}, "y" => $lim{"yMax"} +2 }, 4, undef, 1.5 );

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

