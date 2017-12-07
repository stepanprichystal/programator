#-------------------------------------------------------------------------------------------#
# Description: Checking layer names at matrix
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Matrix::LayerNamesCheck;

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamDTM';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamHistogram';
use aliased 'CamHelpers::CamFilter';
use aliased 'CamHelpers::CamStepRepeat';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#
# If there is some non board layer which should be board, return 0
# Not check NC layers
sub CheckNonBoardBaseLayers {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $wrongLayers  = shift;    # array reference to error message

	my $result = 1;

	my @nonBoard = grep { $_->{"gROWcontext"} eq "misc" }CamJob->GetAllLayers($inCAM, $jobId);
	
	
	@{$wrongLayers} =  grep { $_->{"gROWname"} =~ /(^[mp]?[cs]$)|(^v\d+$)/} @nonBoard;
	
	if(scalar(@{$wrongLayers})){
		
		$result = 0; 
	}
	 
	return $result;
}
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use Data::Dump qw(dump);

	use aliased 'Packages::CAMJob::Matrix::LayerNamesCheck';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f52457";

	my $mess = "";
 
	my @l = ();
	my $result = LayerNamesCheck->CheckNonBoardBaseLayers( $inCAM, $jobId,  \@l );

	print STDERR "Result is: $result, error \n";

 

}

1;
