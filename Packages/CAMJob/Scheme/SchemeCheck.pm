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
use List::Util qw(first);

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::JobHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamDTM';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamAttributes';
use aliased 'Helpers::JobHelper';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamJob';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#
# Check if mpanel contain requsted schema by customer
sub CustPanelSchemeOk {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $schema   = shift;
	my $custInfo = shift;

	my $result = 1;

	my @schemes = $custInfo->RequiredSchemas();
	my $mpanelExist = CamHelper->StepExists( $inCAM, $jobId, "mpanel" );

	# check if exist mpanel and check schema
	if ( defined scalar(@schemes) && $mpanelExist ) {

		my $exist = first { $schema =~ /^$_/ } @schemes;

		unless ($exist) {

			$result = 0;
		}
	}

	return $result;
}

# Check if production panel has proper scheme
sub ProducPanelSchemeOk {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $schema    = shift;
	my $pnlHeight = shift;
	my $errMess   = shift;

	my $result = 1;

	my ( $schType, $schLCnt, $schHeight ) = $schema =~ m/(rigid|flex|hybrid)_(vv|2v)_?(\d+)?/i;

	my $layerCnt     = CamJob->GetSignalLayerCnt( $inCAM, $jobId );
	my $matKind      = HegMethods->GetMaterialKind($jobId);
	my $isSemiHybrid = 0;
	my $isHybrid     = JobHelper->GetIsHybridMat( $jobId, $matKind, [], \$isSemiHybrid );
	my $isFlex       = JobHelper->GetIsFlex($jobId);

	# 1) Check used schema from number of sig layers point of view
	if ( $layerCnt <= 2 ) {

		# 2v

		if ( $schLCnt ne "2v" ) {
			$result = 0;
 
		}
	}
	else {

		# vv
		if ( $schLCnt ne "vv" ) {
			$result = 0;
		}
	}

	# 2) Check used schema from pnl height point of view
	if ( $layerCnt > 2 && defined $schHeight && defined $pnlHeight ) {

		die "Schema height value is wrong in schema name: $schema" if ( $schHeight eq "" );

		use constant tol => 2;                                            # tolerance of proper schema 2mm
		if ( abs( $schHeight - $pnlHeight ) > tol ) {
			$result = 0;
		}
	}

	# 3) Check if flex schema is used when flex pcb
	if ( JobHelper->GetIsFlex($jobId) && $schema !~ /flex/i ) {

		$result = 0;
		
		$$errMess .= "If PCB is flexible, scheme name must contain text \"flex\".";

	}

	#  4) Check if semihybrid, if proper scheme is selected
	if ($isSemiHybrid) {

		# Exception 1 -  if multilayer + coverlay, return hybrid
		if ( $layerCnt > 2 && $schema !~ /hybrid/ ) {
			$result = 0;

			$$errMess .= "If PCB is  \"semi-hybrid\" (standard base material + coveraly), hybrid schema for multilazer PCB must be used.";
		}

		# Exception 2 -  if doublesided layer + coverlay, return flex
		if ( $layerCnt <= 2 && $schema !~ /flex/ ) {

			$result = 0;

			$$errMess .= "If PCB is  \"semi-hybrid\" (standard base material + coveraly), flex schema for doublesided PCB must be used.";
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
