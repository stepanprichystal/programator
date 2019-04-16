#-------------------------------------------------------------------------------------------#
# Description: Computing drill duration
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Drilling::DrillDuration::DrillDuration;

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);
use POSIX qw(floor ceil);
use XML::Simple;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAM::UniDTM::UniDTM';
use aliased 'CamHelpers::CamDTM';
use aliased 'Helpers::FileHelper';
use aliased 'CamHelpers::CamNCHooks';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Enums::EnumsMachines';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsDrill';
use aliased 'Packages::CAM::UniDTM::Enums' => "EnumsDTM";
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamHistogram';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

my $TOOLCHANGETIME = 40;    # time for tool change 40s

# Return duration of job/step/layer in second
# Consider Pilot holes
sub GetDrillDuration {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;
	my $layer    = shift;
	my $SR       = shift // 0;
	my $machine  = shift // EnumsMachines->MACHINE_DEF;    # default machine for get tool parameter

	# total time of drilling for step (including nested steps)
	my $duration = 0;

	# Parse file where are stored measured duration (per 100 holes) for all tools
	my %measuredDur = ();

	my @lines = @{ FileHelper->ReadAsLines( GeneralHelper->Root() . "\\Packages\\CAMJob\\Drilling\\DrillDuration\\DrillToolDuration.csv" ) };

	foreach my $l (@lines) {

		$l =~ s/\s//g;
		$measuredDur{ "c" . $1 } = [ $2, $3 ] if ( $l =~ m/(\d+);(\d+);(\d+)/ );
	}

	my @uniqueSteps = CamStepRepeat->GetUniqueNestedStepAndRepeat( $inCAM, $jobId, $stepName );    # step for exploration
	push( @uniqueSteps, { "stepName" => $stepName, "totalCnt" => 1 } );

	my %cumulativeUsage = ();

	foreach my $s (@uniqueSteps) {

		# check if layer is not empty
		my %hist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $s->{"stepName"}, $layer, 0 );
		next if ( $hist{"total"} == 0 );

		# rout paths duration
		my %drillToolUsage = $self->GetDrillToolUsage( $inCAM, $jobId, $s->{"stepName"}, $layer, 0 );

		# compute total duration
		foreach my $toolKey ( keys %drillToolUsage ) {

			next unless ( $drillToolUsage{$toolKey} );

			die "Duration is not defined for tool $toolKey" unless ( defined $measuredDur{$toolKey} );

			# a) add to total drill tool duration (multipled by number of occurence in main step)
			$duration += ( $drillToolUsage{$toolKey} * $measuredDur{$toolKey}->[1] / 100 ) * $s->{"totalCnt"};    # drill holes duration

			# b) store cumulative rout tool ussage for computing tool change (length in mm)
			# (multipled by number of occurence in main step)
			$cumulativeUsage{$toolKey} = 0 unless ( defined $cumulativeUsage{$toolKey} );
			$cumulativeUsage{$toolKey} += $drillToolUsage{$toolKey} * $s->{"totalCnt"};
		}
	}

	# Compute tool change by tool limits (tool limit is taken from default machine).

	my $materialName = HegMethods->GetMaterialKind($jobId);
	my %toolParams   = CamNCHooks->GetMaterialParams( $inCAM, $jobId, $layer, $materialName, EnumsMachines->MACHINE_DEF );
	my $tChangeCnt   = 0;

	foreach my $toolKey ( keys %cumulativeUsage ) {

		my $tLim;    # in [m/10]

		# get limit of special tool
		if ( $toolKey =~ /^c(\d+)_/ ) {

			$tLim = $toolParams{"drill"}->{"spec"}->{$toolKey};
		}
		else {

			$tLim = $toolParams{"drill"}->{"def"}->{$toolKey};
		}

		$tLim = ( $tLim =~ m/N(\d+)/i )[0];

		die "Tool drill limit is not defined for tool: $toolKey in parameter file" unless ( defined $tLim );

		# Add relative tool change time because of exceed tool limit
		$duration += $cumulativeUsage{$toolKey} / ( $tLim * 100 )  * $measuredDur{$toolKey}->[0];

	}

	# Add tool change accrodin tool type count
	my @tChanges = grep { $cumulativeUsage{$_} > 0 } keys %cumulativeUsage;
	
	$duration += $measuredDur{$_}->[0] foreach(@tChanges);

	# Add one extra tool change
	$duration += $TOOLCHANGETIME;

	return $duration;
}

sub GetDrillToolUsage {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $step    = shift;
	my $layer   = shift;
	my $SR      = shift // 0;
	my $machine = shift // EnumsMachines->MACHINE_DEF;    # default machine for get tool parameter

	# Drill tool usage table
	my %toolUsage = ();

	# Fill table with all standard tools (key is: c_<tool size in µm>)
	my @tools = CamDTM->GetToolTable( $inCAM, "drill" );
	$toolUsage{ "c" . $_ * 1000 } = 0 foreach (@tools);

	# Fill table with all special tools  (key is: c_<tool size in µm>_<magazine info>)
	my $toolSpec = XMLin( FileHelper->Open( GeneralHelper->Root() . "\\Config\\MagazineSpec.xml" ) );

	$toolUsage{ "c" . ( $toolSpec->{"tool"}->{$_}->{"diameter"} * 1000 ) . "_" . $_ } = 0 foreach ( keys %{ $toolSpec->{"tool"} } );

	# Get tool parameters (need drill limiot for holes)

	my $unitDTM = UniDTM->new( $inCAM, $jobId, $step, $layer, $SR );

	my @tool = grep { $_->GetTypeProcess() eq EnumsDrill->TypeProc_HOLE } $unitDTM->GetUniqueTools();

	my @dtmTools = CamDTM->GetDTMTools( $inCAM, $jobId, $step, $layer, $SR );

	foreach my $t (@tool) {

		# Add standard tool counts
		foreach my $dtmTools (@dtmTools) {

			if ( $dtmTools->{"gTOOLdrill_size"} eq $t->GetDrillSize() ) {

				$toolUsage{ "c" . $t->GetDrillSize() } += $dtmTools->{"gTOOLcount"};
			}
		}

		# Add pilot holes
		if ( $toolUsage{ "c" . $t->GetDrillSize() } > 0 ) {

			foreach my $p ( $unitDTM->GetPilots( $t->GetDrillSize() ) ) {

				$toolUsage{ "c" . $p } += $toolUsage{ "c" . $t->GetDrillSize() };
			}
		}
	}

	return %toolUsage;
 
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use Data::Dump qw(dump);

	use aliased 'Packages::CAMJob::Drilling::DrillDuration::DrillDuration';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d113609";
	my $step  = "panel";
	my $layer = "m";

	my $result = DrillDuration->GetDrillDuration( $inCAM, $jobId, $step, $layer );

	print STDERR "Result is: " . int( $result / 60 ) . ":" . sprintf( "%02s", $result % 60 ) . " error \n";

}

1;
