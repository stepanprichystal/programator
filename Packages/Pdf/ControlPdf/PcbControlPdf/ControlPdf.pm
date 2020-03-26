
#-------------------------------------------------------------------------------------------#
# Description: Is repsponsible for complete export of control pdf
# Can create TOP/BOT preview of pcb, single layersw previev, stackup previref
# And complete all to one pdf
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::PcbControlPdf::ControlPdf;
use base('Packages::ItemResult::ItemEventMngr');

#3th party library
use utf8;
use strict;
use warnings;
use File::Copy;
use PDF::API2;

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
use aliased 'Packages::Pdf::ControlPdf::PcbControlPdf::HtmlTemplate::TemplateKey';
use aliased 'Packages::Pdf::ControlPdf::PcbControlPdf::HtmlTemplate::FillTemplatePrevInfo';
use aliased 'Packages::Pdf::ControlPdf::PcbControlPdf::HtmlTemplate::FillTemplatePrevImg';
use aliased 'Packages::Pdf::ControlPdf::PcbControlPdf::FinalPreview::FinalPreview';
use aliased 'Packages::Pdf::ControlPdf::PcbControlPdf::FinalPreview::Enums' => "EnumsFinal";
use aliased 'Packages::Pdf::ControlPdf::PcbControlPdf::SinglePreview::SinglePreview';
use aliased 'Packages::Pdf::ControlPdf::PcbControlPdf::StackupPreview::StackupPreview';
use aliased 'Packages::Pdf::ControlPdf::Helpers::OutputFinalPdf';

use aliased 'Packages::NifFile::NifFile';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $inCAM = shift;
	my $jobId = shift;
	my $step = shift;
	my $considerSR = shift;
	my $detailPrev = shift;
	my $lang = shift;
	my $infoToPdf = shift;
	

	my $self = $class->SUPER::new(@_);
	bless $self;

	$self->{"inCAM"}      = $inCAM;
	$self->{"jobId"}      = $jobId;
	$self->{"step"}       = $step;
	$self->{"considerSR"} = $considerSR;    # show preview with step and repat data
	$self->{"detailPrev"} = $detailPrev;    # do separate preview of nested step and repeat
	$self->{"lang"}      = shift;     # language of pdf, values cz/en
	$self->{"infoToPdf"} = shift;


	# 1) Identify steps to process
	my $srExist = CamStepRepeat->ExistStepAndRepeats( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"} );
	die "Step: " . $self->{"step"} . " doesn't contain SR" if ( $self->{"considerSR"} && !$srExist );

	# a) main step
	my @steps = ( { "name" => $self->{"step"}, "containSR" => $srExist, "considerSR" => $self->{"considerSR"}, "isNest" => 0 } );

	# b) nested steps
	if ( $self->{"detailPrev"} ) {
		my @nested = CamStepRepeat->GetUniqueStepAndRepeat( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"} );
		push( @steps, map { { "name" => $_->{"stepName"}, "containSR" => 0, "considerSR" => 0, "isNest" => 1 } } @nested );
	}

	$self->{"steps"}  = \@steps;
	$self->{"titles"} = [];        # page titles

	# 2) Init properties

	$self->{"outputPath"} = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".pdf";            # place where pdf is created
	$self->{"outputPdf"} = OutputFinalPdf->new( $self->{"lang"}, $self->{"infoToPdf"}, $self->{"jobId"} );

	# indication if each parts are required to be in final pdf
	$self->{"previewInfoReq"}  = { "req" => 0, "outfile" => undef };
	$self->{"previewStckpReq"} = { "req" => 0, "outfile" => undef };
	$self->{"previewImgReq"}    = {};                                                                        # kyes are name of steps
	$self->{"previewLayersReq"} = {};

	# Do necessary checks

	$self->__Checks();

	return $self;
}

# Create stackup based on xml, and convert to png
sub AddInfoPreview {
	my $self = shift;
	my $mess = shift // \"";

	my $result = 1;

	my $resultItem = $self->_GetNewItem("General info");

	$self->{"previewInfoReq"}->{"req"} = 1;

	my $tempPath = GeneralHelper->Root() . "\\Packages\\Pdf\\ControlPdf\\PcbControlPdf\\HtmlTemplate\\templateInfo.html";

	# Fill data template
	my $templData = TemplateKey->new();
	my $fillTempl = FillTemplatePrevInfo->new( $self->{"inCAM"}, $self->{"jobId"} );

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

# Create stackup based on xml, and convert to png
sub AddStackupPreview {
	my $self = shift;
	my $mess = shift // \"";

	my $result = 1;

	my $resultItem = $self->_GetNewItem("Stackup");

	$self->{"previewStckpReq"}->{"req"} = 1;

	# 1) create stackup image
	my $prev = StackupPreview->new( $self->{"inCAM"}, $self->{"jobId"} );
	if ( $prev->Create($mess) ) {
		$self->{"previewStckpReq"}->{"outfile"} = $prev->GetOutput();

		# Add page title
		my $title = undef;
		if ( $self->{"lang"} eq "cz" ) {
			$title = "Skladba";
		}
		else {
			$title = "Stackup";
		}

		$self->__AddPageTitle($title);
	}
	else {

		$result = 0;
		$$mess .= "Error during creatin stackup pdf preview\n";
	}

	$self->_OnItemResult($resultItem);    # Raise finish event

	return $result;
}

# Create image of real pcb from top
sub AddImagePreview {
	my $self = shift;
	my $mess = shift // \"";
	my $top = shift // 1;
	my $bot = shift // 1;

	my $result;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	foreach my $sInf ( @{ $self->{"steps"} } ) {
		my $messTop = "";
		my $messBot = "";

		my $resultItemTop = $self->_GetNewItem( "Image TOP - " . $sInf->{"name"} );
		my $resultItemBot = $self->_GetNewItem( "Image BOT - " . $sInf->{"name"} );

		$self->{"previewImgReq"}->{ $sInf->{"name"} }->{"req"} = 1;

		my @layerFilter = map { $_->{"gROWname"} } CamJob->GetBoardLayers( $inCAM, $jobId );
		CamStep->CreateFlattenStep( $inCAM, $jobId, $sInf->{"name"}, $sInf->{"name"} . "_pdf", 1, \@layerFilter );

		my $previewTop = FinalPreview->new( $inCAM, $jobId, $sInf->{"name"} . "_pdf", EnumsFinal->View_FROMTOP );
		my $previewBot = FinalPreview->new( $inCAM, $jobId, $sInf->{"name"} . "_pdf", EnumsFinal->View_FROMBOT );

		unless ( $previewTop->Create( \$messTop ) ) {
			$$mess .= $messTop;
			$resultItemTop->AddError($messTop);
			$result = 0;
		}

		unless ( $previewBot->Create( \$messBot ) ) {
			$$mess .= $messBot;
			$resultItemBot->AddError($messBot);
			$result = 0;
		}

		# Fill data template
		my $templData = TemplateKey->new();
		my $fillTempl = FillTemplatePrevImg->new( $inCAM, $jobId );

		my $pTop = $previewTop->GetOutput();
		my $pBot = $previewBot->GetOutput();

		$fillTempl->FillKeysData( $templData, $pTop, $pBot, $self->{"infoToPdf"} );

		my $templ    = HtmlTemplate->new( $self->{"lang"} );
		my $tempPath = GeneralHelper->Root() . "\\Packages\\Pdf\\ControlPdf\\PcbControlPdf\\HtmlTemplate\\templateImg.html";

		if ( $templ->ProcessTemplatePdf( $tempPath, $templData ) ) {

			$self->{"previewImgReq"}->{ $sInf->{"name"} }->{"outfile"} = $templ->GetOutFile();

			# Add page title

			my $title = undef;
			if ( $self->{"lang"} eq "cz" ) {
				$title = "Dodání";
			}
			else {
				$title = "Shipping units";
			}

			my $detailExist = scalar( grep { $_->{"isNest"} } @{ $self->{"steps"} } );
			if ($detailExist) {
				$title .= " - " . ( !$sInf->{"isNest"} ? "panel" : "single" );
			}

			$self->__AddPageTitle($title);

		}
		else {

			$result = 0;

			my $messTempl = "Error during generate pdf page for top/bot image preview";
			$$mess .= $messTempl;
			$resultItemTop->AddError($messTempl);
			$resultItemBot->AddError($messTempl);
		}

		$self->_OnItemResult($resultItemTop);    # Raise finish event
		$self->_OnItemResult($resultItemBot);    # Raise finish event

		CamStep->DeleteStep( $inCAM, $jobId, $sInf->{"name"} . "_pdf" );
	}

	return $result;
}

sub AddLayersPreview {
	my $self = shift;
	my $mess = shift // \"";

	my $result;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	foreach my $sInf ( @{ $self->{"steps"} } ) {

		my $messL      = "";
		my $resultItem = $self->_GetNewItem( "Single layers TOP - " . $sInf->{"name"} );

		$self->{"previewLayersReq"}->{ $sInf->{"name"} }->{"req"} = 1;

		my $prev = SinglePreview->new( $inCAM, $jobId, $sInf->{"name"}, $sInf->{"considerSR"}, $self->{"lang"} );

		if ( $prev->Create( 1, ( $sInf->{"containSR"} && !$sInf->{"considerSR"} && !$sInf->{"isNest"} ? 1 : 0 ), \$messL ) ) {
			$self->{"previewLayersReq"}->{ $sInf->{"name"} }->{"outfile"} = $prev->GetOutput();

			# Add page title

			my $title = undef;
			if ( $self->{"lang"} eq "cz" ) {
				$title = "Výrobní data";
			}
			else {
				$title = "Production data";
			}

			my $detailExist = scalar( grep { $_->{"isNest"} } @{ $self->{"steps"} } );
			if ($detailExist) {
				$title .= " - " . ( !$sInf->{"isNest"} ? "panel" : "single" );
			}

			my $pdf = PDF::API2->open( $prev->GetOutput() );
			for ( my $i = 0 ; $i < scalar( scalar( $pdf->pages ) ) ; $i++ ) {
				$self->__AddPageTitle($title);
			}
		}
		else {

			$result = 0;
			$$messL .= "Error during generate single layer preview for step: " . $sInf->{"name"};
			$$mess  .= $$messL;
			$resultItem->AddError($$messL);
		}

		$self->_OnItemResult($resultItem);    # Raise finish event
	}

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

	if ( $self->{"previewStckpReq"}->{"req"} && !-e $self->{"previewStckpReq"}->{"outfile"} ) {
		$result = 0;
		$$mess .= "Error when creating stackup preview.\n";
	}

	foreach my $sInf ( @{ $self->{"steps"} } ) {

		my $stepName = $sInf->{"name"};

		if ( $self->{"previewImgReq"}->{$stepName}->{"req"} && !-e $self->{"previewImgReq"}->{$stepName}->{"outfile"} ) {
			$result = 0;
			$$mess .= "Error when creating pcb image preview, for step: $stepName.\n";
		}

		if ( $self->{"previewLayersReq"}->{$stepName}->{"req"} && !-e $self->{"previewLayersReq"}->{$stepName}->{"outfile"} ) {
			$result = 0;
			$$mess .= "Error when creating pcb layers preview, for step: $stepName.\n";
		}
	}

	# 2) complete all together and add header and footer

	if ($result) {

		my @pdfFiles = ();

		push( @pdfFiles, $self->{"previewInfoReq"}->{"outfile"} )  if ( $self->{"previewInfoReq"}->{"req"} );
		push( @pdfFiles, $self->{"previewStckpReq"}->{"outfile"} ) if ( $self->{"previewStckpReq"}->{"req"} );

		foreach my $sInf ( @{ $self->{"steps"} } ) {

			my $stepName = $sInf->{"name"};
			push( @pdfFiles, $self->{"previewImgReq"}->{$stepName}->{"outfile"} ) if ( $self->{"previewImgReq"}->{$stepName}->{"req"} );

		}

		foreach my $sInf ( @{ $self->{"steps"} } ) {

			my $stepName = $sInf->{"name"};
			push( @pdfFiles, $self->{"previewLayersReq"}->{$stepName}->{"outfile"} )
			  if ( $self->{"previewLayersReq"}->{$stepName}->{"req"} );
		}

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

# do some initialiyation, create pdf step in InCAM job
sub __Checks {
	my $self = shift;

	# check when step is panel, nif file already exist too
	my $panelExist = CamHelper->StepExists( $self->{"inCAM"}, $self->{"jobId"}, "panel" );
	my $nifFile = NifFile->new( $self->{"jobId"} );

	if ( $panelExist && !$nifFile->Exist() ) {

		die "If panel exist, nif file has to exist too.";
	}

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

	use aliased 'Packages::Pdf::ControlPdf::PcbControlPdf::ControlPdf';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "d276179";

	my $mess = "";

	my $step = "o+1";
	my $SR = CamStepRepeat->ExistStepAndRepeats( $inCAM, $jobId, $step );

	#my $nested = $SR;
	my $nested = 0;

	my $control = ControlPdf->new( $inCAM, $jobId, $step, 0, $nested, "en", 1 );

	#$control->AddInfoPreview( \$mess );
	#$control->AddStackupPreview( \$mess );
	$control->AddImagePreview( \$mess, 1, 0 );
	#$control->AddLayersPreview( \$mess );
	my $reuslt = $control->GeneratePdf( \$mess );

	unless ($reuslt) {
		print STDERR "Error:" . $mess;
	}

	#
	$control->GetOutputPath();

}

1;
