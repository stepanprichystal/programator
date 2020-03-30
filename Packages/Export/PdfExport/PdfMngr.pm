
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
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Packages::Pdf::StackupPdf::StackupPdf';
use aliased 'Packages::Pdf::ControlPdf::PcbControlPdf::ControlPdf';
use aliased 'Packages::Pdf::DrillMapPdf::DrillMapPdf';
use aliased 'Packages::Pdf::NCSpecialPdf::NCSpecialPdf';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class     = shift;
	my $packageId = __PACKAGE__;
	my $self      = $class->SUPER::new( $packageId, @_ );
	bless $self;

	$self->{"inCAM"}               = shift;
	$self->{"jobId"}               = shift;
	$self->{"exportControl"}       = shift;    # if export pdf data contro
	$self->{"controlStep"}         = shift;    # which step export
	$self->{"controlLang"}         = shift;    # which language use
	$self->{"controlInfoToPdf"}    = shift;    # put info about operator to pdf
	$self->{"controlInclNested"}   = shift;    # include nested steps in pdf preview
	$self->{"exportStackup"}       = shift;    # if export stackup pdf to job's archive
	$self->{"exportPressfit"}      = shift;    # if export pressfit pdf
	$self->{"exportToleranceHole"} = shift;    # if export tolerance hole pdf
	$self->{"exportNCSpecial"}     = shift;    # if export NC special pdf

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

	if ( $self->{"exportToleranceHole"} ) {
		$self->__ExportToleranceHole();
	}

	if ( $self->{"exportNCSpecial"} ) {
		$self->__ExportNCSpecial();
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

	my $considerSR = 0;

	if ( CamStepRepeat->ExistStepAndRepeats( $inCAM, $jobId, $self->{"controlStep"} ) ) {
		$considerSR = $self->{"controlInclNested"} ? 0 : 1;
	}

	my $controlPdf =
	  ControlPdf->new( $inCAM, $jobId, $self->{"controlStep"}, $considerSR, $self->{"controlInclNested"}, $lang, $self->{"controlInfoToPdf"} );

	my $f = sub {
		
		my $self = $_[0];
				my $item = $_[1];
				$item->SetGroup("Control data");
				$self->_OnItemResult($item);
	};

	$controlPdf->{"onItemResult"}->Add(
		sub {$f->($self,@_)}
	);

	# 1) Create Info preview

	$controlPdf->AddInfoPreview();

	# 2) Create stackup
	$controlPdf->AddStackupPreview();

	# 3) Create Preview images

	$controlPdf->AddImagePreview();

	# 4) Create single layer preview

	$controlPdf->AddLayersPreview();

	# 5) Generate final pdf
	my $errMess = "";
	my $resultFinal = $self->_GetNewItem( "Final PDF merge", "Control data" );
	unless ( $controlPdf->GeneratePdf( \$errMess ) ) {
		$resultFinal->AddError("$errMess");
	}

	if ($resultFinal) {

		my $outputPdf = $controlPdf->GetOutputPath();

		unless ( -e $outputPdf ) {
			$resultFinal->AddError("Output pdf control doesnt exist. Failed to create control pdf.\n");
		}

		my $archivePath = JobHelper->GetJobArchive($jobId) . "zdroje\\" . $self->{"jobId"} . "-control.pdf";

		if ( -e $archivePath ) {
			unless ( unlink($archivePath) ) {

				$resultFinal->AddError( "Can not delete old pdf control file (" . $archivePath . "). Maybe file is still open.\n" );
			}
		}

		copy( $outputPdf, $archivePath );
		unlink($outputPdf);
	}

	$self->_OnItemResult($resultFinal);

}

sub __OnExportControl {
	my $self = shift;
	my $item = shift;

	$item->SetGroup("Control data");

	$self->_OnItemResult($item);

}

sub __ExportStackup {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $stackup = StackupPdf->new( $inCAM, $self->{"jobId"} );
	my $resultCreate = $stackup->Create( 1, 1, 1 );

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

	my $pressfit = DrillMapPdf->new( $inCAM, $jobId );
	my $resultCreate = $pressfit->CreatePressfitMeasure("panel");

	my @tmpPahs = $pressfit->GetPdfPaths();

	my $pdfPath = JobHelper->GetJobArchive($jobId) . "pdf\\" . $jobId . "_pressfitHole_";

	for ( my $i = 0 ; $i < scalar(@tmpPahs) ; $i++ ) {

		my $f = $pdfPath . ( $i + 1 ) . ".pdf";

		if ( -e $f ) {
			unless ( unlink($f) ) {
				die "Can not delete old pdf pressfit file (" . $f . "). Maybe file is still open.\n";
			}
		}

		copy( $tmpPahs[$i], $f ) or die "Copy failed: $!";
		unlink( $tmpPahs[$i] );

	}

	my $resultPressfit = $self->_GetNewItem("Pressfit pdf");

	unless ($resultCreate) {
		$resultPressfit->AddError("Failed to create pdf pressfit");
	}

	$self->_OnItemResult($resultPressfit);

}

sub __ExportToleranceHole {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $drillMapPdf = DrillMapPdf->new( $inCAM, $jobId );
	my $resultCreate = $drillMapPdf->CreateToleranceMeasure("panel");

	my @tmpPahs = $drillMapPdf->GetPdfPaths();

	my $pdfPath = JobHelper->GetJobArchive($jobId) . "pdf\\" . $jobId . "_toleranceHole_";

	for ( my $i = 0 ; $i < scalar(@tmpPahs) ; $i++ ) {

		my $f = $pdfPath . ( $i + 1 ) . ".pdf";

		if ( -e $f ) {
			unless ( unlink($f) ) {
				die "Can not delete old pdf tolerance hole file (" . $f . "). Maybe file is still open.\n";
			}
		}

		copy( $tmpPahs[$i], $f ) or die "Copy failed: $!";
		unlink( $tmpPahs[$i] );

	}

	my $resultPressfit = $self->_GetNewItem("Tolerance hole pdf");

	unless ($resultCreate) {
		$resultPressfit->AddError("Failed to create pdf tolerance hole measurement");
	}

	$self->_OnItemResult($resultPressfit);

}

sub __ExportNCSpecial {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $pdf = NCSpecialPdf->new( $inCAM, $jobId );

	if ( $pdf->Create() ) {

		my $tmpPath = $pdf->GetOutputPath();

		my $pdfPath = JobHelper->GetJobArchive($jobId) . "pdf\\" . $jobId . "_NCCountersink.pdf";

		if ( -e $pdfPath ) {
			unless ( unlink($pdfPath) ) {
				die "Can not delete old countersink pdf file (" . $pdfPath . "). Maybe file is still open.\n";
			}
		}

		copy( $tmpPath, $pdfPath ) or die "Copy failed: $!";
		unlink($tmpPath);

		my $resultNCSpecial = $self->_GetNewItem("NC countersink pdf");

		unless ($resultNCSpecial) {
			$resultNCSpecial->AddError("Failed to create pdf NC countersink");
		}

		$self->_OnItemResult($resultNCSpecial);
	}

}

sub TaskItemsCount {
	my $self = shift;

	my $totalCnt = 0;

	if ( $self->{"exportControl"} ) {

		$totalCnt += 1;                                        # preview info
		$totalCnt += 1;                                        # stackup preview
		$totalCnt += 2;                                        # top + bot view
		$totalCnt += 2 if ( $self->{"controlInclNested"} );    # top + bot view nested
		$totalCnt += 1;                                        # single output
		$totalCnt += 1 if ( $self->{"controlInclNested"} );    # single output  nested
		$totalCnt += 1;                                        # output final pdf
	}

	if ( $self->{"exportStackup"} ) {
		$totalCnt += 1;                                        # output stackup pdf
	}

	if ( $self->{"exportPressfit"} ) {
		$totalCnt += 1;                                        # output pressfit pdf
	}

	if ( $self->{"exportToleranceHole"} ) {
		$totalCnt += 1;                                        # output tolerances pdf
	}

	if ( $self->{"exportNCSpecial"} ) {
		$totalCnt += 1;                                        # output nc special pdf
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

