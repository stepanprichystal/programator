
#-------------------------------------------------------------------------------------------#
# Description: TifFile - interface for signal layers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::ControlPdf;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'Helpers::JobHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Packages::Pdf::Template2Pdf::Template2Pdf';
use aliased 'Packages::Pdf::ControlPdf::HtmlTemplate::TemplateKey';
use aliased 'Packages::Pdf::ControlPdf::FinalPreview::FinalPreview';
use aliased 'Packages::Pdf::ControlPdf::FinalPreview::Enums' => "EnumsFinal";
use aliased 'Packages::Pdf::ControlPdf::SinglePreview::SinglePreview';
use aliased 'Packages::Pdf::ControlPdf::StackupPreview::StackupPreview';
use aliased 'Packages::Pdf::ControlPdf::OutputPdf';
use aliased 'Packages::Pdf::ControlPdf::FillTemplate';

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

	$self->{"lang"} = shift;

	$self->{"pdfStep"} = "pdf_" . $self->{"step"};

	$self->{"outputPath"} = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".pdf";

	$self->{"outputPdf"} = OutputPdf->new();
	$self->{"fillTemplate"} = FillTemplate->new($self->{"inCAM"}, $self->{"jobId"});

	$self->{"template"}       = Template2Pdf->new( $self->{"lang"} );
	$self->{"stackupPreview"} = StackupPreview->new( $self->{"jobId"} );
	$self->{"previewTop"}     = FinalPreview->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"pdfStep"}, EnumsFinal->View_FROMTOP );
	$self->{"previewBot"}     = FinalPreview->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"pdfStep"}, EnumsFinal->View_FROMBOT );
	$self->{"previewSingle"}  = SinglePreview->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"pdfStep"}, $self->{"lang"} );
	return $self;
}

sub Create {
	my $self = shift;
	
	
	# check when step is panel, nif file already exist
	
	

	CamHelper->SetStep( $self->{"inCAM"}, $self->{"step"} );

	$self->__CreatePdfStep();

	CamHelper->SetStep( $self->{"inCAM"}, $self->{"pdfStep"} );

	# 1) create stackup image
	#$self->{"stackupPreview"}->Create();

	# 2) Final preview top
	#$self->{"previewTop"}->Create();

	# 3) Final preview bot
	#$self->{"previewBot"}->Create();

	# 4) Create preview single
	#$self->{"previewSingle"}->Create();

	# 5) Process template
	$self->__ProcessTemplate( $self->{"stackupPreview"}->GetOutput(), $self->{"previewTop"}->GetOutput(), $self->{"previewBot"}->GetOutput() );

	# 6) complete all together and add header and footer
	$self->{"outputPdf"}->Output();

	$self->__DeletePdfStep( $self->{"pdfStep"} );
}

# delete pdf step
sub __ProcessTemplate {
	my $self          = shift;
	my $stackupPath    = shift;
	my $previewTopPath = shift;
	my $previewBotPath = shift;

	my $tempPath = GeneralHelper->Root() . "\\Packages\\Pdf\\ControlPdf\\HtmlTemplate\\template.html";

	# Fill data template
	my $templData = TemplateKey->new();
 

	$self->{"fillTemplate"}->Fill($templData, $stackupPath, $previewTopPath, $previewBotPath);

	$self->__FillTemplate($templData);

	my $result = $self->{"template"}->Convert( $tempPath, $templData );

	my $outFile = $self->{"template"}->GetOutFile();
}

sub __FillTemplate {
	my $self      = shift;
	my $templData = shift;

	

	#$self->{"template"}->SetJobId("f12345");

}

# create special step, which IPC will be exported from
sub __CreatePdfStep {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $stepPdf = $self->{"pdfStep"};

	#delete if step already exist
	if ( CamHelper->StepExists( $inCAM, $jobId, $stepPdf ) ) {
		$inCAM->COM( "delete_entity", "job" => $jobId, "name" => $stepPdf, "type" => "step" );
	}

	$inCAM->COM(
				 'copy_entity',
				 type             => 'step',
				 source_job       => $jobId,
				 source_name      => $self->{"step"},
				 dest_job         => $jobId,
				 dest_name        => $stepPdf,
				 dest_database    => "",
				 "remove_from_sr" => "yes"
	);

	#check if SR exists in etStep, if so, flattern whole step
	my $srExist = CamStepRepeat->ExistStepAndRepeats( $inCAM, $jobId, $stepPdf );

	if ($srExist) {
		$self->__FlatternPdfStep($stepPdf);
	}
}

sub __FlatternPdfStep {
	my $self    = shift;
	my $stepPdf = shift;
	my $inCAM   = $self->{"inCAM"};
	my $jobId   = $self->{"jobId"};

	CamHelper->SetStep( $self->{"inCAM"}, $stepPdf );

	my @allLayers = CamJob->GetBoardLayers( $inCAM, $jobId );

	foreach my $l (@allLayers) {

		CamLayer->FlatternLayer( $inCAM, $jobId, $stepPdf, $l->{"gROWname"} );
	}

	$inCAM->COM('sredit_sel_all');
	$inCAM->COM('sredit_del_steps');

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

	use aliased 'Packages::Pdf::ControlPdf::ControlPdf';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "f52456";

	my $control = ControlPdf->new( $inCAM, $jobId, "o+1", "en" );

	$control->Create();
}

1;
