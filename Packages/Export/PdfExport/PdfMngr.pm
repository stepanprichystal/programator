
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for export pdf control file and pdf stackup file
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::PdfExport::PdfMngr;
use base('Packages::Export::MngrBase');

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
use aliased 'Helpers::FileHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Packages::Pdf::TravelerPdf::StackupPdf::StackupPdf';
use aliased 'Packages::Pdf::TravelerPdf::ProcessStackupPdf::ProcessStackupPdf';
use aliased 'Packages::Pdf::TravelerPdf::CvrlStencilPdf::CvrlStencilPdf';
use aliased 'Packages::Pdf::TravelerPdf::PeelStencilPdf::PeelStencilPdf';
use aliased 'Packages::Pdf::ControlPdf::PcbControlPdf::ControlPdf';
use aliased 'Packages::Pdf::DrawingPdf::DrillMapPdf::DrillMapPdf';
use aliased 'Packages::Pdf::DrawingPdf::NCSpecialPdf::NCSpecialPdf';
use aliased 'Packages::Pdf::DrawingPdf::StiffenerPdf::StiffenerPdf';
use aliased 'Packages::CAMJob::Traveler::ProcessStackupTmpl::ProcessStackupTmpl';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Pdf::DrawingPdf::DrillMapDrillCpnPdf::DrillMapCouponPdf';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class       = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $packageId   = __PACKAGE__;
	my $createFakeL = 1;
	my $self        = $class->SUPER::new( $inCAM, $jobId, $packageId, $createFakeL );
	bless $self;

	$self->{"exportControl"}         = shift;    # if export pdf data contro
	$self->{"controlStep"}           = shift;    # which step export
	$self->{"controlLang"}           = shift;    # which language use
	$self->{"controlInfoToPdf"}      = shift;    # put info about operator to pdf
	$self->{"controlInclNested"}     = shift;    # include nested steps in pdf preview
	$self->{"exportStackup"}         = shift;    # if export stackup pdf to job's archive
	$self->{"exportPressfit"}        = shift;    # if export pressfit pdf
	$self->{"exportToleranceHole"}   = shift;    # if export tolerance hole pdf
	$self->{"exportNCSpecial"}       = shift;    # if export NC special pdf
	$self->{"exportCustCpnIPC3Map"}  = shift;    # Export drill map for customer IPC3 coupon
	$self->{"exportDrillCpnIPC3Map"} = shift;    # Export drill map for drill IPC3 coupon
	$self->{"exportStiffThick"}      = shift;    # if export stiffener thicknessdrawing pdf
	$self->{"exportCvrlStencil"}     = shift;    # if export coverlay stencil pdf
	$self->{"exportPeelStencil"}     = shift;    # if export peelable stencil pdf

	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $self->{'inCAM'}, $self->{'jobId'} );

	return $self;
}

sub Run {
	my $self  = shift;
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

		if ( !JobHelper->GetIsFlex($jobId) ) {

			if ( CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $self->{"jobId"} ) > 2 ) {
				$self->__ExportStackupOld();
			}
		}

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

	if ( $self->{"exportCustCpnIPC3Map"} || $self->{"exportDrillCpnIPC3Map"} ) {
		$self->__ExportIPC3CouponDrillMap();
	}

	if ( $self->{"exportStiffThick"} ) {
		$self->__ExportStiffThick();
	}

	if ( $self->{"exportCvrlStencil"} ) {
		$self->__ExportCvrlStencil();
	}

	if ( $self->{"exportPeelStencil"} ) {
		$self->__ExportPeelStencil();
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

	$controlPdf->{"onItemResult"}->Add( sub { $f->( $self, @_ ) } );

	# 1) Create Info preview

	$controlPdf->AddInfoPreview();

	# 2) Create stackup
	$controlPdf->AddStackupPreview();

	# 3) Create Preview images

	$controlPdf->AddImagePreview();

	# 4) Create single layer preview

	$controlPdf->AddLayersPreview();

	# 5) Generate final pdf
	if ( $controlPdf->GeneratePdf() ) {

		my $errMess = "";
		my $resultFinal = $self->_GetNewItem( "Copy to archive", "Control data" );

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

		if ( copy( $outputPdf, $archivePath ) ) {
			unlink($outputPdf);
		}

		$self->_OnItemResult($resultFinal);
	}

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

	my $resultStackup = $self->_GetNewItem("Production stackup traveler");

	my $pDirTraveler = JobHelper->GetJobArchive($jobId) . "tpvpostup\\";
	my $pDirPdf      = JobHelper->GetJobArchive($jobId) . "pdf\\";

	unless ( -d $pDirTraveler ) {
		die "Unable to create dir: $pDirTraveler" unless ( mkdir $pDirTraveler );
	}

	unless ( -d $pDirPdf ) {
		die "Unable to create dir: $pDirPdf" unless ( mkdir $pDirPdf );
	}

	# 1) Clear old files
	my @stakupTepl = FileHelper->GetFilesNameByPattern( $pDirTraveler, "stackup" );
	unlink($_) foreach (@stakupTepl);

	my @stakupPdf = FileHelper->GetFilesNameByPattern( $pDirPdf, "stackup" );
	unlink($_) foreach (@stakupPdf);

	my $pSerTempl = $pDirTraveler . $jobId . "_template_stackup.txt";
	my $pOutTempl = $pDirTraveler . $jobId . "_template_stackup.pdf";

	my $stackup = ProcessStackupPdf->new($jobId);
	my $procStack = ProcessStackupTmpl->new( $inCAM, $jobId );

	# 2) Check if there is any laminations

	if ( $procStack->LamintaionCnt() ) {

		#my $lamType = ProcStckpEnums->LamType_CVRLPRODUCT;
		my $lamType      = undef;
		my $ser          = "";
		my $resultCreate = $stackup->BuildTemplate( $inCAM, $lamType, \$ser );

		if ($resultCreate) {

			# 1) Output serialized template
			FileHelper->WriteString( $pSerTempl, $ser );

			# 2) Output pdf template
			$stackup->OutputTemplate($lamType);
			unless ( copy( $stackup->GetOutputPath(), $pOutTempl ) ) {
				$resultStackup->AddError( "Can not delete old pdf stackup file (" . $pOutTempl . "). Maybe file is still open.\n" );
			}

			unlink( $stackup->GetOutputPath() );

			# 3) Output all orders in production
			my @PDFOrders = ();
			my @orders    = HegMethods->GetPcbOrderNumbers($jobId);
			@orders = grep { $_->{"stav"} =~ /^4$/ } @orders;    # not ukoncena and stornovana

			push( @PDFOrders, map { { "orderId" => $_->{"reference_subjektu"}, "extraProducId" => 0 } } @orders );

			# Add all extro production
			foreach my $orderId ( map { $_->{"orderId"} } @PDFOrders ) {

				my @extraOrders = HegMethods->GetProducOrderByOrderId( $orderId, undef, "N" );
				@extraOrders = grep { $_->{"cislo_dodelavky"} >= 1 } @extraOrders;
				push( @PDFOrders, map { { "orderId" => $_->{"nazev_subjektu"}, "extraProducId" => $_->{"cislo_dodelavky"} } } @extraOrders );
			}

			my $serFromFile = FileHelper->ReadAsString($pSerTempl);

			foreach my $order (@PDFOrders) {

				$stackup->OutputSerialized( $serFromFile, $order->{"orderId"}, $order->{"extraProducId"} );

				my $pPdf = $pDirPdf . $order->{"orderId"} . "-DD-" . $order->{"extraProducId"} . "_stackup.pdf";

				unless ( copy( $stackup->GetOutputPath(), $pPdf ) ) {
					print STDERR "Can not delete old pdf stackup file (" . $pPdf . "). Maybe file is still open.\n";
				}

				unlink( $stackup->GetOutputPath() );

			}

		}
		else {

			$resultStackup->AddError("Failed to create pdf stackup");
		}
	}
	else {

		die "No lamination exists in job";
	}

	$self->_OnItemResult($resultStackup);
}

sub __ExportStackupOld {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $stackup = StackupPdf->new( $inCAM, $self->{"jobId"} );
	my $resultCreate = $stackup->Create( 1, 1, 1 );

	my $resultStackup = $self->_GetNewItem("Stackup pdf OLD");

	if ($resultCreate) {
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
	}
	else {
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

sub __ExportIPC3CouponDrillMap {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $mergePdf = 0;

	if ( $self->{"exportCustCpnIPC3Map"} && $self->{"exportDrillCpnIPC3Map"} ) {
		$mergePdf = 1;
	}

	my $pdfCustCpnPath = undef;
	if ( $self->{"exportCustCpnIPC3Map"} ) {

		my $pdf = DrillMapCouponPdf->new( $inCAM, $jobId );
		if ( $pdf->CreateIPC3Main() ) {

			my $tmpPath = $pdf->GetPdfPath();

			if ( !$mergePdf ) {
				$pdfCustCpnPath = JobHelper->GetJobArchive($jobId) . "pdf\\" . $jobId . "_CustIPC3Coupon.pdf";

				if ( -e $pdfCustCpnPath ) {
					unless ( unlink($pdfCustCpnPath) ) {
						die "Can not delete old pdf file (" . $pdfCustCpnPath . "). Maybe file is still open.\n";
					}

				}

				copy( $tmpPath, $pdfCustCpnPath ) or die "Copy failed: $!";
				unlink($tmpPath);

			}
			else {
				$pdfCustCpnPath = $tmpPath;
			}

			my $resultCpn = $self->_GetNewItem("Cust IPC3 coupon pdf");

			unless ($resultCpn) {
				$resultCpn->AddError("Failed to create IPC3 coupon pdf");
			}

			$self->_OnItemResult($resultCpn);
		}
	}

	my $pdfDrillCpnPath = undef;
	if ( $self->{"exportDrillCpnIPC3Map"} ) {
		my $pdf = DrillMapCouponPdf->new( $inCAM, $jobId );
		if ( $pdf->CreateIPC3Drill() ) {

			my $tmpPath = $pdf->GetPdfPath();

			if ( !$mergePdf ) {
				$pdfDrillCpnPath = JobHelper->GetJobArchive($jobId) . "pdf\\" . $jobId . "_DrillIPC3Coupon.pdf";

				if ( -e $pdfDrillCpnPath ) {
					unless ( unlink($pdfDrillCpnPath) ) {
						die "Can not delete old pdf file (" . $pdfDrillCpnPath . "). Maybe file is still open.\n";
					}

				}

				copy( $tmpPath, $pdfDrillCpnPath ) or die "Copy failed: $!";
				unlink($tmpPath);

			}
			else {
				$pdfDrillCpnPath = $tmpPath;
			}

			my $resultCpn = $self->_GetNewItem("Drill IPC3 coupon pdf");

			unless ($resultCpn) {
				$resultCpn->AddError("Failed to create IPC3 coupon pdf");
			}

			$self->_OnItemResult($resultCpn);
		}
	}

	if ($mergePdf) {
		use constant mm  => 25.4 / 72;
		use constant a4H => 297;
		use constant a4W => 210;

		my $mergedPdf  = PDF::API2->new();
		my $sourcePdf1 = PDF::API2->open($pdfCustCpnPath);
		my $sourcePdf2 = PDF::API2->open($pdfDrillCpnPath);

		#my $scale = min( $imgHeight / a4H, $imgWidth / a4W );

		# Create nex page
		my $page = $mergedPdf->page();
		$page->mediabox( a4H / mm, a4W / mm );
		my $gfx = $page->gfx();

		# 1) Add source layer
		my $xData1 = $mergedPdf->importPageIntoForm( $sourcePdf1, 0 );
		$gfx->formimage( $xData1, 0, 0, 0.7 );

		my $xData2 = $mergedPdf->importPageIntoForm( $sourcePdf2, 0 );
		$gfx->formimage( $xData2, a4H / 2 / mm, 0, 0.7 );

		my $outputPdf = JobHelper->GetJobArchive($jobId) . "pdf\\" . $jobId . "_IPC3Coupons.pdf";
		$mergedPdf->saveas($outputPdf);

		unlink($sourcePdf1);
		unlink($sourcePdf2);
	}

}

sub __ExportStiffThick {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $pdf = StiffenerPdf->new( $inCAM, $jobId );

	if ( $pdf->CreateStiffPdf() ) {

		my $resultStiff = $self->_GetNewItem("Stiffener thickness pdf");

		my $tmpPath = $pdf->GetPdfPath();

		if ( -e $tmpPath ) {
			

			my $pdfPath = JobHelper->GetJobArchive($jobId) . "pdf\\" . $jobId . "_StiffenerThick.pdf";

			if ( -e $pdfPath ) {
				unless ( unlink($pdfPath) ) {
					die "Can not delete old Stiffener thickness pdf drawing. File (" . $pdfPath . "). Maybe file is still open.\n";
				}
			}

			copy( $tmpPath, $pdfPath ) or die "Copy failed: $!";
			unlink($tmpPath);
		}
		else {
			$resultStiff->AddError("Failed to create pdf Stiffener thickness");
		}

		$self->_OnItemResult($resultStiff);
	}

}

sub __ExportCvrlStencil {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $result = $self->_GetNewItem("Coverlay stencil traveler");

	my $pDirTraveler = JobHelper->GetJobArchive($jobId) . "tpvpostup\\";
	my $pDirPdf      = JobHelper->GetJobArchive($jobId) . "pdf\\";

	unless ( -d $pDirTraveler ) {
		die "Unable to create dir: $pDirTraveler" unless ( mkdir $pDirTraveler );
	}

	unless ( -d $pDirPdf ) {
		die "Unable to create dir: $pDirPdf" unless ( mkdir $pDirPdf );
	}

	# 1) Clear old files
	my @stakupTepl = FileHelper->GetFilesNameByPattern( $pDirTraveler, "cvrlStncl" );
	unlink($_) foreach (@stakupTepl);

	my @stakupPdf = FileHelper->GetFilesNameByPattern( $pDirPdf, "cvrlStncl" );
	unlink($_) foreach (@stakupPdf);

	my $pSerTempl = $pDirTraveler . $jobId . "_template_cvrlstncl.txt";
	my $pOutTempl = $pDirTraveler . $jobId . "_template_cvrlstncl.pdf";

	my $travelerPdf = CvrlStencilPdf->new($jobId);
	my @NClayers =
	  CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, [ EnumsGeneral->LAYERTYPE_nplt_soldcMill, EnumsGeneral->LAYERTYPE_nplt_soldsMill ] );

	# 2) Check if there is any laminations

	if ( scalar(@NClayers) ) {

		#my $lamType = ProcStckpEnums->LamType_CVRLPRODUCT;

		my $ser = "";
		my $resultCreate = $travelerPdf->BuildTemplate( $inCAM, \$ser );

		if ($resultCreate) {

			# 1) Output serialized template
			FileHelper->WriteString( $pSerTempl, $ser );

			# 2) Output pdf template
			$travelerPdf->OutputTemplate();
			unless ( copy( $travelerPdf->GetOutputPath(), $pOutTempl ) ) {
				$result->AddError( "Can not delete old pdf file (" . $pOutTempl . "). Maybe file is still open.\n" );
			}

			unlink( $travelerPdf->GetOutputPath() );

			# 3) Output all orders in production
			my @PDFOrders = ();
			my @orders    = HegMethods->GetPcbOrderNumbers($jobId);
			@orders = grep { $_->{"stav"} =~ /^4$/ } @orders;    # not ukoncena and stornovana

			push( @PDFOrders, map { { "orderId" => $_->{"reference_subjektu"}, "extraProducId" => 0 } } @orders );

			# Add all extro production
			foreach my $orderId ( map { $_->{"orderId"} } @PDFOrders ) {

				my @extraOrders = HegMethods->GetProducOrderByOrderId( $orderId, undef, "N" );
				@extraOrders = grep { $_->{"cislo_dodelavky"} >= 1 } @extraOrders;
				push( @PDFOrders, map { { "orderId" => $_->{"nazev_subjektu"}, "extraProducId" => $_->{"cislo_dodelavky"} } } @extraOrders );
			}

			my $serFromFile = FileHelper->ReadAsString($pSerTempl);

			foreach my $order (@PDFOrders) {

				$travelerPdf->OutputSerialized( $serFromFile, $order->{"orderId"}, $order->{"extraProducId"} );

				my $pPdf = $pDirPdf . $order->{"orderId"} . "-DD-" . $order->{"extraProducId"} . "_cvrlstncl.pdf";

				unless ( copy( $travelerPdf->GetOutputPath(), $pPdf ) ) {
					print STDERR "Can not delete old pdf stackup file (" . $pPdf . "). Maybe file is still open.\n";
				}

				unlink( $travelerPdf->GetOutputPath() );

			}

		}
		else {

			$result->AddError("Failed to create pdf stackup");
		}
	}
	else {

		die "No lamination exists in job";
	}

	$self->_OnItemResult($result);
}

sub __ExportPeelStencil {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $result = $self->_GetNewItem("Peelable stencil traveler");

	my $pDirTraveler = JobHelper->GetJobArchive($jobId) . "tpvpostup\\";
	my $pDirPdf      = JobHelper->GetJobArchive($jobId) . "pdf\\";

	unless ( -d $pDirTraveler ) {
		die "Unable to create dir: $pDirTraveler" unless ( mkdir $pDirTraveler );
	}

	unless ( -d $pDirPdf ) {
		die "Unable to create dir: $pDirPdf" unless ( mkdir $pDirPdf );
	}

	# 1) Clear old files
	my @stakupTepl = FileHelper->GetFilesNameByPattern( $pDirTraveler, "peelstncl" );
	unlink($_) foreach (@stakupTepl);

	my @stakupPdf = FileHelper->GetFilesNameByPattern( $pDirPdf, "peelstncl" );
	unlink($_) foreach (@stakupPdf);

	my $pSerTempl = $pDirTraveler . $jobId . "_template_peelstncl.txt";
	my $pOutTempl = $pDirTraveler . $jobId . "_template_peelstncl.pdf";

	my $travelerPdf = PeelStencilPdf->new($jobId);
	my @NClayers = CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, [ EnumsGeneral->LAYERTYPE_nplt_lcMill, EnumsGeneral->LAYERTYPE_nplt_lsMill ] );

	# 2) Check if there is any laminations

	if ( scalar(@NClayers) ) {

		#my $lamType = ProcStckpEnums->LamType_CVRLPRODUCT;
		my $ser = "";
		my $resultCreate = $travelerPdf->BuildTemplate( $inCAM, \$ser );

		if ($resultCreate) {

			# 1) Output serialized template
			FileHelper->WriteString( $pSerTempl, $ser );

			# 2) Output pdf template
			$travelerPdf->OutputTemplate();
			unless ( copy( $travelerPdf->GetOutputPath(), $pOutTempl ) ) {
				$result->AddError( "Can not delete old pdf file (" . $pOutTempl . "). Maybe file is still open.\n" );
			}

			unlink( $travelerPdf->GetOutputPath() );

			# 3) Output all orders in production
			my @PDFOrders = ();
			my @orders    = HegMethods->GetPcbOrderNumbers($jobId);
			@orders = grep { $_->{"stav"} =~ /^4$/ } @orders;    # not ukoncena and stornovana

			push( @PDFOrders, map { { "orderId" => $_->{"reference_subjektu"}, "extraProducId" => 0 } } @orders );

			# Add all extro production
			foreach my $orderId ( map { $_->{"orderId"} } @PDFOrders ) {

				my @extraOrders = HegMethods->GetProducOrderByOrderId( $orderId, undef, "N" );
				@extraOrders = grep { $_->{"cislo_dodelavky"} >= 1 } @extraOrders;
				push( @PDFOrders, map { { "orderId" => $_->{"nazev_subjektu"}, "extraProducId" => $_->{"cislo_dodelavky"} } } @extraOrders );
			}

			my $serFromFile = FileHelper->ReadAsString($pSerTempl);

			foreach my $order (@PDFOrders) {

				$travelerPdf->OutputSerialized( $serFromFile, $order->{"orderId"}, $order->{"extraProducId"} );

				my $pPdf = $pDirPdf . $order->{"orderId"} . "-DD-" . $order->{"extraProducId"} . "_peelstncl.pdf";

				unless ( copy( $travelerPdf->GetOutputPath(), $pPdf ) ) {
					print STDERR "Can not delete old pdf stackup file (" . $pPdf . "). Maybe file is still open.\n";
				}

				unlink( $travelerPdf->GetOutputPath() );

			}

		}
		else {

			$result->AddError("Failed to create pdf stackup");
		}
	}
	else {

		die "No lamination exists in job";
	}
	$self->_OnItemResult($result);
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

	if ( $self->{"exportCustCpnIPC3Map"} ) {
		$totalCnt += 1;                                        # drill map for customer IPC3 coupon
	}

	if ( $self->{"exportDrillCpnIPC3Map"} ) {
		$totalCnt += 1;                                        # drill map for drill IPC3 coupon
	}

	if ( $self->{"exportStiffThick"} ) {
		$totalCnt += 1;                                        # export stiffener thickness pdf
	}

	if ( $self->{"exportCvrlStencil"} ) {
		$totalCnt += 1;                                        # traveler coverlay stencil
	}

	if ( $self->{"exportPeelStencil"} ) {
		$totalCnt += 1;                                        # traveler peel stencil
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

