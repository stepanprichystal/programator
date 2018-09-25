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
use aliased 'Packages::CAM::UniDTM::Enums' => "EnumsDTM";

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#
# Return duration of job/step/layer in second
# Consider Pilot holes
sub GetDrillDuration {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;
	my $layer = shift;
	my $SR    = shift // 1;

	# Parse duration of drill holes
	my %duration = ();

	my @lines = @{ FileHelper->ReadAsLines( GeneralHelper->Root() . "\\Packages\\CAMJob\\Drilling\\DrillDuration\\DrillToolDuration.csv" ) };

	foreach my $l (@lines) {

		$l =~ s/\s//g;

		if ( $l =~ m/(\d+);(\d+);(\d+)/ ) {

			$duration{$1} = [ $2, $3 ];
		}
	}

	# Get tool parameters (need drill limiot for holes)

	my $materialName = HegMethods->GetMaterialKind($jobId);
	my $machine      = EnumsMachines->MACHINE_C;                                          # default is C, contain all hole diamters
	my $path         = EnumsPaths->InCAM_hooks . "\\ncd\\";
	my %toolParams   = CamNCHooks->GetMaterialParams( $materialName, $machine, $path );

	my $unitDTM = UniDTM->new( $inCAM, $jobId, $step, $layer, $SR );

	my @tool = grep { $_->GetTypeProcess() eq EnumsDTM->TypeProc_HOLE } $unitDTM->GetUniqueTools();

	my @dtmTools = CamDTM->GetDTMTools( $inCAM, $jobId, $step, $layer, $SR );

	my %toolsCnt = ();

	foreach my $t (@tool) {

		unless ( exists $toolsCnt{ $t->GetDrillSize() } ) {

			$toolsCnt{ $t->GetDrillSize() } = 0;
		}

		foreach my $dtmTools (@dtmTools) {

			if ( $dtmTools->{"gTOOLdrill_size"} eq $t->GetDrillSize() ) {

				$toolsCnt{ $t->GetDrillSize() } += $dtmTools->{"gTOOLcount"};
			}
		}

		# Add pilot holes
		if ( $toolsCnt{ $t->GetDrillSize() } > 0 ) {

			foreach my $p ( $unitDTM->GetPilots( $t->GetDrillSize() ) ) {

				unless ( exists $toolsCnt{$p} ) {

					$toolsCnt{$p} = 0;
				}

				$toolsCnt{$p} += $toolsCnt{ $t->GetDrillSize() };
			}
		}
	}

	my $total = 0;

	foreach my $tSize ( keys %toolsCnt ) {

		#print STDERR $tSize . "- ";

		unless ( defined $duration{$tSize} ){
			die;
		}

		die "Duration is not defined for tool $tSize" unless ( defined $duration{$tSize} );

		$total += $toolsCnt{$tSize} * $duration{$tSize}->[1] / 100;    # drill holes duration

		#print STDERR " Cnt = " . $toolsCnt{$tSize};
		#print STDERR " Drill 1 hole = " . $duration{$tSize}->[1] / 100;
		#print STDERR " Drill time = " . $toolsCnt{$tSize} * $duration{$tSize}->[1] / 100;

		my $uniDTMTool = $unitDTM->GetTool( $tSize, EnumsDTM->TypeProc_HOLE );

		my $params = CamNCHooks->GetToolParam( $uniDTMTool, \%toolParams );

		my ($limit) = $params =~ m/N(\d+)/i;

		unless ( defined $limit ) {
			die "Tool drill limit is not defined for tool $tSize in parameter file" unless ( defined $duration{$tSize} );
		}

		my $num = ceil( $toolsCnt{$tSize} / ( $limit * 100 ) );

		#print STDERR " Vymena = " . $num;
		#print STDERR " Total = "
		#  . ( $toolsCnt{$tSize} * $duration{$tSize}->[1] / 100 + ceil( $toolsCnt{$tSize} / ( $limit * 100 ) ) * $duration{$tSize}->[0] ) . "\n";

		$total += ceil( $toolsCnt{$tSize} / ( $limit * 100 ) ) * $duration{$tSize}->[0];    # duration of tool preparing

	}

	# 1 vymena navic
	return $total + 40;
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
	my $jobId = "d152457";
	my $step  = "panel";
	my $layer = "m";

	my $result = DrillDuration->GetDrillDuration( $inCAM, $jobId, $step, $layer );

	print STDERR "Result is: " . int( $result / 60 ) . ":" . sprintf( "%02s", $result % 60 ) . " error \n";

}

1;
