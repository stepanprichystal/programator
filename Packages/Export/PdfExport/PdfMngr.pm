
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for export pdf control file and pdf stackup file
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::PdfExport::PdfMngr;
use base('Packages::ItemResult::ItemEventMngr');

use Class::Interface;
&implements('Packages::Export::IMngr');

#3th party library
use strict;
use warnings;
use File::Copy;

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::Pdf::StackupPdf::StackupPdf';
use aliased 'Packages::Pdf::ControlPdf::ControlPdf';
use aliased 'Packages::Pdf::PressfitPdf::PressfitPdf';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class     = shift;
	my $packageId = __PACKAGE__;
	my $self      = $class->SUPER::new( $packageId, @_ );
	bless $self;

	$self->{"inCAM"}          = shift;
	$self->{"jobId"}          = shift;
	$self->{"exportControl"}  = shift;    # if export pdf data contro
	$self->{"controlStep"}    = shift;    # which step export
	$self->{"controlLang"}    = shift;    # which language use
	$self->{"infoToPdf"}      = shift;    # put info about operator to pdf
	$self->{"exportStackup"}  = shift;    # if export stackup pdf to job's archive
	$self->{"exportPressfit"} = shift;    # if export pressfit pdf

	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $self->{'inCAM'}, $self->{'jobId'} );

	return $self;
}

sub Run {
	my $self = shift;

	my $jobId = $self->{"jobId"};

	# create folder for pdf files
	unless ( -e JobHelper->GetJobArchive($jobId) . "pdf" ) {
		mkdir( JobHelper->GetJobArchive($jobId) . "pdf" );
	}

	if ( $self->{"exportControl"} ) {
		$self->__ExportDataControl();
	}

	if ( $self->{"exportStackup"} ) {
		$self->__ExportStackup();
	}

	if ( $self->{"exportPressfit"} ) {
		$self->__ExportPressfit();
	}

}

sub __ExportDataControl {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $lang = undef;
	if ( $self->{"controlLang"} =~ /english/i ) {
		$lang = "en";
	}
	elsif ( $self->{"controlLang"} =~ /czech/i ) {
		$lang = "cz";
	}

	my $controlPdf = ControlPdf->new( $inCAM, $jobId, $self->{"controlStep"}, $lang, $self->{"infoToPdf"} );

	$controlPdf->Create();

	# 1) Create stackup

	if ( $self->{"layerCnt"} > 2 ) {

		my $resultStackup = $self->_GetNewItem( "Preview stackup", "Control pdf" );

		my $mess1   = "";
		my $result1 = $controlPdf->CreateStackup( \$mess1 );

		unless ($result1) {
			$resultStackup->AddError($mess1);
		}

		$self->_OnItemResult($resultStackup);
	}

	# 2) Create preview top

	my $resultPreviewTop = $self->_GetNewItem( "Preview top", "Control pdf" );

	my $mess2   = "";
	my $result2 = $controlPdf->CreatePreviewTop( \$mess2 );

	unless ($result2) {
		$resultPreviewTop->AddError($mess2);
	}

	$self->_OnItemResult($resultPreviewTop);

	# 3) Create preview bot

	my $resultPreviewBot = $self->_GetNewItem( "Preview bot", "Control pdf" );

	my $mess3   = "";
	my $result3 = $controlPdf->CreatePreviewBot( \$mess3 );

	unless ($result3) {
		$resultPreviewBot->AddError($mess3);
	}

	$self->_OnItemResult($resultPreviewBot);

	# 4) Create preview single

	my $resultSingle = $self->_GetNewItem( "Single layers", "Control pdf" );

	my $mess4   = "";
	my $result4 = $controlPdf->CreatePreviewSingle( \$mess4 );

	unless ($result4) {
		$resultSingle->AddError($mess4);
	}

	$self->_OnItemResult($resultSingle);

	# 5) Final output

	my $resultFinal = $self->_GetNewItem( "Generate pdf", "Control pdf" );

	my $mess5   = "";
	my $result5 = $controlPdf->GeneratePdf( \$mess5 );

	unless ($result5) {
		$resultFinal->AddError($mess5);
	}

	$self->_OnItemResult($resultFinal);

	my $outputPdf = $controlPdf->GetOutputPath();

	unless ( -e $outputPdf ) {
		die "Output pdf control doesnt exist. Failed to create control pdf.\n";
	}

	my $archivePath = JobHelper->GetJobArchive($jobId) . "zdroje\\" . $self->{"jobId"} . "-control.pdf";

	if ( -e $archivePath ) {
		unless ( unlink($archivePath) ) {
			die "Can not delete old pdf control file (" . $archivePath . "). Maybe file is still open.\n";
		}
	}

	copy( $outputPdf, $archivePath );
	unlink($outputPdf);
}

sub __ExportStackup {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $stackup      = StackupPdf->new( $self->{"jobId"} );
	my $resultCreate = $stackup->Create();

	my $tmpPath = $stackup->GetStackupPath();
	my $pdfPath = JobHelper->GetJobArchive($jobId) . "pdf/" . $jobId . "-cm.pdf";

	# create folder
	unless ( -e JobHelper->GetJobArchive($jobId) . "pdf" ) {
		mkdir( JobHelper->GetJobArchive($jobId) . "pdf" );
	}

	if ( -e $pdfPath ) {
		unless ( unlink($pdfPath) ) {
			die "Can not delete old pdf stackup file (" . $pdfPath . "). Maybe file is still open.\n";
		}
	}

	copy( $tmpPath, $pdfPath ) or die "Copy failed: $!";

	my $resultStackup = $self->_GetNewItem("Stackup pdf");

	unless ($resultCreate) {
		$resultStackup->AddError("Failed to create pdf stackup");
	}

	$self->_OnItemResult($resultStackup);

}

sub __ExportPressfit {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $pressfit = PressfitPdf->new( $inCAM, $jobId );
	my $resultCreate = $pressfit->Create("panel");

	my @tmpPahs = $pressfit->GetPressfitPaths();

	my $pdfPath = JobHelper->GetJobArchive($jobId) . "pdf\\" . $jobId . "_pressfit_";

	for ( my $i = 0 ; $i < scalar(@tmpPahs) ; $i++ ) {

		my $f = $pdfPath . ( $i + 1 ) . ".pdf";

		if ( -e $f ) {
			unless ( unlink($f) ) {
				die "Can not delete old pdf pressfit file (" . $f . "). Maybe file is still open.\n";
			}
		}

		copy( $tmpPahs[$i], $f ) or die "Copy failed: $!";
		unlink($tmpPahs[$i]);

	}

	my $resultPressfit = $self->_GetNewItem("Pressfit pdf");

	unless ($resultCreate) {
		$resultPressfit->AddError("Failed to create pdf pressfit");
	}

	$self->_OnItemResult($resultPressfit);

}

sub ExportItemsCount {
	my $self = shift;

	my $totalCnt = 0;

	if ( $self->{"exportControl"} ) {

		if ( $self->{"layerCnt"} > 2 ) {
			$totalCnt += 1;    # stackup preview
		}

		$totalCnt += 2;        # top + bot view
		$totalCnt += 1;        # single output
		$totalCnt += 1;        # output final pdf
	}

	if ( $self->{"exportStackup"} ) {
		$totalCnt += 1;        # output stackup pdf
	}
	
	if ( $self->{"exportPressfit"} ) {
		$totalCnt += 1;        # output pressfit pdf
	}	

	return $totalCnt;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

