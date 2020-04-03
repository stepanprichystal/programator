
#-------------------------------------------------------------------------------------------#
# Description: Module create image preview of pcb based on physical layers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::StencilControlPdf::ImgPreview::ImgPreview;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Pdf::ControlPdf::StencilControlPdf::ImgPreview::LayerData::LayerDataList';
use aliased 'Packages::Pdf::ControlPdf::Helpers::ImgPreview::LayerData::LayerColor';
use aliased 'Packages::Pdf::ControlPdf::StencilControlPdf::ImgPreview::ImgPreviewOut';
use aliased 'Packages::Pdf::ControlPdf::StencilControlPdf::ImgPreview::ImgLayerPrepare';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamHistogram';
use aliased 'CamHelpers::CamJob';
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::Pdf::ControlPdf::StencilControlPdf::ImgPreview::Enums';
use aliased 'Packages::Pdf::ControlPdf::Helpers::ImgPreview::Enums' => 'PrevEnums';
use aliased 'Connectors::HeliosConnector::HegMethods';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}    = shift;
	$self->{"jobId"}    = shift;
	$self->{"pdfStep"}  = shift;
	$self->{"viewType"} = shift;    # TOP/BOT
	$self->{"params"}   = shift;    # Stencil parameters

	$self->{"layerList"} = LayerDataList->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"viewType"} );
	$self->{"imgLayerPrepare"} =
	  ImgLayerPrepare->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"viewType"}, $self->{"pdfStep"}, $self->{"params"} );
	$self->{"outputPath"} = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".png";

	return $self;
}

# Create image preview
sub Create {
	my $self    = shift;
	my $message = shift;

	# 1) Create step
	CamHelper->SetStep( $self->{"inCAM"}, $self->{"step"} );
	CamStep->CreateFlattenStep( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"}, $self->{"pdfStep"}, 0 );
	CamHelper->SetStep( $self->{"inCAM"}, $self->{"pdfStep"} );


	# 2)Get layers for output
	my @layers = CamJob->GetAllLayers( $self->{"inCAM"}, $self->{"jobId"} );

	# set layer list
	$self->{"layerList"}->InitLayers( \@layers );
	$self->{"layerList"}->InitSurfaces( $self->__DefineSurfaces() );

	# 3) Prepare layers for image
	$self->{"imgLayerPrepare"}->PrepareLayers( $self->{"layerList"} );
	
	# 4) Output image
	my $imgOutput = ImgPreviewOut->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"pdfStep"}, $self->{"layerList"}, $self->{"viewType"} );
	$imgOutput->Output( $self->{"layerList"} );

	return 1;
}

# Return path of image
sub GetOutput {
	my $self = shift;

	return $self->{"outputPdf"}->GetOutput();
}

sub __ConvertPdfToPng {
	my $self       = shift;
	my $outputPath = shift;

	my $result = 1;

	my @cmd = ( EnumsPaths->InCAM_3rdScripts . "im\\convert.exe" );
	push( @cmd, "-density 200" );
	push( @cmd, $outputPath );
	push( @cmd, "-shave 20x20 -trim -shave 2x2" );
	push( @cmd, "--alpha off" );

	push( @cmd, $self->{"outputPath"} );

	my $cmdStr = join( " ", @cmd );

	my $systeMres = system($cmdStr);

	unlink($outputPath);

	if ( $systeMres > 0 ) {
		$result = 0;
	}

	return;
}

# Each pcb layer is represent bz color/texture
# this method is responsible for choose this color/texture, transparency, 3d effects, etc..
sub __DefineSurfaces {
	my $self = shift;
	my %clrs = ();

	# final surface of pcb
	my $surface = HegMethods->GetPcbSurface( $self->{"jobId"} );

	# Pcb material
	my $pcbMatClr = LayerColor->new( PrevEnums->Surface_TEXTURE, Enums->Texture_METAL );
	$clrs{ Enums->Type_STNCLMAT } = $pcbMatClr;

	# Cover
	my $pcbCoverClr = LayerColor->new( PrevEnums->Surface_COLOR, "250,250,250" );
	$pcbCoverClr->SetOpaque(45);
	$clrs{ Enums->Type_COVER } = $pcbCoverClr;

	# Holes
	my $holesClr = LayerColor->new( PrevEnums->Surface_COLOR, "0,0,0" );
	$clrs{ Enums->Type_HOLES } = $holesClr;
	$holesClr->Set3DEdges(1);

	# Codes
	my $codesClr = LayerColor->new( PrevEnums->Surface_COLOR, "0,0,0" );
	$clrs{ Enums->Type_CODES } = $codesClr;

	# Profile
	my $profileClr = LayerColor->new( PrevEnums->Surface_COLOR, "230,0,0" );
	$clrs{ Enums->Type_PROFILE } = $profileClr;

	# Data profile
	my $dataProfileClr = LayerColor->new( PrevEnums->Surface_COLOR, "230,0,0" );
	$clrs{ Enums->Type_DATAPROFILE } = $dataProfileClr;

	# Half lasered fiduc
	my $halfFiducClr = LayerColor->new( PrevEnums->Surface_COLOR, "125,125,125" );
	$clrs{ Enums->Type_HALFFIDUC } = $halfFiducClr;

	# Fiduc positions
	my $fiducPosClr = LayerColor->new( PrevEnums->Surface_COLOR, "39,214,62" );
	$clrs{ Enums->Type_FIDUCPOS } = $fiducPosClr;

	return \%clrs;

}

sub Clean {
	my $self        = shift;
 

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	CamStep->DeleteStep( $inCAM, $jobId, $self->{"pdfStep"} );

	# delete helper layers
	foreach my $lData ( $self->{"layerList"}->GetOutputLayers() ) {

		$inCAM->COM( 'delete_layer', "layer" => $lData->GetOutputLayer() );
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Pdf::ControlPdf::StencilControlPdf::ImgPreview::ImgPreview';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "d259045";

	my $mess = "";

	my $control = ImgPreview->new( $inCAM, $jobId, "o+1", "en" );
	$control->Create();

	#$control->CreateStackup(\$mess);
	$control->CreatePreviewTop( \$mess );

	$control->CreatePreviewBot( \$mess );

	#$control->CreatePreviewSingle(\$mess);
	#$control->GeneratePdf();

	#$control->GetOutputPath();

}

1;

