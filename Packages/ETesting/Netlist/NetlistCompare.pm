
#-------------------------------------------------------------------------------------------#
# Description: Library for comparing netlist in job
# Notice: "Reference step" - means step which is original (eg.: input, o, pcb)
#		  "Edit step" - means step which is created from Reference step (eg.: o+1, mpanel)
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::ETesting::Netlist::NetlistCompare;

#3th party library
use strict;
use warnings;

#local library

use aliased 'Helpers::FileHelper';
use aliased 'Helpers::JobHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamLayer';
use aliased 'Packages::ETesting::Netlist::NetlistReport';
use aliased 'Packages::CAMJob::Panelization::SRStep';
use aliased 'CamHelpers::CamStep';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	$self->{"reportPaths"} = JobHelper->GetJobOutput( $self->{"jobId"} ) . "netlistReport\\";

	unless ( -e $self->{"reportPaths"} ) {
		mkdir( $self->{"reportPaths"} ) or die "Can't create dir: " . $self->{"reportPaths"} . $_;
	}

	return $self;
}

# Compare step without Step and repeat, return netlist report
# Reference step is choosed automatically, according TPV "step name rules"
sub Compare1Up {
	my $self     = shift;
	my $editStep = shift;
	my $pnlBased = shift;    # is edited step based on panel

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	$self->{"inCAM"}->COM("disp_off");

	my $stepRef = undef;

	if ($pnlBased) {

		# Reference step is flattened step based on panel step $pnlBased

		$stepRef = $self->__CreateRefStep($pnlBased);

		# Move pcb to zero point
		my %limEdit = CamJob->GetProfileLimits2( $inCAM, $jobId, $editStep );
		my %limRef  = CamJob->GetProfileLimits2( $inCAM, $jobId, $stepRef );

		if ( abs( $limEdit{"xMin"} - $limRef{"xMin"} ) > 0.01 || abs( $limEdit{"yMin"} - $limRef{"yMin"} ) > 0.01 ) {

			my %source = ( "x" => $limRef{"xMin"},  "y" => $limRef{"yMin"} );
			my %target = ( "x" => $limEdit{"xMin"}, "y" => $limEdit{"yMin"} );

			CamStep->MoveStepData( $inCAM, $jobId, $stepRef, \%source, \%target );
		}

	}
	else {

		# reference step is 1up not SR

		# 1) test if panel contain SR steps
		if ( CamStepRepeat->ExistStepAndRepeats( $inCAM, $jobId, $editStep ) ) {
			die "Can't compare \"$editStep\" netlist by function \"NetlistCompare::Compare1Up\", because there are Step and Repeat steps.";
		}

		$stepRef = CamStep->GetReferenceStep( $inCAM, $jobId, $editStep );
		unless ( defined $stepRef ) {
			die "Reference (original) step doesn't exist for: " . $editStep;
		}
	}

	my $r = $self->__CompareNetlist( $editStep, $stepRef );

	$self->{"inCAM"}->COM("disp_on");

	return $r;

}

# Compare step with Step and repeat, return netlist report
# "Help reference panel" is automatically created from given panel step
sub ComparePanel {
	my $self     = shift;
	my $editStep = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	$self->{"inCAM"}->COM("disp_off");

	my $stepRef = undef;    # if step ref not defined, create own step with original data

	# 1) test if panel contain SR steps
	unless ( CamStepRepeat->ExistStepAndRepeats( $inCAM, $jobId, $editStep ) ) {
		die "Can't compare \"$editStep\" netlist by  function \"NetlistCompare::ComparePanel\", because there is no Step and Repeat inside.";
	}

	my $editPnlFlat = $editStep . "_netlist";
	my $refPnlFlat  = $self->__CreateRefStep($editStep);

	CamStep->CreateFlattenStep( $inCAM, $jobId, $editStep, $editPnlFlat, 0 );
	my $r = $self->__CompareNetlist( $editPnlFlat, $refPnlFlat );

	$self->{"inCAM"}->COM("disp_on");

	return $r;

}

# Return all reports, which were done in past.
# Reports are stored in job "Output/Netlist folder" in InCAM db
sub GetStoredReports {
	my $self = shift;

	my @reports = ();

	my $dir = undef;
	opendir( $dir, $self->{"reportPaths"} ) or die $!;

	while ( my $file = readdir($dir) ) {

		next unless $file =~ /_X_/i;

		my $filePath = $self->{"reportPaths"} . $file;

		push( @reports, NetlistReport->new($filePath) );

	}

	closedir($dir);

	return @reports;

}

# Create reference, flateneed step, based on given "panel step"
# Assume SR steps inside contains "edited"
# steps (which will be automatically replaced with reference/original steps)
sub __CreateRefStep {
	my $self    = shift;
	my $pnlStep = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# 1) test if panel contain SR steps
	unless ( CamStepRepeat->ExistStepAndRepeats( $inCAM, $jobId, $pnlStep ) ) {
		die "Can't create reference step because there is no Step and Repeat inside $pnlStep.";
	}

	my @sr = CamStepRepeat->GetStepAndRepeat( $inCAM, $jobId, $pnlStep );

	# 2) check if each sr in panel has original reference step

	my %mapRef = ();

	foreach my $s (@sr) {

		my $ref = CamStep->GetReferenceStep( $inCAM, $jobId, $s->{"gSRstep"} );

		unless ( defined $ref ) {
			die "Reference (original) step doesn't exist for: " . $s->{"gSRstep"};
		}

		$mapRef{ $s->{"gSRstep"} } = $ref;
	}

	# 3) Create "reference" panel from exist panel

	my $panelRef = $pnlStep . "_ref";

	CamStep->DeleteStep( $inCAM, $jobId, $panelRef );

	$inCAM->COM(
				 'copy_entity',
				 "type"           => 'step',
				 "source_job"     => $jobId,
				 "source_name"    => $pnlStep,
				 "dest_job"       => $jobId,
				 "dest_name"      => $panelRef,
				 "dest_database"  => "",
				 "remove_from_sr" => "yes"
	);

	my @boardLayers = map { $_->{"gROWname"} } CamJob->GetBoardLayers( $inCAM, $jobId );

	my %mapRefTmp = ();

	foreach my $step ( keys %mapRef ) {

		my $refStep    = $mapRef{$step};
		my $refStepTmp = $refStep . "_tmp";

		$mapRefTmp{$step} = $refStepTmp;

		CamStep->DeleteStep( $inCAM, $jobId, $refStepTmp );

		# 1) create tmp 1up step
		$inCAM->COM(
					 'copy_entity',
					 "type"           => 'step',
					 "source_job"     => $jobId,
					 "source_name"    => $refStep,
					 "dest_job"       => $jobId,
					 "dest_name"      => $refStepTmp,
					 "dest_database"  => "",
					 "remove_from_sr" => "yes"
		);

		# 2) clip all layers around profile in new tmp step

		CamHelper->SetStep( $inCAM, $refStepTmp );
		CamLayer->AffectLayers( $inCAM, \@boardLayers );

		$inCAM->COM(
					 "clip_area_end",
					 "layers_mode" => "affected_layers",
					 "area"        => "profile",
					 "area_type"   => "rectangle",
					 "inout"       => "outside",
					 "contour_cut" => "yes",
					 "margin"      => "2000",
					 "feat_types"  => "line\;pad\;surface\;arc\;text",
					 "pol_types"   => "positive\;negative"
		);

		CamLayer->ClearLayers($inCAM);

	}

	# Replace "processed" steps in panel with "tmp reference" steps
	for ( my $i = 0 ; $i < scalar(@sr) ; $i++ ) {

		my $srRow = $sr[$i];

		CamStepRepeat->ChangeStepAndRepeat(
											$inCAM,                            $jobId,
											$panelRef,                         $i + 1,
											$mapRefTmp{ $srRow->{"gSRstep"} }, $srRow->{"gSRxa"},
											$srRow->{"gSRya"},                 $srRow->{"gSRdx"},
											$srRow->{"gSRdy"},                 $srRow->{"gSRnx"},
											$srRow->{"gSRny"},                 $srRow->{"gSRangle"},
											"ccw",                             $srRow->{"gSRmirror"},
											$srRow->{"gSRflip"},               $srRow->{"gSRxa"},
											$srRow->{"gSRxa"},                 $srRow->{"gSRxa"},
											$srRow->{"gSRxa"},
		  )

	}

	# Flatten created $panelRef

	my $refPnlFlat = $panelRef . "_netlist";

	CamStep->CreateFlattenStep( $inCAM, $jobId, $panelRef, $refPnlFlat, 0 );

	CamStep->DeleteStep( $inCAM, $jobId, $panelRef );    # delete panel ref

	foreach my $step ( keys %mapRefTmp ) {

		CamStep->DeleteStep( $inCAM, $jobId, $mapRefTmp{$step} );    # delete clipepd ref steps
	}

	return $refPnlFlat;

}

# Compare two steps and theirs netlists
# Rerturn report (NetlistReport.pm)
sub __CompareNetlist {
	my $self     = shift;
	my $editStep = shift;
	my $refStep  = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# Compare steps dimensions, if are same
	my %limEdit = CamJob->GetProfileLimits2( $inCAM, $jobId, $editStep );
	my %limRef  = CamJob->GetProfileLimits2( $inCAM, $jobId, $refStep );

	my $editW = abs( $limEdit{"xMax"} - $limEdit{"xMin"} );
	my $editH = abs( $limEdit{"yMax"} - $limEdit{"yMin"} );

	my $refW = abs( $limRef{"xMax"} - $limRef{"xMin"} );
	my $refH = abs( $limRef{"yMax"} - $limRef{"yMin"} );

	if ( abs( $editW - $refW ) > 0.01 || abs( $editH - $refH ) > 0.01 ) {

		die "Can't compare steps: $editStep, $refStep because step dimensions are diferent.";
	}

	# compare left bot profile

	if ( abs( $limEdit{"xMin"} - $limRef{"xMin"} ) > 0.01 || abs( $limEdit{"yMin"} - $limRef{"yMin"} ) > 0.01 ) {

		die "Can't compare steps: $editStep, $refStep because left profile corners have different positions.";
	}

	$inCAM->COM( 'set_subsystem', "name" => '1-Up-Edit' );
	$inCAM->COM( 'show_tab',      "tab"  => "1-Up Parameters Page", "show" => 'yes' );
	$inCAM->COM( 'top_tab',       "tab"  => "1-Up Parameters Page" );

	CamHelper->SetStep( $inCAM, $editStep );

	$inCAM->COM(
				 'netlist_compare',
				 "job1"                 => $jobId,
				 "step1"                => $editStep,
				 "type1"                => 'cur',
				 "job2"                 => $jobId,
				 "step2"                => $refStep,
				 "type2"                => 'cur',
				 "recalc_cur"           => 'yes',
				 "use_cad_names"        => 'no',
				 "report_extra"         => 'yes',
				 "report_miss_on_cu"    => 'yes',
				 "report_miss"          => 'yes',
				 "max_highlight_shapes" => '5000'
	);

	$inCAM->COM( 'rv_tab_empty', report => 'netlist_compare', is_empty => 'no' );
	$inCAM->COM(
		'netlist_compare_results_show',
		"action"            => 'netlist_compare',
		"is_end_results"    => 'yes',
		"is_reference_type" => 'no',
		"job2"              => $jobId,
		"step2"             => $refStep

	);

	# store results and get NetlistReport object
	my $r = $self->__StoreResult( $editStep, $refStep );

	return $r;
}

sub __StoreResult {
	my $self     = shift;
	my $editStep = shift;
	my $stepRef  = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $file = $self->{"reportPaths"} .  $editStep . "_X_" .  $stepRef;
	$inCAM->COM( "netlist_save_compare_results", "output" => "file", "out_file" => $file );

	my $r = NetlistReport->new($file);

	return $r;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::ETesting::Netlist::NetlistCompare';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "f52457";

	my $nc = NetlistCompare->new( $inCAM, $jobId );

	#my $report = $nc->ComparePanel("mpanel");
	my $report = $nc->Compare1Up( "o+1", "o+1_panel" );

	print $report->Result();

	print $nc;

}

1;

