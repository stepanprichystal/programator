
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
use aliased 'Packages::Pdf::Template2Pdf::Template2Pdf';
use aliased 'Packages::Pdf::ControlPdf::HtmlTemplate::TemplateKey';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	$self->{"lang"} = "en";

	#$self->{"step"}  = shift;

	#$self->{"outputPdf"} = OutputPdf->new();

	return $self;
}

# delete pdf step
sub __ProcessTemplate {
	my $self = shift;

	my $tempPath = GeneralHelper->Root() . "\\Packages\\Pdf\\ControlPdf\\HtmlTemplate\\template.html";

	# Fill data template
	my $templData = TemplateKey->new();

	$templData->SetJobId("f12345");

	my $convertor = Template2Pdf->new( $self->{"lang"} );

	my $result = $convertor->Convert( $tempPath, $templData );

	print STDERR "Result of converion: " . $result . ".\n";

	my $outFile = $convertor->GetOutFile();
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

	my $control = ControlPdf->new( $inCAM, $jobId );

	$control->__ProcessTemplate();

}

1;

