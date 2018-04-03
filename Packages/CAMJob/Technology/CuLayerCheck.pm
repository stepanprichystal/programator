#-------------------------------------------------------------------------------------------#
# Description: Silkscreen checks
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Technology::CuLayerCheck;

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::FileHelper';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

# Return maximal value of cu layer by pcb class
sub GetMaxCuByClass {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my $p = GeneralHelper->Root() . "\\Resources\\CuClassRel";

	if ( -e $p ) {

		my @lines = grep { $_ ~= /^#/ } @{ FileHelper->ReadAsLines($p) };
 
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use Data::Dump qw(dump);

	use aliased 'Packages::CAMJob::SilkScreen::SilkScreenCheck';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f52456";

	my $mess = "";

	my $result = SilkScreenCheck->FeatsWidthOkAllLayers( $inCAM, $jobId, "o+1", \$mess );

	print STDERR "Result is: $result, error message: $mess\n";

}

1;
