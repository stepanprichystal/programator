#-------------------------------------------------------------------------------------------#
# Description: Contain special function, which work with routing
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::PdfOperation::PdfOperation;

#3th party library
use strict;
use warnings;
 

#local library

use aliased 'Helpers::GeneralHelper';
 

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#
 

# Return best pilot hole for chain size
sub MergePdf {
	my $self       = shift;
 
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
