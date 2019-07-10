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
use aliased 'Enums::EnumsChecklist';
use aliased 'CamHelpers::CamStepRepeat';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

# Run speific action inchecklist
sub ActionRun {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $step        = shift;
	my $checklist   = shift;
	my $action      = shift;
	my $async       = shift // 0;
	my $copyFromLib = shift // 1;    # unless checklist exist in job, search and copz checklist from global library

	if ( defined $async && $async ) {
		$async = "yes";
	}
	else {
		$async = "no";
	}

	# Copy checklist from global library
	if ( !$self->ChecklistExists( $inCAM, $jobId, $step, $checklist ) && $copyFromLib ) {
		$inCAM->COM( "chklist_from_lib", "chklist" => $checklist );
	}

	CamHelper->SetStep( $inCAM, $step );

	$inCAM->COM( "chklist_run", "chklist" => $checklist, "nact" => $action, "area" => "global", "async_run" => $async );

	return 1;
}

# Copy checklist from job to specific step
sub CopyChecklistToStep {
	my $self         = shift;
	my $inCAM        = shift;
	my $step         = shift;
	my $checklistSrc = shift;
	my $checklistDst = shift // $checklistSrc;

	$inCAM->COM( "chklist_copy", "dst_chk" => $checklistDst, "dst_stp" => $step, "src_chk" => $checklistSrc );

}

# Store action summarz report to file
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

# Return if chesklist exist in specific job and step
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

	my $val = $inCAM->{doinfo}{gEXISTS};

	return ( $val =~ /yes/i ) ? 1 : 0;
}

# Check if checklist exist in Global library
sub ChecklistLibExists {
	my $self      = shift;
	my $inCAM     = shift;
	my $checklist = shift;

	$inCAM->SupressToolkitException(1);
	$inCAM->HandleException(1);

	my $res = $inCAM->COM( "chklist_from_lib", "chklist" => $checklist );

	$inCAM->SupressToolkitException(0);
	$inCAM->HandleException(0);

	return ( $res > 0 ) ? 0 : 1;
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
# If action hasn't been run yet, return undef
sub GetChecklistActionTime {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $step      = shift;
	my $checklist = shift;
	my $action    = shift;

	my $dt = undef;

	if ( $self->ChecklistActionStatus( $inCAM, $jobId, $step, $checklist, $action ) eq EnumsChecklist->Status_UNDONE ) {

		return undef;
	}
	$inCAM->INFO(
		"units"       => 'mm',
		"entity_type" => 'check',
		"entity_path" => "$jobId/$step/$checklist",
		"data_type"   => "LAST_TIME",
		"options"     => "action=$action"

	);

	my $val = $inCAM->{doinfo}{gLAST_TIME};

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

	$h += 12 if ( $noon =~ /pm/i && $h > 1 );

	$dt = DateTime->new(
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
	my $jobId = "d250544";

	#my $system1 = CamChecklist->ChecklistLibExists( $inCAM,"control1" );
	my $system = CamChecklist->ChecklistExists2( $inCAM, $jobId, "o+1", "control" );

	#my $job = CamChecklist->ActionRun( $inCAM, $jobId, "o+1", "control1", 1 );

	die;

}

1;

1;
