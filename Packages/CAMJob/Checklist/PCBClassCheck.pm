#-------------------------------------------------------------------------------------------#
# Description: Verification of job class against control checklist
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Checklist::PCBClassCheck;

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::FileHelper';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::CAM::Checklist::Action';
use aliased 'Enums::EnumsChecklist';
use aliased 'CamHelpers::CamChecklist';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

# Verify set "job class" against control checklist for inner and outer layers
# If there is smaller isolations than set construction class
# (with consideration of isolation tolerance)
# variable $verifyRes is filled with info (layer, checklist error category, exceed isolation value)
# Return value:
# - 0, if some problems occur
# - 1, if function run succesfully. It doesn't matter if some verify result info (var $verifyRes) are set
sub VerifyMinIsolLayers {
	my $self          = shift;
	my $inCAM         = shift;
	my $jobId         = shift;
	my $step          = shift;
	my $verifyRes     = shift;                # array reference
	my $checklistName = shift // "control";
	my $isolTol       = shift // 0.1;         # tolerance of isolation from set construction class is 10%
	my $verifyErrMess = shift;                # error message when, checklist to verify not run succesfully

	$$verifyErrMess = "";

	my $result = 1;

	if ( CamJob->GetSignalLayer( $inCAM, $jobId ) > 2 ) {

		unless ( $self->VerifyMinIsolInnerLayers( $inCAM, $jobId, $step, $verifyRes, undef, undef, \$verifyErrMess ) ) {

			$result = 0;
		}
	}

	unless ( $self->VerifyMinIsolOuterLayers( $inCAM, $jobId, $step, $verifyRes, undef, undef, \$verifyErrMess ) ) {

		$result = 0;
	}
	
	return $result;
}

# Verify set "job class" against control checklist for inner layers
# If there is smaller isolations than set construction class
# (with consideration of isolation tolerance)
# variable $verifyRes is filled with info (layer, checklist error category, exceed isolation value)
# Return value:
# - 0, if some problems occur
# - 1, if function run succesfully. It doesn't matter if some verify result info (var $verifyRes) are set
sub VerifyMinIsolInnerLayers {
	my $self          = shift;
	my $inCAM         = shift;
	my $jobId         = shift;
	my $step          = shift;
	my $verifyRes     = shift;                # array reference
	my $checklistName = shift // "control";
	my $isolTol       = shift // 0.1;         # tolerance of isolation from set construction class is 10%
	my $verifyErrMess = shift;                # error message when, checklist to verify not run succesfully

	die "Checklist (name:$checklistName) doesn't exists" unless ( CamChecklist->ChecklistLibExists( $inCAM, $checklistName ) );

	my @inner = map { $_->{"gROWname"} } grep { $_->{"gROWname"} =~ /^v\d+$/i } CamJob->GetBoardBaseLayers( $inCAM, $jobId );
	my $class = CamJob->GetJobPcbClassInner( $inCAM, $jobId );

	my $actionNum = 1;
	my $result = $self->__VerifyMinIsol( $inCAM, $jobId, $step, $verifyRes, $checklistName, $actionNum, $isolTol, \@inner, $class, $verifyErrMess );

	return $result;
}

# Verify set "job class" against control checklist for inner layers
# If there is smaller isolations than set construction class
# (with consideration of isolation tolerance)
# variable $verifyRes is filled with info (layer, checklist error category, exceed isolation value)
sub VerifyMinIsolOuterLayers {
	my $self          = shift;
	my $inCAM         = shift;
	my $jobId         = shift;
	my $step          = shift;
	my $verifyRes     = shift;                # array reference
	my $checklistName = shift // "control";
	my $isolTol       = shift // 0.1;         # tolerance of isolation from set construction class is 10%
	my $verifyErrMess = shift;                # error message when, checklist to verify not run succesfully

	die "Checklist (name:$checklistName) doesn't exists" unless ( CamChecklist->ChecklistLibExists( $inCAM, $checklistName ) );

	my @outer = map { $_->{"gROWname"} } grep { $_->{"gROWname"} =~ /^[cs]$/i } CamJob->GetBoardBaseLayers( $inCAM, $jobId );
	my $class = CamJob->GetJobPcbClass( $inCAM, $jobId );

	my $actionNum = 2;
	my $result = $self->__VerifyMinIsol( $inCAM, $jobId, $step, $verifyRes, $checklistName, $actionNum, $isolTol, \@outer, $class, $verifyErrMess );

	return $result;
}

sub __VerifyMinIsol {
	my $self            = shift;
	my $inCAM           = shift;
	my $jobId           = shift;
	my $step            = shift;
	my $verifyRes       = shift;            # array reference
	my $checklistName   = shift;
	my $checklistAction = shift;
	my $isolTol         = shift // 0.1;     # tolerance of isolation from set construction class is 10%
	my @layers          = @{ shift(@_) };
	my $class           = shift;
	my $verifyErrMess   = shift;

	my $result = 1;

	my $isol = JobHelper->GetIsolationByClass($class);

	unless ( CamChecklist->ChecklistExists( $inCAM, $jobId, $step, $checklistName ) ) {

		CamChecklist->CopyChecklistToStep( $inCAM, $step, $checklistName );
	}

	my $a = Action->new( $inCAM, $jobId, $step, $checklistName, $checklistAction );    # action number = 1;

	my $actionStatus = $a->Run();

	unless ( $actionStatus eq EnumsChecklist->Status_DONE ) {

		$$verifyErrMess = "Running checklist action: $checklistName/$checklistAction end with error. Checklist action status: $actionStatus\n";
		$result         = 0;

	}
	else {

		my $r = $a->GetFullReport( undef, undef, [ EnumsChecklist->Sev_RED ] );

		foreach my $l (@layers) {

			foreach my $catName ( ( EnumsChecklist->Cat_PAD2PAD, EnumsChecklist->Cat_PAD2CIRCUIT, EnumsChecklist->Cat_CIRCUIT2CIRCUIT ) ) {

				my $cat = $r->GetCategory($catName);
				next unless ( defined $cat );

				my @catVal = $cat->GetCatValues($l);

				if ( @catVal && $catVal[0]->GetValue() < $isol * ( 1 - $isolTol ) ) {

					my %inf = ();
					$inf{"layer"} = $l;
					$inf{"cat"}   = $cat->GetCatTitle();
					$inf{"val"}   = $catVal[0]->GetValue();

					push( @{$verifyRes}, \%inf );

				}
			}
		}
	}

	return $result;

}

# Return resutls from cheklist "control":

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use Data::Dump qw(dump);

	use aliased 'Packages::CAMJob::Checklist::PCBClassCheck';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d251561";
	my $step  = "o+1";

	my $mess = "";

	my @verifyResults = ();
	my $verifyErrMess;
	my $verified = PCBClassCheck->VerifyMinIsolLayers( $inCAM, $jobId, $step, \@verifyResults, "control", undef, \$verifyErrMess );

	if ($verified) {

		# Function ended OK

		if (@verifyResults) {

			# ...but PCB class verification failed

			foreach my $r (@verifyResults) {

				print "Layer: " . $r->{"layer"} . "\n";
				print "Problem category: " . $r->{"cat"} . "\n";
				print "Problem value: " . $r->{"value"} . "\n";
				print "\n\n";

			}
		}
	}
	else {

		# Function ended with error

		print STDERR $verifyErrMess;
	}

}

1;
