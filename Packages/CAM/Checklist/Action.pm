
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

use aliased 'Helpers::FileHelper';
use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::JobHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::CAM::Checklist::ActionReport';
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

	return 1;
}

# Return parsed action report
sub GetReport {
	my $self = shift;

	my $report = $self->__ParseReport();

	return $report;
}

sub __ParseReport {
	my $self = shift;

	my $inCAM     = $self->{"inCAM"};
	my $jobId     = $self->{"jobId"};
	my $step      = $self->{"step"};
	my $checklist = $self->{"checklist"};
	my $action    = $self->{"action"};

	die "Checklist:" . $self->{"checklist"} . "doesn't esists"
	  unless ( CamChecklist->ChecklistExists( $inCAM, $jobId, $step, $checklist ) );

	my $actionStatus = CamChecklist->ChecklistActionStatus( $inCAM, $jobId, $step, $checklist, $action );
	die "Checklist action is not in status: DONE. Current status: $actionStatus" unless ( $actionStatus eq EnumsChecklist->Status_DONE );

	my $file = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID();
	CamChecklist->OutputActionReport( $inCAM, $jobId, $step, $checklist, $action, $file );

	my @lines = @{ FileHelper->ReadAsLines($file) };

	unlink($file) or die $_;

	my $jobRep  = shift @lines;
	my $stepRep = shift @lines;
	my $date    = shift @lines;
	my $time    = shift @lines;
	my $created = shift @lines;
	my $units   = shift @lines;

	# Parse time
	my ( $d, $monthTxt, $y ) = $date =~ m/DATE\s+:+\s+(\d+)\s+(\w+)\s+(\d+)/i;
	my ( $h, $m,        $s ) = $time =~ m/TIME\s+:+\s+(\d+):(\d+):(\d+)/i;
	my %month = (
				  "Jan"  => 1,
				  "Feb"  => 2,
				  "Mar"  => 3,
				  "Apr"  => 4,
				  "May"  => 5,
				  "Jun"  => 6,
				  "Jul"  => 7,
				  "Aug"  => 8,
				  "Sept" => 9,
				  "Oct"  => 10,
				  "Nov"  => 11,
				  "Dec"  => 12
	);

	my $dt = DateTime->new(
							"year"      => $y,
							"month"     => $month{$monthTxt},
							"day"       => $d,
							"hour"      => $h,
							"minute"    => $m,
							"second"    => $s,
							"time_zone" => 'Europe/Prague'
	);

	my $report = ActionReport->new( $checklist, $action, $dt );

	my $currentL        = undef;
	my $curCategory     = undef;
	my $curCategoryHist = undef;

	my $lPrev;
	for ( my $i = 0 ; $i < scalar(@lines) ; $i++ ) {

		my $l = $lines[$i];
		my $lPrev = $lines[ $i - 1 ] if ( $i > 0 );

		next if ( $l =~ /^[\t\s]$/ );

		# $l =~ /^[\t\s]$/;

		# New lazer detected
		if ( $l =~ m/Layer\s*:\s*(.*)/i ) {

			$currentL = $1;
		}

		# New Category detected
		if ( $l =~ /=+/i ) {

			my $catName = $lPrev;
			$catName =~ s/(^\s+)|\s+$//g;
			my $catDesc = $lines[ $i + 1 ];
			$catDesc =~ s/(^\s+)|\s+$//g;
			$i++;

			$curCategory = $report->GetCategory($catName);

			unless ( defined $curCategory ) {

				$curCategory = $report->AddCategory( $catName, $catDesc );
			}

			$curCategoryHist = $curCategory->AddCategoryHist($currentL);

		}

		# Parse category values
		# Not "summary" parsing is not impolmented
		if ( $l =~ m/(\d+.?\d*)-\s+(\d+.?\d*)\s+(\d+)/ ) {
			my $from = $1;
			my $to   = $2;
			my $cnt  = $3;

			$to =~ s/\s//g;    # there can be space if number is not float

			$curCategoryHist->AddItem( $from, $to, $cnt, $l );
		}
	}

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

	my $jobId = "d222775";

	my $a = Action->new( $inCAM, $jobId, "o+1", "control", 2 );

	$a->Run();
	my $r = $a->GetReport();
	
	die;
 

	 

	 

}

1;

