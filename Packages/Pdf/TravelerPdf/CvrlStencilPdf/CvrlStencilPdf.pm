
#-------------------------------------------------------------------------------------------#
# Description: Modul is responsible for creating coverlay stencil traveler
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::TravelerPdf::CvrlStencilPdf::CvrlStencilPdf;
use base('Packages::Pdf::TravelerPdf::TravelerPdfBase');

#3th party library
use utf8;
use strict;
use warnings;
use English;
use DateTime::Format::Strptime;
use DateTime;
use File::Copy;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::JobHelper';
use aliased 'Packages::CAMJob::Traveler::UniTravelerTmpl::UniTravelerTmpl';
use aliased 'Packages::Pdf::TravelerPdf::CvrlStencilPdf::CvrlStencilBuilder';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamDrilling';
use aliased 'Packages::CAMJob::Traveler::UniTravelerTmpl::Enums' => 'UniTrvlEnums';
#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	return $self;
}

sub BuildTemplate {
	my $self       = shift;
	my $inCAM      = shift;
	my $serialized = shift;

	my $result = 0;

	my $jobId = $self->{"jobId"};

	# 1) Init traveler

	my @NClayers =
	  CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, [ EnumsGeneral->LAYERTYPE_nplt_soldcMill, EnumsGeneral->LAYERTYPE_nplt_soldsMill ] );

	if ( scalar(@NClayers) ) {

		my @bldrs = ();
		foreach my $NC (@NClayers) {
			push( @bldrs, CvrlStencilBuilder->new( $inCAM, $jobId, $NC->{"gROWname"} ) );
		}

		my $UniTravelerTmpl = UniTravelerTmpl->new( $inCAM, $jobId, \@bldrs );

		# 2) Check build traveler
		my $buildTraveler = 1;

		if ($buildTraveler) {

			$result = $self->_BuildTemplate( $inCAM, $UniTravelerTmpl, $serialized );
		}
	}

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

	# Values for replace
	my $orderId    = shift;
	my $extraOrder = shift;

	die "JSON string is not defined " unless ( defined $JSONstr );
	die "Order Id is not defined "    unless ( defined $orderId );

	$self->__UpdateJSONTemplate( \$JSONstr, $orderId, $extraOrder );

	my $result = 1;

	$self->_OutputSerialized( $JSONstr, $orderId, $extraOrder );

	return $result;

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

	my $v_KEYORDERNUM = UniTrvlEnums->KEYORDERNUM;
	$$JSONstr =~ s/$v_KEYORDERNUM/$orderNum/ig;

	my $v_KEYORDERDATE = UniTrvlEnums->KEYORDERDATE;
	$$JSONstr =~ s/$v_KEYORDERDATE/$orderDate/ig;

	my $v_KEYORDERTERM = UniTrvlEnums->KEYORDERTERM;
	$$JSONstr =~ s/$v_KEYORDERTERM/$orderTerm/ig;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Pdf::TravelerPdf::CvrlStencilPdf::CvrlStencilPdf';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	#my $jobId    = "d152456"; #Outer RigidFLex TOP
	my $jobId = "d270787";    #Outer RigidFLex BOT
	                          #my $jobId = "d266566"; # inner flex
	                          #my $jobId = "d146753"; # 1v flex
	                          #my $jobId = "d267628";    # flex 2v + stiff

	#my $jobId       = "d162595";
	my $pDirTraveler = EnumsPaths->Client_INCAMTMPOTHER . "tpvpostup\\";
	my $pDirPdf      = EnumsPaths->Client_INCAMTMPOTHER . "pdf\\";

	unless ( -d $pDirTraveler ) {
		die "Unable to create dir: $pDirTraveler" unless ( mkdir $pDirTraveler );
	}

	unless ( -d $pDirPdf ) {
		die "Unable to create dir: $pDirPdf" unless ( mkdir $pDirPdf );
	}

	my @stakupTepl = FileHelper->GetFilesNameByPattern( $pDirTraveler, "Cvrl" );
	unlink($_) foreach (@stakupTepl);

	my @stakupPdf = FileHelper->GetFilesNameByPattern( $pDirPdf, "Cvrl" );
	unlink($_) foreach (@stakupPdf);

	my $pSerTempl = $pDirTraveler . $jobId . "_template_Cvrlstncl.txt";
	my $pOutTempl = $pDirTraveler . $jobId . "_template_Cvrlstncl.pdf";

	my $travelerPDF = CvrlStencilPdf->new($jobId);

	# 2) Check if there is any laminations

	if (1) {

		#my $lamType = ProcStckpEnums->LamType_CvrlPRODUCT;
		my $lamType      = undef;
		my $ser          = "";
		my $resultCreate = $travelerPDF->BuildTemplate( $inCAM, \$ser );
		if ($resultCreate) {

			# 1) Output serialized template
			FileHelper->WriteString( $pSerTempl, $ser );

			# 2) Output pdf template
			$travelerPDF->OutputTemplate($lamType);
			unless ( copy( $travelerPDF->GetOutputPath(), $pOutTempl ) ) {
				print STDERR "Can not delete old pdf stackup file (" . $pOutTempl . "). Maybe file is still open.\n";
			}

			unlink( $travelerPDF->GetOutputPath() );

			# 3) Output all orders in production
			my @PDFOrders = ();
			my @orders    = HegMethods->GetPcbOrderNumbers($jobId);
			#@orders = grep { $_->{"stav"} =~ /^4$/ } @orders;    # not ukoncena and stornovana

			push( @PDFOrders, map { { "orderId" => $_->{"reference_subjektu"}, "extraProducId" => 0 } } @orders );

			# Add all extro production
			foreach my $orderId ( map { $_->{"orderId"} } @PDFOrders ) {

				my @extraOrders = HegMethods->GetProducOrderByOederId( $orderId, undef, "N" );
				@extraOrders = grep { $_->{"cislo_dodelavky"} >= 1 } @extraOrders;
				push( @PDFOrders, map { { "orderId" => $_->{"nazev_subjektu"}, "extraProducId" => $_->{"cislo_dodelavky"} } } @extraOrders );
			}

			my $serFromFile = FileHelper->ReadAsString($pSerTempl);

			foreach my $order (@PDFOrders) {

				$travelerPDF->OutputSerialized( $serFromFile, $order->{"orderId"}, $order->{"extraProducId"} );

				my $pPdf = $pDirPdf . $order->{"orderId"} . "-DD-" . $order->{"extraProducId"} . "_cvrlstncl.pdf";

				unless ( copy( $travelerPDF->GetOutputPath(), $pPdf ) ) {
					print STDERR "Can not delete old pdf stackup file (" . $pPdf . "). Maybe file is still open.\n";
				}

				unlink( $travelerPDF->GetOutputPath() );

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

