#-------------------------------------------------------------------------------------------#
# Description: Computing drill duration
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Routing::RoutDuration::RoutDuration;

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
use aliased 'CamHelpers::CamDTM';
use aliased 'Helpers::FileHelper';
use aliased 'CamHelpers::CamNCHooks';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Enums::EnumsMachines';
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::CAM::UniDTM::UniDTM';
use aliased 'Packages::CAM::UniDTM::Enums' => "EnumsDTM";
use aliased 'Packages::CAM::UniRTM::UniRTM';
use aliased 'Packages::CAM::UniRTM::Enums' => "EnumsRTM";
use aliased 'Packages::CAMJob::Routing::RoutSpeed::RoutSpeed';
use aliased 'Packages::CAMJob::Routing::RoutDuplicated::RoutDuplicated';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamHistogram';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamMatrix';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

my $FOOTDOWNLENGTH = 10;    # length of foot down (machine slow down rout speed)
my $FOOTDOWNSPEED  = 2;     # tool speed during foot down 2m/min
my $TOOLCHANGETIME = 45;    # time for tool change 45s

# Return duration or fouting for layer in second
# - Consider duplicated rout
# - Not consider tool changes
sub GetRoutDuration {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $step    = shift;
	my $layer   = shift;
	my $machine = shift // EnumsMachines->MACHINE_DEF;    # default machine for get tool parameter

	# total time of routing for step (including nested steps)
	my $duration = 0;

	my @uniqueSteps = CamStepRepeat->GetUniqueNestedStepAndRepeat( $inCAM, $jobId, $step );    # step for exploration
	push( @uniqueSteps, { "stepName" => $step, "totalCnt" => 1 } );

	my %cumulativeUsage = ();

	foreach my $s (@uniqueSteps) {

		# check if layer is not empty
		my %hist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $s->{"stepName"}, $layer, 0 );
		next if ( $hist{"total"} == 0 );

		my $workLayer = $layer;

		# If surface, layer has to be compenasete in order compute rout lengths
		if ( $hist{"surf"} ) {
			CamLayer->WorkLayer( $inCAM, $layer );
			$workLayer = CamLayer->RoutCompensation( $inCAM, $layer, "rout" );
		}

		# rout paths duration
		my %routToolUsage = $self->GetRoutToolUsage( $inCAM, $jobId, $s->{"stepName"}, $layer, $workLayer, 0 );

		CamMatrix->DeleteLayer( $inCAM, $jobId, $workLayer ) if ( $workLayer ne $layer );    # remove work layer

		# compute total duration
		foreach my $toolKey ( keys %routToolUsage ) {

			foreach my $routPath ( @{ $routToolUsage{$toolKey} } ) {

				my $len = $routPath->{"length"};
				my $speed = $routPath->{"speed"};

				# a) add to total rout tool duration (multipled by number of occurence in main step)
				$duration += ( ($len / 1000) / ($speed/60) ) * $s->{"totalCnt"};

				# b) store cumulative rout tool ussage for computing tool change (length in mm)
				# (multipled by number of occurence in main step)
				$cumulativeUsage{$toolKey} = 0 unless ( defined $cumulativeUsage{$toolKey} );
				$cumulativeUsage{$toolKey} += ($len * $s->{"totalCnt"});

			}
		}
	}

	# Compute tool change by tool limits (tool limit is taken from default machine)
	my $materialName = HegMethods->GetMaterialKind($jobId);
	my %toolParams   = CamNCHooks->GetMaterialParams( $inCAM, $jobId, $layer, $materialName, EnumsMachines->MACHINE_DEF );
	my $tChangeCnt   = 0;

	foreach my $toolKey ( keys %cumulativeUsage ) {

		my $tLim;    # in [m/10]

		# get limit of special tool
		if ( $toolKey =~ /^c(\d+)_/ ) {

			$tLim = $toolParams{"rout"}->{"spec"}->{$toolKey};
		}
		else {

			$tLim = $toolParams{"rout"}->{"def"}->{$toolKey};
		}

		$tLim = ( $tLim =~ m/N(\d+)/i )[0];

		die "Tool rout limit is not defined for tool: $toolKey in parameter file" unless ( defined $tLim );

		# Add relative tool change time because of exceed tool limit
		$duration += $cumulativeUsage{$toolKey} / ( $tLim * 100 ) * $TOOLCHANGETIME;
	}

	# Add tool change accrodin tool type count
	my @tChanges = grep {$cumulativeUsage{$_} > 0 } keys %cumulativeUsage;
	$duration += scalar(@tChanges) * $TOOLCHANGETIME;

	return $duration;
}

# Return duration or fouting for layer in second
# - Consider duplicated rout
# - Not consider tool changes
sub GetRoutToolUsage {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $step      = shift;
	my $layer     = shift;                                  # original layer
	my $workLayer = shift;                                  # layer for parsing rout (different from original if contains surfaces)
	my $SR        = shift // 0;
	my $machine   = shift // EnumsMachines->MACHINE_DEF;    # default machine for get tool parameter

	# Total rout duration per panel
	my %toolUsage = ();

	# Fill table with all standard tools (key is: c_<tool size in µm>)
	my @tools = CamDTM->GetToolTable( $inCAM, "rout" );
	$toolUsage{ "c" . $_ * 1000 } = [] foreach (@tools);

	# Fill table with all special tools  (key is: c_<tool size in µm>_<magazine info>)
	my $toolSpec = XMLin( FileHelper->Open( GeneralHelper->Root() . "\\Config\\MagazineSpec.xml" ) );
	$toolUsage{ "c" . ( $toolSpec->{"tool"}->{$_}->{"diameter"} * 1000 ) . "_" . $_ } = [] foreach ( keys %{ $toolSpec->{"tool"} } );

	my $unitDTM = UniDTM->new( $inCAM, $jobId, $step, $layer, $SR );
	my $uniRTM = UniRTM->new( $inCAM, $jobId, $step, $workLayer, $SR, $unitDTM );
	my $materialName = HegMethods->GetMaterialKind($jobId);

	# 1) Compute duration of standard rout tools
	foreach my $uniChainSeq ( $uniRTM->GetChainSequences() ) {

		$self->__SetSequenceToolUsage( $uniChainSeq, 0, $materialName, \%toolUsage );

	}

	# 2) Compute duration of duplicated rout tools

	foreach my $uniChainSeq ( $uniRTM->GetChainSequences() ) {

		my $isDupl = RoutDuplicated->GetDuplicateRout( $jobId,
													   $uniChainSeq->GetChain()->GetChainTool()->GetChainSize(),
													   $uniChainSeq->IsOutline(),
													   $layer, $step );

		if ($isDupl) {
			$self->__SetSequenceToolUsage( $uniChainSeq, 1, $materialName, \%toolUsage );
		}
	}

	return %toolUsage;
}

sub __SetSequenceToolUsage {
	my $self         = shift;
	my $uniChainSeq  = shift;
	my $isDuplicated = shift;
	my $materialKind = shift;
	my $toolUsage    = shift;

	my $uniChainTool = $uniChainSeq->GetChain()->GetChainTool();
	my $uniDTMTool   = $uniChainTool->GetUniDTMTool();

	# magazine info if special tool
	my $magazineInfo = $uniDTMTool->GetMagazineInfo();
	$magazineInfo = undef if ( $magazineInfo eq "" );

	# rout tool diamter µm
	my $drillSize = $uniDTMTool->GetDrillSize();

	# is otline
	my $isOutline = $uniChainSeq->IsOutline();

	# layer/tool operation type
	my $operation = $uniDTMTool->GetToolOperation();

	my $routSpeed = RoutSpeed->GetToolRoutSpeed( $drillSize, $operation, $magazineInfo, $isOutline, $isDuplicated, $materialKind );

	# rout length
	my $length = 0;

	foreach my $f ( $uniChainSeq->GetFeatures() ) {

		# There could be line with zero length but no undefined
		die "No length defined for rout feature id: " . $f->{"id"} if ( !defined $f->{"length"} );
		
		
		
		$length += $f->{"length"};
	}

	# store length to "rout tool usage table"

	if ($isOutline) {
		$length -= $FOOTDOWNLENGTH;    #
	}

	# store to tool ussage table
	my $key = "c" . $drillSize . ( defined $magazineInfo ? "_$magazineInfo" : "" );

	push( @{ $toolUsage->{$key} }, { "length" => $length, "speed" => $routSpeed } );

	# add time for routing foot down
	if ($isOutline) {

		push( @{ $toolUsage->{$key} }, { "length" => $FOOTDOWNLENGTH, "speed" => $FOOTDOWNSPEED } );
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use Data::Dump qw(dump);

	use aliased 'Packages::CAMJob::Routing::RoutDuration::RoutDuration';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d231312";
	my $step  = "panel";
	my $layer = "f";

	my $result = RoutDuration->GetRoutDuration( $inCAM, $jobId, $step, $layer );

	print STDERR "Result is: " . int( $result / 60 ) . ":" . sprintf( "%02s", $result % 60 ) . " error \n";

}

1;
