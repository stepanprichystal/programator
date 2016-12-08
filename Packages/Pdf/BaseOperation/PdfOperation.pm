#-------------------------------------------------------------------------------------------#
# Description: Contain special function, which work with routing
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::BaseOperation::PdfOperation;

#3th party library
use strict;
use warnings;
use PDF::API2;

#local library

use aliased 'Helpers::GeneralHelper';

use aliased 'Enums::EnumsPaths';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

# Return best pilot hole for chain size
sub MergeDocs {
	my $self       = shift;
	my @inputFiles = @{shift(@_)};
	my $outFile    = shift;

	unless ( defined $outFile ) {

		$outFile = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID();

	}

	# the output file
	my $outputPdf = PDF::API2->new( -file => $outFile );

	foreach my $inputFile (@inputFiles) {
		my $inputPdf = PDF::API2->open($inputFile);
		my @numpages = ( 1 .. $inputPdf->pages() );
		foreach my $numpage (@numpages) {

			# add page number $numpage from $input_file to the end of
			# the file $output_file
			$outputPdf->importpage( $inputPdf, $numpage, 0 );
		}
	}

	$outputPdf->save();

	return $outFile;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#
	#	use aliased 'Packages::Routing::PilotHole';
	#	use aliased 'Packages::InCAM::InCAM';
	#
	#	my $jobId = "f13610";
	#	my $inCAM = InCAM->new();
	#
	#	my $step = "o+1";
	#
	#	my $max = PilotHole->AddPilotHole( $inCAM, $jobId, $step, "f");

}

1;
