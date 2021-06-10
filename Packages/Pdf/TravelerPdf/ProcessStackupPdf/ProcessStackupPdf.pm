
#-------------------------------------------------------------------------------------------#
# Description: Preparing PDF traveler for stackup
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::TravelerPdf::ProcessStackupPdf::ProcessStackupPdf;
use base('Packages::Pdf::TravelerPdf::TravelerPdfBase');

#3th party library
use utf8;
use strict;
use warnings;
use English;
use DateTime::Format::Strptime;
use DateTime;
use File::Copy;
use POSIX qw(floor ceil);

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::JobHelper';
use aliased 'Packages::CAMJob::Traveler::ProcessStackupTmpl::ProcessStackupTmpl';
use aliased 'Packages::CAMJob::Traveler::ProcessStackupTmpl::Enums' => "ProcStckpEnums";
use aliased 'Packages::Pdf::TravelerPdf::CvrlStencilPdf::CvrlStencilBuilder';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamDrilling';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

use constant JSONPAGESEP => "\n\n======= NEW PAGE =======\n\n";

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

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
	my $stackupTmpl = ProcessStackupTmpl->new( $inCAM, $self->{"jobId"}, $lamType );

	# 2) Check if there is any laminations
	my $lamCnt = $stackupTmpl->LamintaionCnt($lamType);

	if ($lamCnt) {

		$result = $self->_BuildTemplate( $inCAM, $stackupTmpl, $serialized );
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
 

# Output stackup serialized Template to PDF file
# Following values will be replaced:
# - Order number
# - Order date
# - Order term
# - Number of Dodelavka
# - All items where is necessery consider amount of production panel
sub __UpdateJSONTemplate {
	my $self       = shift;
	my $JSONstr    = shift;
	my $orderId    = shift;
	my $extraOrder = shift;    # number of extra production

	my $infoIS = undef;

	if ( $extraOrder > 0 ) {
		$infoIS = ( HegMethods->GetProducOrderByOrderId( $orderId, $extraOrder, undef ) )[0];
	}
	else {
		$infoIS = { HegMethods->GetAllByOrderId($orderId) };
	}
	
	die "Order info from IS is not defined" unless(defined $infoIS);

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
	
	 
	$$JSONstr =~ s/$v_KEYORDEAMOUNTTOT/$orderAmountTot/g;
	

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
	my $extraOrderValStr = $extraOrder > 0 ? $extraOrder              : "";
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
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Pdf::TravelerPdf::ProcessStackupPdf::ProcessStackupPdf';
	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Packages::CAMJob::Traveler::ProcessStackupTmpl::Enums' => 'ProcStckpEnums';

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

	my $jobId       = "d322952";
	my $pDirStackup = EnumsPaths->Client_INCAMTMPOTHER . "tpvpostup\\";
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
	my $procStack = ProcessStackupTmpl->new( $inCAM, $jobId );

	# 2) Check if there is any laminations

	if ( $procStack->LamintaionCnt() ) {

		#my $lamType = ProcStckpEnums->LamType_FLEXBASE;
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
			#@orders = grep { $_->{"stav"} =~ /^4$/ } @orders;    # not ukoncena and stornovana

			push( @PDFOrders, map { { "orderId" => $_->{"reference_subjektu"}, "extraProducId" => 0 } } @orders );

			# Add all extro production
			foreach my $orderId ( map { $_->{"orderId"} } @PDFOrders ) {

				my @extraOrders = HegMethods->GetProducOrderByOrderId( $orderId, undef,undef );
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

			print STDERR "ERROR during stackup";
		}
	}
	else {

		print STDERR "Lamination doesnt exist";
	}

}

1;

