#-------------------------------------------------------------------------------------------#
# Description: Verification of various parameters in signal layer
# Like anular ring etc..
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Checklist::PCBSigLayer;

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

# Return if there is via or pth annular ring less than 75µm
# (and geater than "0" - if ring is cut by rout, checklist can return annular ring 0)
# Return value:
# - 0, if some problems occur during running checklist
# - 1, if checklist run succesfully
sub ExistAnularRingLess75 {
	my $self                = shift;
	my $inCAM               = shift;
	my $jobId               = shift;
	my $step                = shift;
	my $existRing           = shift;    # result value
	my $runChecklistErrMess = shift;    # error message when, checklist to verify not run succesfully

	$$runChecklistErrMess = "";
	$$existRing           = 0;

	# Directly defined existing checklist
	my $checklistName   = "control";
	my $checklistAction = 3;

	use constant MINAR => 80;

	my $resultChecklist = 1;

	if ( !CamChecklist->ChecklistExists( $inCAM, $jobId, $step, $checklistName ) ) {
		
		
		CamChecklist->CopyChecklistFromLib( $inCAM, $checklistName );
		CamChecklist->CopyChecklistToStep( $inCAM, $step, $checklistName );
	 

	}
	elsif ( CamChecklist->GetChecklistActionCnt( $inCAM, $jobId, $step, $checklistName ) < $checklistAction ) {

		$inCAM->COM( "chklist_delete", "chklist" => $checklistName );
		
		CamChecklist->CopyChecklistFromLib( $inCAM, $checklistName );
		CamChecklist->CopyChecklistToStep( $inCAM, $step, $checklistName );

	}

	my $a = Action->new( $inCAM, $jobId, $step, $checklistName, $checklistAction );    # action number = 1;

	my $actionStatus = $a->Run();

	unless ( $actionStatus eq EnumsChecklist->Status_DONE ) {

		$$runChecklistErrMess = "Running checklist action: $checklistName/$checklistAction end with error. Checklist action status: $actionStatus\n";
		$resultChecklist      = 0;

	}
	else {
		my $r = $a->GetFullReport( undef, undef, [ EnumsChecklist->Sev_RED, EnumsChecklist->Sev_YELLOW ] );

		foreach my $catName ( ( EnumsChecklist->Cat_PTHCOMPANNULARRING, EnumsChecklist->Cat_VIAANNULARRING ) ) {

			my $cat = $r->GetCategory($catName);
			next unless ( defined $cat );

			# note - > 0 means, there could be annular ring cut by rout and checklist return 0 width of ring
			my @minAr = grep { $_->GetValue() < MINAR &&  $_->GetValue() > 0} $cat->GetCatValues();

			if ( scalar(@minAr) ) {

				$$existRing = 1;
				last;
			}

		}
	}

	return $resultChecklist;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use Data::Dump qw(dump);

	use aliased 'Packages::CAMJob::Checklist::PCBSigLayer';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d320319";
	my $step  = "o+1";

	my $mess = "";

	my $exist = 0;
	my $verifyErrMess;
	my $res = PCBSigLayer->ExistAnularRingLess75( $inCAM, $jobId, $step, \$exist, \$verifyErrMess );

	if ($res) {

		# Function ended OK
		#
		#		if (@resData) {
		#
		#			# ...but PCB class verification failed
		#
		#			foreach my $r (@resData) {
		#
		#				print "Layer: " . $r->{"layer"} . "\n";
		#				print "Problem category: " . $r->{"cat"} . "\n";
		#				print "Problem value: " . $r->{"value"} . "\n";
		#				print "\n\n";
		#
		#			}
		#		}
	}
	else {

		# Function ended with error

		print STDERR $verifyErrMess;
	}

}

1;
