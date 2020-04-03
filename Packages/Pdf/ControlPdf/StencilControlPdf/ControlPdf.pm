
#-------------------------------------------------------------------------------------------#
# Description: Is repsponsible for complete export of control pdf
# Can create image preview of pcb, single layersw previev,
# And complete all to one pdf
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::StencilControlPdf::ControlPdf;
use base('Packages::ItemResult::ItemEventMngr');

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
use aliased 'Packages::Pdf::ControlPdf::StencilControlPdf::ImgPreview::ImgPreview';
use aliased 'Packages::Pdf::ControlPdf::StencilControlPdf::ImgPreview::Enums' => "EnumsFinal";
use aliased 'Packages::Pdf::ControlPdf::StencilControlPdf::SinglePreview::SinglePreview';
use aliased 'Packages::Pdf::ControlPdf::StencilControlPdf::HtmlTemplate::FillTemplatePrevInfo';
use aliased 'Packages::Pdf::ControlPdf::StencilControlPdf::HtmlTemplate::FillTemplatePrevImg';
use aliased 'Packages::Pdf::ControlPdf::Helpers::OutputFinalPdf';
use aliased 'Programs::Stencil::StencilSerializer::StencilSerializer';
use aliased 'Programs::Stencil::StencilCreator::Enums' => 'StnclEnums';
use aliased 'Packages::NifFile::NifFile';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $inCAM     = shift;
	my $jobId     = shift;
	my $step      = shift;
	my $lang      = shift;
	my $infoToPdf = shift;

	my $self = $class->SUPER::new(@_);
	bless $self;

	$self->{"inCAM"}     = $inCAM;
	$self->{"jobId"}     = $jobId;
	$self->{"step"}      = $step;
	$self->{"lang"}      = $lang;        # language of pdf, values cz/en
	$self->{"infoToPdf"} = $infoToPdf;

	# PROPERTIES

	$self->{"pdfStep"}    = "pdf_" . $self->{"step"};
	$self->{"outputPath"} = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".pdf";             # place where pdf is created
	$self->{"outputPdf"}  = OutputFinalPdf->new( $self->{"lang"}, $self->{"infoToPdf"}, $self->{"jobId"} );
	$self->{"params"}     = StencilSerializer->new( $self->{"jobId"} )->LoadStenciLParams();

	$self->{"titles"} = [];                                                                                   # page titles

	# indication if each parts are required to be in final pdf
	$self->{"previewInfoReq"}   = { "req" => 0, "outfile" => undef };
	$self->{"previewImgReq"}    = { "req" => 0, "outfile" => undef };                                         # kyes are name of steps
	$self->{"previewLayersReq"} = { "req" => 0, "outfile" => undef };

	return $self;
}

# Create stackup based on xml, and convert to png
sub AddInfoPreview {
	my $self = shift;
	my $mess = shift // \"";

	my $result = 1;

	my $resultItem = $self->_GetNewItem("General info");

	$self->{"previewInfoReq"}->{"req"} = 1;

	my $tempPath = GeneralHelper->Root() . "\\Packages\\Pdf\\ControlPdf\\StencilControlPdf\\HtmlTemplate\\templateInfo.html";

	# Fill data template
	my $templData = TemplateKey->new();
	my $fillTempl = FillTemplatePrevInfo->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"params"} );

	$fillTempl->FillKeysData( $templData, $self->{"infoToPdf"} );
	$fillTempl->FillKeysLayout($templData);

	my $templ = HtmlTemplate->new( $self->{"lang"} );
	if ( $templ->ProcessTemplatePdf( $tempPath, $templData ) ) {

		$self->{"previewInfoReq"}->{"outfile"} = $templ->GetOutFile();

		# Add page title
		my $title = undef;
		if ( $self->{"lang"} eq "cz" ) {
			$title = "Obecné";
		}
		else {
			$title = "General";
		}

		$self->__AddPageTitle($title);
	}
	else {
		$result = 0;
		$$mess .= "Error during creating preview info page.\n";
	}

	$resultItem->AddError($$mess) unless ($result);    #  Add error to result
	$self->_OnItemResult($resultItem);                 # Raise finish event

	return $result;

}

# Create image of real pcb from top
sub AddImgPreview {
	my $self = shift;
	my $mess = shift // \"";
	
		my $result = 1;
			my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $resultItem = $self->_GetNewItem("Generate img");

	$self->{"previewImgReq"}->{"req"} = 1;

	my $imgPreview = undef;
	if ( $self->{"params"}->GetStencilType() eq StnclEnums->StencilType_TOP || $self->{"params"}->GetStencilType() eq StnclEnums->StencilType_TOPBOT )
	{
		$imgPreview = ImgPreview->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"pdfStep"}, EnumsFinal->View_FROMTOP, $self->{"params"} );
	}
	else {
		$imgPreview = ImgPreview->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"pdfStep"}, EnumsFinal->View_FROMBOT, $self->{"params"} );
	}

	# We create only one preview image which depends

	my $imgPath = undef;
	if ( $imgPreview->Create($mess) ) {
		$imgPath = $imgPreview->GetOutput();
	}
	else {

		$resultItem->AddError($mess);
		$result = 0;
	}

	# 2) Fill data template with images
	my $templData = TemplateKey->new();
	my $fillTempl = FillTemplatePrevImg->new( $inCAM, $jobId );

	$fillTempl->FillKeysData( $templData, $imgPath, $self->{"infoToPdf"} );

	my $templ    = HtmlTemplate->new( $self->{"lang"} );
	my $tempPath = GeneralHelper->Root() . "\\Packages\\Pdf\\ControlPdf\\StencilControlPdf\\HtmlTemplate\\templateImg.html";

	if ( $templ->ProcessTemplatePdf( $tempPath, $templData ) ) {

		unlink($imgPath);

		$self->{"previewImgReq"}->{"outfile"} = $templ->GetOutFile();

		# Add page title

		my $title = undef;
		if ( $self->{"lang"} eq "cz" ) {
			$title = "Dodání";
		}
		else {
			$title = "Shipping units";
		}

		$self->__AddPageTitle($title);

	}
	else {

		$result = 0;

		my $messTempl = "Error during generate pdf page for top/bot image preview";
		$$mess .= $messTempl;

		$resultItem->AddError($messTempl);
	}

	$self->_OnItemResult($resultItem);    # Raise finish event

	$imgPreview->Clean();

	return $result;
}

 

sub AddLayersPreview {
	my $self = shift;
	my $mess = shift // \"";

	my $result = 1;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $messL      = "";
	my $resultItem = $self->_GetNewItem("Single layers");

	$self->{"previewLayersReq"}->{"req"} = 1;

	my $prev = SinglePreview->new( $inCAM, $jobId, $self->{"step"}, $self->{"lang"} );

	if ( $prev->Create( 1, \$messL ) ) {
		$self->{"previewLayersReq"}->{"outfile"} = $prev->GetOutput();

		# Add page title

		my $title = undef;
		if ( $self->{"lang"} eq "cz" ) {
			$title = "Výrobní data";
		}
		else {
			$title = "Production data";
		}

	}
	else {

		$result = 0;
		$$messL .= "Error during generate single layer preview";
		$$mess  .= $$messL;
		$resultItem->AddError($$messL);
	}

	$self->_OnItemResult($resultItem);    # Raise finish event

	return $result;
}

# complete all together and create one single pdf
sub GeneratePdf {
	my $self = shift;
	my $mess = shift // \"";

	my $result = 1;

	my $resultItem = $self->_GetNewItem("Final PDF merge");

	# 1) Before generating pdf, check if all required pages are available

	if ( $self->{"previewInfoReq"}->{"req"} && !-e $self->{"previewInfoReq"}->{"outfile"} ) {
		$result = 0;
		$$mess .= "Error when creating stackup preview.\n";
	}

	if ( $self->{"previewImgReq"}->{"req"} && !-e $self->{"previewImgReq"}->{"outfile"} ) {
		$result = 0;
		$$mess .= "Error when creating image preview.\n";
	}

	if ( $self->{"previewLayersReq"}->{"req"} && !-e $self->{"previewLayersReq"}->{"outfile"} ) {
		$result = 0;
		$$mess .= "Error when creating production layers preview.\n";
	}

	# 2) complete all together and add header and footer

	if ($result) {

		my @pdfFiles = ();

		push( @pdfFiles, $self->{"previewInfoReq"}->{"outfile"} )   if ( $self->{"previewInfoReq"}->{"req"} );
		push( @pdfFiles, $self->{"previewImgReq"}->{"outfile"} )    if ( $self->{"previewImgReq"}->{"req"} );
		push( @pdfFiles, $self->{"previewLayersReq"}->{"outfile"} ) if ( $self->{"previewLayersReq"}->{"req"} );

		$self->{"outputPdf"}->Output( \@pdfFiles, $self->{"titles"} );

	}
	else {
		$resultItem->AddError($$mess);
	}

	$self->_OnItemResult($resultItem);    # Raise finish event

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

	$self->{"fillTemplate"}->Fill( $templData, $previewTopPath, $self->{"infoToPdf"} );

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

sub __AddPageTitle {
	my $self  = shift;
	my $title = shift;

	push( @{ $self->{"titles"} }, $title );
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Pdf::ControlPdf::StencilControlPdf::ControlPdf';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "d276512";

	#	foreach my $l ( CamJob->GetAllLayers( $inCAM, $jobId ) ) {
	#
	#		if ( $l->{"gROWname"} =~ /.*-.*-/i ) {
	#
	#			$inCAM->COM( 'delete_layer', layer => $l->{"gROWname"} );
	#		}
	#	}

	my $mess = "";

	my $control = ControlPdf->new( $inCAM, $jobId, "o+1", "en" );
	$control->AddInfoPreview( \$mess );
	$control->AddImagePreview( \$mess, 1, 1 );
	$control->AddLayersPreview( \$mess );
	my $reuslt = $control->GeneratePdf( \$mess );

	unless ($reuslt) {
		print STDERR "Error:" . $mess;
	}

	#$control->GetOutputPath();

}

1;
