#-------------------------------------------------------------------------------------------#
# Description: Contains trigger methods, which work with tpv stackups
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::TriggerFunction::Travelers;

#3th party library
use strict;
use warnings;
use File::Copy;

#loading of locale modules
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::JobHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Packages::Pdf::TravelerPdf::ProcessStackupPdf::ProcessStackupPdf';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

# Function convert stackup template to PDF and update order (or dodealvka) information
# parameter $orderId is eg: F12345-01
sub StackupTemplate2PDF {
	my $self    = shift;
	my $orderId = shift;

	my $jobId = $orderId;
	$jobId =~ s/-.*$//;

	my ($orderNum) = $orderId =~ m/^\w\d+-(\d*)$/;
	$orderNum = int($orderNum);

	my $pDirStackup = JobHelper->GetJobArchive($jobId) . "tpvpostup\\";
	my $pDirPdf     = JobHelper->GetJobArchive($jobId) . "pdf\\";
	my $pTemplate   = $pDirStackup . $jobId . "_template_stackup.txt";

	if ( -e $pTemplate ) {
		
		my $stackup = ProcessStackupPdf->new($jobId);
 
		# 3) Output all orders in production
		my @PDFOrders = ();
	 
		push( @PDFOrders, map { { "orderId" => $orderId, "extraProducId" => 0 } } $orderId );
 

		my $serFromFile = FileHelper->ReadAsString($pTemplate);

		foreach my $order (@PDFOrders) {

			$stackup->OutputSerialized( $serFromFile, undef, $order->{"orderId"}, $order->{"extraProducId"} );

			my $pPdf = $pDirPdf . $order->{"orderId"} . "-DD-" . $order->{"extraProducId"} . "_stackup.pdf";

			unless ( copy( $stackup->GetOutputPath(), $pPdf ) ) {
				die "Can not delete old pdf stackup file (" . $pPdf . "). Maybe file is still open.\n";
			}
			
			unlink($stackup->GetOutputPath());

		}
	} 

	return 1;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::TriggerFunction::Travelers';

	Travelers->StackupTemplate2PDF("d279269-01");

	print STDERR "ttt";

}

1;

