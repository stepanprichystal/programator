
#-------------------------------------------------------------------------------------------#
# Description: Library for comparing netlist in job
# Notice: Word "Reference" - means step which is original
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
use aliased 'Packages::ETesting::Netlist::NetlistReport';
use aliased 'Packages::CAMJob::Panelization::SRStep';

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

sub Compare1Up {
	my $self    = shift;
	my $step    = shift;
	my $stepRef = shift;

	my $jobRef = $self->{"jobId"};

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	$inCAM->COM( 'set_subsystem', "name" => '1-Up-Edit' );
	CamHelper->SetStep( $inCAM, $step );
	$inCAM->COM( 'rv_tab_empty', report => 'netlist_compare', is_empty => 'yes' );

	$inCAM->COM(
				 'netlist_compare',
				 "job1"                 => $jobId,
				 "step1"                => $step,
				 "type1"                => 'cur',
				 "job2"                 => $jobRef,
				 "step2"                => $stepRef,
				 "type2"                => 'cur',
				 "recalc_cur"           => 'yes',
				 "use_cad_names"        => 'no',
				 "report_extra"         => 'yes',
				 "report_miss_on_cu"    => 'yes',
				 "report_miss"          => 'yes',
				 "max_highlight_shapes" => '5000'
	);

	$inCAM->COM( 'rv_tab_view_results_enabled', "report" => 'netlist_compare', "is_enabled" => 'yes', "serial_num" => '-1', "all_count" => '-1' );
	$inCAM->COM(
		'netlist_compare_results_show',
		"action"            => 'netlist_compare',
		"is_end_results"    => 'yes',
		"is_reference_type" => 'no',
		"job2"              => $jobRef,
		"step2"             => $stepRef

	);

	# store results and get NetlistReport object
	my $r = $self->__StoreResult( $step, $jobRef, $stepRef );

	return $r;

}

sub ComparePanel {
	my $self = shift;
	my $step = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $stepRef = undef;    # if step ref not defined, create own step with original data

	# 1) test if panel contain SR steps
	unless ( CamStepRepeat->ExistStepAndRepeats( $inCAM, $jobId, $step ) ) {
		die "Cannot compare \"$step\" netlist as \"panel\", because there is no Step and Repeat steps.";
	}

	my @sr = CamStepRepeat->GetStepAndRepeat( $inCAM, $jobId, $step );

	# 2) check if each sr in panel has original reference step
 
	my %mapRef = ();

	foreach my $s (@sr) {

		if ( $s->{"gSRstep"} eq "o+1" ) {

			my $ref = ( grep { CamHelper->StepExists( $inCAM, $jobId, $_ ) } ( "o", "input", "pcb" ) )[0];

			if ($ref) {

				$mapRef{ $s->{"gSRstep"} } = $ref;
			}
			else {
				die "Ori doesn't exist for: " . $s->{"gSRstep"};
			}

		}
		else {

			if ( CamHelper->StepExists( $inCAM, $jobId, $s->{"gSRstep"} . "_+1" ) ) {

				$mapRef{ $s->{"gSRstep"} } = $s->{"gSRstep"} . "_+1";
			}
			else {
				die "Ori step doesn't exist for: " . $s->{"gSRstep"};
			}
		}
	}

	# 1) Create "reference" panel from exist panel

	my $panelRef = $step . "_ref";

	if ( CamHelper->StepExists( $inCAM, $jobId, $panelRef ) ) {
		$inCAM->COM( "delete_entity", "job" => $jobId, "name" => $panelRef, "type" => "step" );
	}

	$inCAM->COM(
				 'copy_entity',
				 "type"           => 'step',
				 "source_job"     => $jobId,
				 "source_name"    => $step,
				 "dest_job"       => $jobId,
				 "dest_name"      => $panelRef,
				 "dest_database"  => "",
				 "remove_from_sr" => "yes"
	);

	my @boardLayers = map { $->{"gROWname"} } CamJob->GetBoardLayers($inCAM, $jobId);


	my %mapRefTmp = ();

	foreach my $step ( keys %mapRef ) {

		my $refStep    = $mapRef{$step};
		my $refStepTmp = $refStep . "_tmp";
		
		$mapRefTmp{$refStep} = $refStepTmp;

		if ( CamHelper->StepExists( $inCAM, $jobId, $refStepTmp ) ) {
			$inCAM->COM( "delete_entity", "job" => $jobId, "name" => $refStepTmp, "type" => "step" );
		}
		


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
					 "margin"      => "0",
					 "feat_types"  => "line\;pad\;surface\;arc\;text",
					 "pol_types"   => "positive\;negative"
		);
 
	}
	
	# Replace "processed" steps in panel with "tmp reference" steps
	my 
	
	
	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $sr = SRStep->new($inCAM, $jobId, $mpanel_ref);
	$sr->Create();
	
	my $self       = shift;
	
	my $stepWidth  = shift;    # request on onlyu some layers
	my $stepHeight = shift;    # request on onlyu some layers
	my $margTop    = shift;
	my $margBot    = shift;
	my $margLeft   = shift;
	my $margRight  = shift;
	my $profPos    = shift; 
	
	Packages::CAMJob::Panelization::SRStep
		

	}

	# 1) create tmp ori 1up steps with cut layers behind profile
	copy_step

	  copy_entity, type = step, source_job = f52456, source_name = mpanel, dest_job = f52456, dest_name = mpanel_ref, dest _database =,
	  remove_from_sr =
	  yes(3)

}

sub GetStoredReports {
	my $self = shift;

	my @reports = ();

	my $dir = undef;
	opendir( $dir, $self->{"reportPaths"} ) or die $!;

	while ( my $file = readdir($dir) ) {

		next unless $file =~ /^Edit(\w\d+)/i;

		my $filePath = $self->{"reportPaths"} . $file;

		push( @reports, NetlistReport->new($filePath) );

	}

	closedir($dir);

	return @reports;

}

sub __StoreResult {
	my $self    = shift;
	my $step    = shift;
	my $stepRef = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $jobRef = $self->{"jobId"};

	my $file = $self->{"reportPaths"} . "Edit" . $jobId . "_" . $step . "_Ref" . $jobRef . "_" . $stepRef;
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

	my $jobId = "f52456";

	my $nc = NetlistCompare->new( $inCAM, $jobId );

	$nc->Compare1Up( "o+1", "o" );

	print $nc;

}

1;

