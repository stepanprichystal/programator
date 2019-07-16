
#-------------------------------------------------------------------------------------------#
# Description: Librabrary form manipulating with InCAM checklist action
# Allow run specific action and parse action report
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::Checklist::Action;

#3th party library
use strict;
use warnings;
use DateTime;

#local library

use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::CAM::Checklist::ActionTxtReport::TxtReportParser';
use aliased 'Packages::CAM::Checklist::ActionFullReport::FullReportParser';
use aliased 'CamHelpers::CamChecklist';
use aliased 'Enums::EnumsChecklist';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"}     = shift;
	$self->{"jobId"}     = shift;
	$self->{"step"}      = shift;
	$self->{"checklist"} = shift;
	$self->{"action"}    = shift;

	return $self;
}

# Run specific action synchronously
# Return action status after run
sub Run {
	my $self = shift;

	my $inCAM     = $self->{"inCAM"};
	my $jobId     = $self->{"jobId"};
	my $step      = $self->{"step"};
	my $checklist = $self->{"checklist"};
	my $action    = $self->{"action"};

	die "Checklist:" . $self->{"checklist"} . "doesn't esists"
	  unless ( CamChecklist->ChecklistExists( $inCAM, $jobId, $step, $checklist ) );

	CamChecklist->ActionRun( $inCAM, $jobId, $step, $checklist, $action );
	
	my $actionStatus = CamChecklist->ChecklistActionStatus( $inCAM, $jobId, $step, $checklist, $action, );
 
	return $actionStatus;
}

# Return parsed text report (summary)
# Report contain histogram of measured values
sub GetTxtReport {
	my $self = shift;

	my $inCAM     = $self->{"inCAM"};
	my $jobId     = $self->{"jobId"};
	my $step      = $self->{"step"};
	my $checklist = $self->{"checklist"};
	my $action    = $self->{"action"};

	my $parser = TxtReportParser->new( $inCAM, $jobId, $step, $checklist, $action );

	my $report = $parser->ParseReport();

	return $report;
}

# Return complete parsed report values by values from checklist results
sub GetFullReport {
	my $self     = shift;
	my $category = shift;    # category key (Enums::EnumsChecklist->Cat_xxx)
	my $layer    = shift;    # layer name
	my $severity = shift;    # array of severity indicators (Enums::EnumsChecklist->Sev_xxx)

	my $inCAM     = $self->{"inCAM"};
	my $jobId     = $self->{"jobId"};
	my $step      = $self->{"step"};
	my $checklist = $self->{"checklist"};
	my $action    = $self->{"action"};

	my $parser = FullReportParser->new( $inCAM, $jobId, $step, $checklist, $action );

	my $report = $parser->ParseReport( $category, $layer, $severity );

	return $report;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAM::Checklist::Action';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "d152457";

	my $a = Action->new( $inCAM, $jobId, "o+1", "control", 2 );

	#$a->Run();
	my $r = $a->GetFullReport();
	#my $r = $a->GetTxtReport();

	die;

}

1;

