#-------------------------------------------------------------------------------------------#
# Description: Silkscreen checks
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
use aliased 'Packages::CAM::Checklist::Action';
use aliased 'Enums::EnumsChecklist';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

# Verify set "job class" against control checklist for inner layers
# If there is smaller isolations than set construction class 
# (with consideration of isolation tolerance)
# variable $verifyRes is filled with info (layer, checklist error category, exceed isolation value)
sub VerifyMinIsolInnerLayers {
	my $self            = shift;
	my $inCAM           = shift;
	my $jobId           = shift;
	my $step            = shift;
	my $verifyRes       = shift;                # array reference
	my $checklistName   = shift // "control";
	my $isolTol         = shift // 0.1;         # tolerance of isolation from set construction class is 10%
	my $checklistStatus = shift;                # error message when, checklist to verify not run succesfully

	my $result = 1;

	die "Checklist (name:$checklistName) doesn't exists" unless ( CamChecklist->ChecklistLibExists( $inCAM, $checklistName ) );

	my @inner = map { $_->{"gROWname"} } grep { $_->{"gROWname"} =~ /^v\d+$/i } $defaultInfo->GetBoardBaseLayers();
	my $class = CamJob->GetJobPcbClassInner( $inCAM, $jobId );

	my $actionNum = 1;
	my $result = $self->__VerifyMinIsol( $inCAM, $jobId, $step, $verifyRes, $checklistName, $actionNum, $isolTol, \@inner, $class, $checklistStatus );

	return $result;
}

# Verify set "job class" against control checklist for inner layers
# If there is smaller isolations than set construction class 
# (with consideration of isolation tolerance)
# variable $verifyRes is filled with info (layer, checklist error category, exceed isolation value)
sub VerifyMinIsolInnerLayers {
	my $self            = shift;
	my $inCAM           = shift;
	my $jobId           = shift;
	my $step            = shift;
	my $verifyRes       = shift;                # array reference
	my $checklistName   = shift // "control";
	my $isolTol         = shift // 0.1;         # tolerance of isolation from set construction class is 10%
	my $checklistStatus = shift;                # error message when, checklist to verify not run succesfully

	my $result = 1;

	die "Checklist (name:$checklistName) doesn't exists" unless ( CamChecklist->ChecklistLibExists( $inCAM, $checklistName ) );

	my @inner = map { $_->{"gROWname"} } grep { $_->{"gROWname"} =~ /^v\d+$/i } $defaultInfo->GetBoardBaseLayers();
	my $class = CamJob->GetJobPcbClassInner( $inCAM, $jobId );

	my $actionNum = 1;
	my $result = $self->__VerifyMinIsol( $inCAM, $jobId, $step, $verifyRes, $checklistName, $actionNum, $isolTol, \@inner, $class, $checklistStatus );

	return $result;
}

sub __VerifyMinIsol {
	my $self            = shift;
	my $inCAM           = shift;
	my $jobId           = shift;
	my $step            = shift;
	my $verifyRes       = shift;                # array reference
	my $checklistName   = shift;
	my $checklistAction = shift;
	my $isolTol         = shift // 0.1;         # tolerance of isolation from set construction class is 10%
	my @layers          = @{ ${@_} };
	my $class           = shift;
	my $checklistStatus = shift;

	my $result = 1;

	my $a = Action->new( $inCAM, $jobId, $step, $checklistName, $checklistAction );    # action number = 1;

	my $actionStatus = $a->Run();

	unless ( $actionStatus eq EnumsChecklist->Status_DONE ) {

		$$checklistStatus = $actionStatus;
		$result           = 0;

	}
	else {

		my $r = $a->GetFullReport( undef, undef, [ EnumsChecklist->Sev_RED ] );

		foreach my $l (@inner) {

			foreach my $catName ( ( EnumsChecklist->Cat_PAD2PAD, EnumsChecklist->Cat_PAD2CIRCUIT, EnumsChecklist->Cat_CIRCUIT2CIRCUIT ) ) {

				my $cat = $r->GetCategory($catName);
				next unless ( defined $cat );

				my @catVal = $cat->GetCatValues($l);

				if ( @catVal && $catVal[0]->GetValue() < $isol * ( 1 - $isolTol ) ) {

					my %inf          = ();
					my $inf{"layer"} = $l;
					my $inf{"cat"}   = $cat->GetCatTitle();
					my $inf{"val"}   = $catVal[0]->GetValue();

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

	use aliased 'Packages::CAMJob::Technology::CuLayer';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f52456";

	my $mess = "";

	my $result = CuLayer->GetMaxCuByClass( 5, 1 );

	print STDERR "Result is: $result";

}

1;
