
#-------------------------------------------------------------------------------------------#
# Description: Is repsponsible for complete export of control pdf
# Can create image preview of pcb, single layersw previev,  
# And complete all to one pdf
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::StencilControlPdf::ControlPdf;

#3th party library
use utf8;
use strict;
use warnings;
use File::Copy;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamStep';
use aliased 'Helpers::JobHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Packages::Other::HtmlTemplate::HtmlTemplate';
use aliased 'Packages::Pdf::ControlPdf::StencilControlPdf::HtmlTemplate::TemplateKey';
use aliased 'Packages::Pdf::ControlPdf::StencilControlPdf::FinalPreview::FinalPreview';
use aliased 'Packages::Pdf::ControlPdf::StencilControlPdf::FinalPreview::Enums' => "EnumsFinal";
use aliased 'Packages::Pdf::ControlPdf::StencilControlPdf::SinglePreview::SinglePreview';
use aliased 'Packages::Pdf::ControlPdf::StencilControlPdf::FillTemplate';
use aliased 'Packages::Pdf::ControlPdf::Helpers::OutputFinalPdf';
use aliased 'Packages::NifFile::NifFile';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
	$self->{"step"}  = shift;

	$self->{"lang"}      = shift;    # language of pdf, values cz/en
	$self->{"infoToPdf"} = shift;

	$self->{"pdfStep"} = "pdf_" . $self->{"step"};

	$self->{"outputPath"} = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".pdf";    # place where pdf is created

	$self->{"outputPdf"} = OutputFinalPdf->new( $self->{"lang"} );
	$self->{"fillTemplate"} = FillTemplate->new( $self->{"inCAM"}, $self->{"jobId"} );

	$self->{"template"}      = HtmlTemplate->new( $self->{"lang"} );
	$self->{"previewTop"}    = FinalPreview->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"pdfStep"}, EnumsFinal->View_FROMTOP );
	$self->{"previewSingle"} = SinglePreview->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"}, $self->{"lang"} );

	return $self;
}

# do some initialiyation, create pdf step in InCAM job
sub Create {
	my $self = shift;
 

	CamHelper->SetStep( $self->{"inCAM"}, $self->{"step"} );

	CamStep->CreateFlattenStep( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"}, $self->{"pdfStep"}, 0 );
 
	CamHelper->SetStep( $self->{"inCAM"}, $self->{"pdfStep"} );
}

# Create image of real pcb from top
sub CreatePreview {
	my $self = shift;
	my $mess = shift;

	# 2) Final preview top
	my $result = $self->{"previewTop"}->Create($mess);
	return $result;
}

# Create pdf preview of single layers
sub CreatePreviewSingle {
	my $self = shift;
	my $mess = shift;

	# 4) Create preview single
	my $result = $self->{"previewSingle"}->Create($mess);
	return $result;
}

# complete all together and create one single pdf
sub GeneratePdf {
	my $self = shift;
	my $mess = shift;

	my $result = 1;

	# 5) Process template
	$self->__ProcessTemplate(   $self->{"previewTop"}->GetOutput() );

	# 6) complete all together and add header and footer
	
	my @pdfFiles = ($self->{"template"}->GetOutFile(), $self->{"previewSingle"}->GetOutput() );
	my @titles = $self->__GetPdfPageTitles();
	
	$self->{"outputPdf"}->Output(\@pdfFiles, \@titles );
	$self->__DeletePdfStep( $self->{"pdfStep"} );

	return $result;
}

# Return final pdf file
sub GetOutputPath {
	my $self = shift;

	return $self->{"outputPdf"}->GetOutput();
}

# Layout of first page is created by HTML template
# Template must by first filled by data
sub __ProcessTemplate {
	my $self           = shift;
	my $previewTopPath = shift;
	
	#$previewTopPath = EnumsPaths->Client_INCAMTMPOTHER.'757CE9C1-6C1E-1014-8973-FDD56CB4D31D.jpeg';

	unless ( -e $previewTopPath ) {
		die "Error when creating stencil image, view from top.\n";
	}
 
	my $tempPath = GeneralHelper->Root() . "\\Packages\\Pdf\\ControlPdf\\StencilControlPdf\\HtmlTemplate\\template.html";

	# Fill data template
	my $templData = TemplateKey->new();

	$self->{"fillTemplate"}->Fill( $templData, $previewTopPath,  $self->{"infoToPdf"} );

	my $result = $self->{"template"}->ProcessTemplatePdf( $tempPath, $templData );

	unlink($previewTopPath);
}
 
 
# Return pdf titles from first to last page
sub __GetPdfPageTitles {
	my $self = shift;

	my @titles = ();

	my $title = "Production preview: ";

	if ( $self->{"lang"} eq "cz" ) {
		$title = "Předvýrobní náhled: ";
	}

	# 1 page
	if ( $self->{"lang"} eq "cz" ) {
		push( @titles, $title . "Obecné" );
	}
	else {
		push( @titles, $title . "General" );
	}

	# 2 page
	if ( $self->{"lang"} eq "cz" ) {
		push( @titles, $title . "Jednotlivé vrstvy" );
	}
	else {
		push( @titles, $title . "Single layer data" );
	}
 

	 return @titles;
} 

# delete pdf step
sub __DeletePdfStep {
	my $self    = shift;
	my $stepPdf = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	#delete if step already exist
	if ( CamHelper->StepExists( $inCAM, $jobId, $stepPdf ) ) {
		$inCAM->COM( "delete_entity", "job" => $jobId, "name" => $stepPdf, "type" => "step" );
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Pdf::ControlPdf::StencilControlPdf::ControlPdf';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "d251561";

	foreach my $l ( CamJob->GetAllLayers( $inCAM, $jobId ) ) {
		
		if ( $l->{"gROWname"} =~ /.*-.*-/i ) {
			
			$inCAM->COM( 'delete_layer', layer => $l->{"gROWname"} );
		}
	}

	my $mess = "";

	my $control = ControlPdf->new( $inCAM, $jobId, "o+1", "en" );
	$control->Create();
 
	$control->CreatePreview( \$mess );
	$control->CreatePreviewSingle(\$mess);
	$control->GeneratePdf();

	#$control->GetOutputPath();

}

1;
