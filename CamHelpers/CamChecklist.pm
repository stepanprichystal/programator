#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#

package CamHelpers::CamChecklist;

#3th party library
use strict;
use warnings;
use DateTime;

#loading of locale modules

use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamCopperArea';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamDTM';
use aliased 'Enums::EnumsDrill';
use aliased 'CamHelpers::CamStepRepeat';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

# Run speific action inchecklist
sub ActionRun {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $step      = shift;
	my $checklist = shift;
	my $action    = shift;
	my $async     = shift // 0;

	if ( defined $async && $async ) {
		$async = "yes";
	}
	else {
		$async = "no";
	}
	
	CamHelper->SetStep($inCAM, $step);

	$inCAM->COM( "chklist_run", "chklist" => $checklist, "nact" => $action, "area" => "global", "async_run" => $async );

	return 1;
}

sub OutputActionReport {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $step      = shift;
	my $checklist = shift;
	my $action    = shift;
	my $outfile   = shift;

	$inCAM->INFO(
		"units"       => 'mm',
		"entity_type" => 'check',
		"entity_path" => "$jobId/$step/$checklist",
		"out_file"    => $outfile,
		"data_type"   => "REPORT",
		"parse"       => "no",
		"options"     => "action=$action"

	);
}

sub ChecklistExists {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $step      = shift;
	my $checklist = shift;

	$inCAM->INFO(
		"units"       => 'mm',
		"entity_type" => 'check',
		"entity_path" => "$jobId/$step/$checklist",
		"data_type"   => "EXISTS"

	);

	return $inCAM->{doinfo}{gEXISTS};
}

# Return status of action
# Enums::EnumsChecklist
# - Status_OUTDATE     => "status_outdate",
# -	Status_DONE     => "status_done",
# - Status_UNDONE     => "status_undone",
# - Status_ERROR     => "status_error
sub ChecklistActionStatus {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $step      = shift;
	my $checklist = shift;
	my $action    = shift;

	$inCAM->INFO(
		"units"       => 'mm',
		"entity_type" => 'check',
		"entity_path" => "$jobId/$step/$checklist",
		"data_type"   => "STATUS",
		"options"     => "action=$action"

	);

	return $inCAM->{doinfo}{gSTATUS};
}

# Return time of last run of specified action
# Return value is in DateTime format
sub GetChecklistActionTime {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $step      = shift;
	my $checklist = shift;
	my $action    = shift;

	$inCAM->INFO(
		"units"       => 'mm',
		"entity_type" => 'check',
		"entity_path" => "$jobId/$step/$checklist",
		"data_type"   => "LAST_TIME",
		"options"     => "action=$action"

	);

	my $val =  $inCAM->{doinfo}{gLAST_TIME};
	
	
	my ( $d, $monthTxt, $y, $h, $m, $noon ) = $val =~ m/(\d+)\s+(\w+)\s+(\d+)\s+(\d+):(\d+)\s+([AP]M)/i;
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

	$h += 12 if($noon =~ /pm/i && $h > 1);

	my $dt = DateTime->new(
							"year"      => $y,
							"month"     => $month{$monthTxt},
							"day"       => $d,
							"hour"      => $h,
							"minute"    => $m,
							"second"    => 0,
							"time_zone" => 'Europe/Prague'
	);
	
	return $dt;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'CamHelpers::CamChecklist';

	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d152456";

	my $dt = CamChecklist->GetChecklistActionTime( $inCAM, $jobId, "o+1", "control", 2 );

	 die;

}

1;

1;
