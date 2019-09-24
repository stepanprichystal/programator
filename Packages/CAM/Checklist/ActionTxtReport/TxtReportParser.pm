
#-------------------------------------------------------------------------------------------#
# Description: Represent category of parser action InCAM report
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::Checklist::ActionTxtReport::TxtReportParser;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::FileHelper';
use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::JobHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsChecklist';
use aliased 'CamHelpers::CamChecklist';
use aliased 'Packages::CAM::Checklist::ActionTxtReport::TxtReportCatHist';
use aliased 'Packages::CAM::Checklist::ActionTxtReport::ActionTxtReport';


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
sub ParseReport {
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
	CamChecklist->OutputActionTxtReport( $inCAM, $jobId, $step, $checklist, $action, $file );

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
				  "Sep" => 9,
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

	my $report = ActionTxtReport->new( $checklist, $action, $dt );

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
 

}

1;

