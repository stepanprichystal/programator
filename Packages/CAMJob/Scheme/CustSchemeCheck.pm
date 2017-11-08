#-------------------------------------------------------------------------------------------#
# Description: Customer request checks
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Scheme::CustSchemeCheck;

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
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamAttributes';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#
# Check if mpanel contain requsted schema by customer
sub CustSchemeOk {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $usedSchema 	= shift;
	my $custInfo = shift;

	my $result = 1;

	my $scheme = $custInfo->RequiredSchema();
	my $exist = CamHelper->StepExists( $inCAM, $jobId, "mpanel" );

	# check if exist mpanel and check schema
	if ( defined $scheme && $exist ) {

		$$usedSchema = CamAttributes->GetStepAttrByName( $inCAM, $jobId, "mpanel", "cust_panelization_scheme" );

		unless ( $$usedSchema =~ /$scheme/i ) {
 
			$result = 0;
		}
	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use Data::Dump qw(dump);
	#
	#	use aliased 'Packages::CAMJob::SilkScreen::SilkScreenCheck';
	#	use aliased 'Packages::InCAM::InCAM';
	#
	#	my $inCAM = InCAM->new();
	#	my $jobId = "f52456";
	#
	#	my $mess = "";
	#
	#
	#	my $result = SilkScreenCheck->FeatsWidthOkAllLayers( $inCAM, $jobId, "o+1",  \$mess );
	#
	#	print STDERR "Result is: $result, error message: $mess\n";

}

1;
