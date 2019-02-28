
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for ipc file creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::ImpExport::ImpMngr;
use base('Packages::ItemResult::ItemEventMngr');

use Class::Interface;
&implements('Packages::Export::IMngr');

#3th party library
use strict;
use warnings;
use File::Copy;
use Log::Log4perl qw(get_logger :levels);

#local library

use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::JobHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::CAMJob::Stackup::StackupConvertor';
use aliased 'Packages::Pdf::ImpedancePdf::MeasureImpPdf';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class     = shift;
	my $packageId = __PACKAGE__;
	my $self      = $class->SUPER::new( $packageId, @_ );
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	$self->{"exportPdf"}     = shift;    # export measurement pdf
	$self->{"exportStackup"} = shift;    # export stackup

	return $self;
}

sub Run {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# Export measurement pdf
	if ( $self->{"exportPdf"} ) {

		my $export = MeasureImpPdf->new( $inCAM, $jobId );

		$export->{"onItemResult"}->Add( sub { $self->_OnItemResult(@_) } );

		if ( $export->Create() ) {

			my $pdfArchive = JobHelper->GetJobArchive($jobId) . "pdf\\" . $jobId . "_imp_drawing.pdf";
			if ( -e $pdfArchive ) {
				unless ( unlink($pdfArchive) ) {
					die "Can not delete old impedance pdf file (" . $pdfArchive . "). Maybe file is still open.\n";
				}
			}

			copy( $export->GetPdfOutput(), $pdfArchive );
			unlink( $export->GetPdfOutput() );
		}
	}

	# Export
	if ( $self->{"exportStackup"} ) {

		my $convertor = StackupConvertor->new($jobId);
		my $res       = $convertor->DoConvert();

		my $resultStack = $self->_GetNewItem("Generate ML stackup");

		unless ($res) {
			$resultStack->AddError("Failed to create MultiCal xml stackup");
		}

		$self->_OnItemResult($resultStack);
	}

}

sub TaskItemsCount {
	my $self = shift;

	my $totalCnt = 0;

	$totalCnt += 2 if ( $self->{"exportPdf"} );    # Merge pdf + 1 impedance line (other lines are not considered)

	$totalCnt += 1 if ( $self->{"exportStackup"} );    # export stackup

	return $totalCnt;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

#	use aliased 'Packages::Export::ETExport::ETMngr';
#
#	use aliased 'Packages::InCAM::InCAM';
#
#	my $inCAM = InCAM->new();
#
#	my $jobId = "d229010";
#
#	my $et = ETMngr->new( $inCAM, $jobId, "panel", 1 );
#
#	$et->Run()

}

1;

