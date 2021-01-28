#-------------------------------------------------------------------------------------------#
# Description: Customer request checks
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Scheme::SchemeCheck;

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::JobHelper';
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
sub CustPanelSchemeOk {
	my $self       = shift;
	my $inCAM      = shift;
	my $jobId      = shift;
	my $usedSchema = shift;
	my $custInfo   = shift;

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

# Check if production panel has proper scheme
sub ProducPanelSchemeOk {
	my $self       = shift;
	my $inCAM      = shift;
	my $jobId      = shift;
	my $usedSchema = shift;
	my $result     = 1;

	$$usedSchema = CamAttributes->GetStepAttrByName( $inCAM, $jobId, "panel", ".pnl_scheme" );

	die "Schema name is not defined in step: panel; attribute: pnl_schema" if ( !defined $$usedSchema || $$usedSchema eq "" );

	my ( $schLCnt, $schHeight ) = $$usedSchema =~ /(\d+)v-?(\d*)/i;

	my $sigLCnt = CamJob->GetSignalLayerCnt( $inCAM, $jobId );

	# 1) Check used schema from number of sig layers point of view
	if ( $sigLCnt <= 2 ) {

		if ( !( $schLCnt > 1 && $schLCnt <= 2 ) ) {
			$result = 0;
		}
	}
	else {

		my $sigL = $sigLCnt == 3 ? 4 : $sigLCnt;

		if ( $sigL < $schLCnt ) {
			$result = 0;
		}
	}

	# 2) Check used schema from pnl height point of view
	if ( $sigLCnt > 2 ) {

		die "Schema height is not defined in schema name: $$usedSchema" if ( !defined $schHeight || $schHeight eq "" );

		my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, "panel" );

		my $pnlH = abs( $lim{"yMax"} - $lim{"yMin"} );

		use constant tol => 2;    # tolerance of proper schema 2mm
		if ( abs( $schHeight - $pnlH ) > tol ) {
			$result = 0;
		}

	}

	# 3) Check if flex schema is used when flex pcb
	if ( JobHelper->GetIsFlex($jobId) && $$usedSchema !~ /flex/i ) {

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
	#
	use aliased 'Packages::CAMJob::Scheme::SchemeCheck';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d276231";

	my $mess = "";

	my $usedSch = "";

	my $result = SchemeCheck->ProducPanelSchemeOk( $inCAM, $jobId, \$usedSch );

	print STDERR "Result is: $result, schema is: $usedSch\n";

}

1;
