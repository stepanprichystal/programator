
#-------------------------------------------------------------------------------------------#
# Description: Modul is responsible for creation pdf stackup from prepared xml definition
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::TravelerPdf::ProcessStackupPdf::ProcessStackupPdf;

#3th party library
use utf8;
use strict;
use warnings;
use English;
use PDF::API2;
use DateTime::Format::Strptime;
use DateTime;
use POSIX qw(floor ceil);
use File::Copy;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::JobHelper';
use aliased 'Packages::CAMJob::Stackup::ProcessStackupTempl::ProcessStackupTempl';
use aliased 'Packages::CAMJob::Stackup::ProcessStackupTempl::Enums' => "ProcStckpEnums";
use aliased 'Packages::Other::TableDrawing::Enums'                  => 'TblDrawEnums';
use aliased 'Packages::Other::TableDrawing::DrawingBuilders::PDFDrawing::PDFDrawing';
use aliased 'Packages::Other::TableDrawing::DrawingBuilders::Enums' => 'EnumsBuilder';
use aliased 'Packages::ObjectStorable::JsonStorable::JsonStorable';
use aliased 'Packages::Other::TableDrawing::TableDrawing';
use aliased 'Packages::Other::TableDrawing::DrawingBuilders::Enums' => 'EnumsDrawBldr';
use aliased 'Packages::Other::TableDrawing::DrawingBuilders::GeometryHelper';
use aliased 'Connectors::HeliosConnector::HegMethods';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#
use constant JSONPAGESEP => "\n\n======= NEW PAGE =======\n\n";

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"jobId"} = shift;

	$self->{"paperWidth"}  = shift // 210;
	$self->{"paperHeight"} = shift // 297;
	$self->{"paperMargin"} = shift // 6;                               # margin of printer
	$self->{"fitInCanvas"} = shift // 1;                               # Scale stackup to PDF page size
	$self->{"HAlign"}      = shift // EnumsDrawBldr->HAlign_MIDDLE;    # Center stackup horizontall at page
	$self->{"VAlign"}      = shift // EnumsDrawBldr->VAlign_MIDDLE;    # Center stackup verticall at page

	$self->{"canvasX"} = $self->{"paperWidth"} - 2 * $self->{"paperMargin"};
	$self->{"canvasY"} = $self->{"paperHeight"} - 2 * $self->{"paperMargin"};

	# Customer stackup class
	# Will be defined after Build function
	$self->{"processStckp"} = undef;
	$self->{"tblDrawings"}  = [];

	$self->{"jsonStorable"} = JsonStorable->new();

	return $self;
}

sub BuildTemplate {
	my $self       = shift;
	my $inCAM      = shift;
	my $lamType    = shift;    # Build only specific lam type
	                           # if defined $serialized reference
	                           # Method store here JSON string which contain array of JSON strings for eeach lamination
	my $serialized = shift;

	my $result = 0;

	# 1) Init customer stackup
	$self->{"processStckp"} = ProcessStackupTempl->new( $inCAM, $self->{"jobId"} );

	# 2) Check if there is any laminations

	my $lamCnt = $self->{"processStckp"}->LamintaionCnt($lamType);

	if ($lamCnt) {

		# 2) Build stackup
		my @tblDrawings = ();
		$result = $self->{"processStckp"}->Build( $self->{"canvasX"}, $self->{"canvasY"}, \@tblDrawings, $lamType );

		if ( defined $serialized ) {

			$$serialized = $self->__GetJSON( \@tblDrawings );

		}

		$self->{"tblDrawings"} = \@tblDrawings;
	}

	return $result;

}

# Output stackup template to PDF file
sub OutputTemplate {
	my $self    = shift;
	my $lamType = shift;    # Build only specific lam type

	die "Process stackup is not defined" unless ( defined $self->{"processStckp"} );

	my $result = 1;

	my $lamCnt       = $self->{"processStckp"}->LamintaionCnt($lamType);
	my @drawBuilders = ();
	my @lamFiles     = ();

	for ( my $i = 0 ; $i < $lamCnt ; $i++ ) {

		# 11 Prepare IDrawer and Table drawing
		my $p = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".pdf";
		unlink($p);

		my $IDrawer = PDFDrawing->new( TblDrawEnums->Units_MM, $p, undef, [ $self->{"canvasX"}, $self->{"canvasY"} ], $self->{"paperMargin"} );
		my $tblDraw = $self->{"tblDrawings"}->[$i];

		my ( $scaleX, $scaleY ) = 1;

		( $scaleX, $scaleY ) = GeometryHelper->ScaleDrawingInCanvasSize( $tblDraw, $IDrawer ) if ( $self->{"fitInCanvas"} );
		my $xOffset = GeometryHelper->HAlignDrawingInCanvasSize( $tblDraw, $IDrawer, $self->{"HAlign"}, $scaleX, $scaleY );
		my $yOffset = GeometryHelper->VAlignDrawingInCanvasSize( $tblDraw, $IDrawer, $self->{"VAlign"}, $scaleX, $scaleY );

		unless ( $tblDraw->Draw( $IDrawer, $scaleX, $scaleY, $xOffset, $yOffset ) ) {

			print STDERR "Error during build lamination process id: $i";
			$result = 0;
		}

		push( @lamFiles, $p );
	}

	# Merge all togehter to output file

	$self->__MergeLamPDF( \@lamFiles );

	return $result;
}

# Output stackup serialized Template to PDF file
# Following values will be replaced:
# - Order number
# - Order date
# - Order term
# - Number of Dodelavka
# - All items where is necessery consider amount of production panel
sub OutputSerialized {
	my $self    = shift;
	my $JSONstr = shift;
	my $lamType = shift;    # Build only specific lam type

	# Values for replace
	my $orderId    = shift;
	my $extraOrder = shift;

	die "JSON string is not defined " unless ( defined $JSONstr );
	die "Order Id is not defined "    unless ( defined $orderId );

	$self->__UpdateJSONTemplate( \$JSONstr, $orderId, $extraOrder );

	my $result = 1;

	my @JSONLam = split( JSONPAGESEP, $JSONstr );

	my $lamCnt = scalar(@JSONLam);

	my @drawBuilders = ();
	my @lamFiles     = ();
	for ( my $i = 0 ; $i < $lamCnt ; $i++ ) {

		# 11 Prepare IDrawer and Table drawing
		my $p = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".pdf";
		unlink($p);

		my $IDrawer = PDFDrawing->new( TblDrawEnums->Units_MM, $p, undef, [ $self->{"canvasX"}, $self->{"canvasY"} ], $self->{"paperMargin"} );
		my $tblDraw = TableDrawing->new( TblDrawEnums->Units_MM );

		$tblDraw->LoadSerialized( $JSONLam[$i] );

		my ( $scaleX, $scaleY ) = 1;

		( $scaleX, $scaleY ) = GeometryHelper->ScaleDrawingInCanvasSize( $tblDraw, $IDrawer ) if ( $self->{"fitInCanvas"} );
		my $xOffset = GeometryHelper->HAlignDrawingInCanvasSize( $tblDraw, $IDrawer, $self->{"HAlign"}, $scaleX, $scaleY );
		my $yOffset = GeometryHelper->VAlignDrawingInCanvasSize( $tblDraw, $IDrawer, $self->{"VAlign"}, $scaleX, $scaleY );

		unless ( $tblDraw->Draw( $IDrawer, $scaleX, $scaleY, $xOffset, $yOffset ) ) {

			print STDERR "Error during build lamination process id: $i";
			$result = 0;
		}

		push( @lamFiles, $p );
	}

	# Merge all togehter to output file

	$self->__MergeLamPDF( \@lamFiles );

	return $result;

}

sub GetOutputPath {
	my $self = shift;

	return $self->{"outputPath"};
}

sub __UpdateJSONTemplate {
	my $self       = shift;
	my $JSONstr    = shift;
	my $orderId    = shift;
	my $extraOrder = shift;    # number of extra production

	my $infoIS = undef;

	if ( $extraOrder > 0 ) {
		$infoIS = ( HegMethods->GetProducOrderByOederId( $orderId, $extraOrder, "N" ) )[0];
	}
	else {
		$infoIS = { HegMethods->GetAllByOrderId($orderId) };
	}

	my ($orderNum) = $orderId =~ m/\w\d{6}-(\d+)/;

	my $pattern          = DateTime::Format::Strptime->new( pattern => '%Y-%m-%d %H:%M:%S', );
	my $orderDate        = $pattern->parse_datetime( $infoIS->{"datum_zahajeni"} )->dmy('.');    # start order date;
	my $orderTerm        = $pattern->parse_datetime( $infoIS->{"termin"} )->dmy('.');            # order term;
	my $orderExtraProduc = $extraOrder;

	my $orderAmount    = undef;
	my $orderAmountExt = undef;
	my $orderAmountTot = undef;

	if ( $extraOrder > 0 ) {

		$orderAmount    = $infoIS->{"prirezy_dodelavka"};
		$orderAmountExt = 0;
		$orderAmountTot = $infoIS->{"prirezy_dodelavka"};

	}
	else {
		$orderAmount    = $infoIS->{"pocet_prirezu"};
		$orderAmountExt = $infoIS->{"prirezu_navic"};
		$orderAmountTot = $infoIS->{"pocet_prirezu"} + $infoIS->{"prirezu_navic"};
	}

	my $v_KEYORDERNUM = ProcStckpEnums->KEYORDERNUM;
	$$JSONstr =~ s/$v_KEYORDERNUM/$orderNum/ig;

	my $v_KEYORDERDATE = ProcStckpEnums->KEYORDERDATE;
	$$JSONstr =~ s/$v_KEYORDERDATE/$orderDate/ig;

	my $v_KEYORDERTERM = ProcStckpEnums->KEYORDERTERM;
	$$JSONstr =~ s/$v_KEYORDERTERM/$orderTerm/ig;

	my $v_KEYORDEAMOUNTTOT = ProcStckpEnums->KEYORDEAMOUNTTOT;
	$$JSONstr =~ s/$v_KEYORDEAMOUNTTOT\((\d+)\)/(($orderAmount+$orderAmountExt)*$1)."x"/eg;

	my $v_KEYORDEAMOUNT = ProcStckpEnums->KEYORDEAMOUNT;
	$$JSONstr =~ s/$v_KEYORDEAMOUNT/$orderAmount/g;

	my $v_KEYORDEAMOUNTEXT = ProcStckpEnums->KEYORDEAMOUNTEXT;
	$$JSONstr =~ s/$v_KEYORDEAMOUNTEXT/$orderAmountExt/g;

	my @JSONstrUpdt = ();
	foreach my $pageStr ( split( JSONPAGESEP, $$JSONstr ) ) {
		my $v_KEYTOTALPACKG = ProcStckpEnums->KEYTOTALPACKG;
		my ($pcbPerPackg)   = $pageStr =~ m/$v_KEYTOTALPACKG\((\d+\.?\d*)\)/g;
		my $packgPerOrder   = ceil( $orderAmountTot / $pcbPerPackg );

		my $packgPerOrderStr = ceil( $orderAmountTot / $pcbPerPackg ) . "plot (" . ceil( ceil( $orderAmountTot / $pcbPerPackg ) / 2 ) . "plot)";
		$pageStr =~ s/$v_KEYTOTALPACKG\((\d+\.?\d*)\)/$packgPerOrderStr/eg;

		push( @JSONstrUpdt, $pageStr );
	}
	$$JSONstr = join( JSONPAGESEP, @JSONstrUpdt );

	my $extraOrderStr    = $extraOrder > 0 ? "DODĚLÁVKA Č:" : "";
	my $extraOrderValStr = $extraOrder > 0 ? $extraOrder       : "";
	my $v_KEYEXTRAPRODUC = ProcStckpEnums->KEYEXTRAPRODUC;
	my $v_KEYEXTRAPRODUCVAL = ProcStckpEnums->KEYEXTRAPRODUCVAL;
	$$JSONstr =~ s/$v_KEYEXTRAPRODUC/$extraOrderStr/ig;
	$$JSONstr =~ s/$v_KEYEXTRAPRODUCVAL/$extraOrderValStr/ig;

}

sub __GetJSON {
	my $self        = shift;
	my @tblDrawings = @{ shift(@_) };

	my @refsJSON = ();    # ref to store array of JSON representation of each lamination

	my $result = 1;

	for ( my $i = 0 ; $i < scalar(@tblDrawings) ; $i++ ) {

		my $tblDraw = $tblDrawings[$i];

		my $refJSONLam = "";

		if ( $tblDraw->DrawingToJSON( \$refJSONLam ) ) {
			push( @refsJSON, $refJSONLam );
		}
		else {
			print STDERR "Error during build lamination process id:" . $i;
			$result = 0;
		}
	}

	my $ser = join( JSONPAGESEP, @refsJSON );

	return $ser;
}

sub __MergeLamPDF {
	my $self     = shift;
	my @lamFiles = @{ shift(@_) };

	# Merge all togehter
	# the output file
	$self->{"outputPath"} = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".pdf";

	my $pdf_out = PDF::API2->new( -file => $self->{"outputPath"} );

	my $pagesTotal = 1;

	foreach my $input_file (@lamFiles) {
		my $pdf_in   = PDF::API2->open($input_file);
		my @numpages = ( 1 .. $pdf_in->pages() );

		foreach my $numpage (@numpages) {

			my $page_in  = $pdf_in->openpage($numpage);
			my $page_out = $pdf_out->page(0);

			my @mbox = $page_in->get_mediabox;
			$page_out->mediabox(@mbox);

			my $xo = $pdf_out->importPageIntoForm( $pdf_in, $numpage );

			my $gfx = $page_out->gfx;

			#
			$gfx->formimage(
				$xo,
				0, 0,    # x y
				1
			);

			unlink($input_file);
		}
	}

	$pdf_out->save();

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Pdf::TravelerPdf::ProcessStackupPdf::ProcessStackupPdf';
	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Packages::CAMJob::Stackup::ProcessStackupTempl::Enums' => 'ProcStckpEnums';

	my $inCAM = InCAM->new();

	#my $jobId    = "d087972"; # standard vv 14V
	#my $jobId    = "d152456"; #Outer RigidFLex TOP
	#my $jobId = "d270787";    #Outer RigidFLex BOT
	#my $jobId    = "d261919"; # standard vv 10V
	#my $jobId = "d274753"; # standard vv 8V
	#my $jobId = "d274611"; # standard vv 10V bez postup laminace

	#my $jobId = "d274986";    # standard vv 4V
	#my $jobId = "d266566"; # inner flex
	#my $jobId = "d146753"; # 1v flex
	#my $jobId = "d267628" ; # flex 2v + stiff
	#my $jobId = "d064915"; # neplat
	#my $jobId = "d275112"; # standard 1v
	#my $jobId = "d275162"; # standard 2v

	my $jobId       = "d162595";
	my $pDirStackup = EnumsPaths->Client_INCAMTMPOTHER . "pdfstackup\\";
	my $pDirPdf     = EnumsPaths->Client_INCAMTMPOTHER . "pdf\\";

	unless ( -d $pDirStackup ) {
		die "Unable to create dir: $pDirStackup" unless ( mkdir $pDirStackup );
	}

	unless ( -d $pDirPdf ) {
		die "Unable to create dir: $pDirStackup" unless ( mkdir $pDirPdf );
	}

	my @stakupTepl = FileHelper->GetFilesNameByPattern( $pDirStackup, "stackup" );
	unlink($_) foreach (@stakupTepl);

	my @stakupPdf = FileHelper->GetFilesNameByPattern( $pDirPdf, "stackup" );
	unlink($_) foreach (@stakupPdf);

	my $pSerTempl = $pDirStackup . $jobId . "_template_stackup.txt";
	my $pOutTempl = $pDirStackup . $jobId . "_template_stackup.pdf";

	my $stackup = ProcessStackupPdf->new($jobId);
	my $procStack = ProcessStackupTempl->new( $inCAM, $jobId );

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
				print STDERR "Can not delete old pdf stackup file (" . $pOutTempl . "). Maybe file is still open.\n";
			}

			unlink( $stackup->GetOutputPath() );

			# 3) Output all orders in production
			my @PDFOrders = ();
			my @orders    = HegMethods->GetPcbOrderNumbers($jobId);
			@orders = grep { $_->{"stav"} =~ /^4$/ } @orders;    # not ukoncena and stornovana

			push( @PDFOrders, map { { "orderId" => $_->{"reference_subjektu"}, "extraProducId" => 0 } } @orders );

			# Add all extro production
			foreach my $orderId ( map { $_->{"orderId"} } @PDFOrders ) {

				my @extraOrders = HegMethods->GetProducOrderByOederId( $orderId, undef, "N" );
				@extraOrders = grep { $_->{"cislo_dodelavky"} >= 1 } @extraOrders;
				push( @PDFOrders, map { { "orderId" => $_->{"nazev_subjektu"}, "extraProducId" => $_->{"cislo_dodelavky"} } } @extraOrders );
			}

			my $serFromFile = FileHelper->ReadAsString($pSerTempl);

			foreach my $order (@PDFOrders) {

				$stackup->OutputSerialized( $serFromFile, $lamType, $order->{"orderId"}, $order->{"extraProducId"} );

				my $pPdf = $pDirPdf . $order->{"orderId"} . "-DD-" . $order->{"extraProducId"} . "_stackup.pdf";

				unless ( copy( $stackup->GetOutputPath(), $pPdf ) ) {
					print STDERR "Can not delete old pdf stackup file (" . $pPdf . "). Maybe file is still open.\n";
				}

				unlink( $stackup->GetOutputPath() );

			}

		}
		else {

			print STDERR "ERROR during stackup";
		}
	}
	else {

		print STDERR "Lamination doesnt exist";
	}

}

1;

