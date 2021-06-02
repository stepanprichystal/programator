#-------------------------------------------------------------------------------------------#
# Description: Contain special function, which work with routing
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::PilotHole;

#3th party library
use strict;
use warnings;
use Math::Polygon;
use List::Util qw[max];

#local library

use aliased 'Helpers::GeneralHelper';

use aliased 'CamHelpers::CamHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Packages::Polygon::Features::RouteFeatures::RouteFeatures';
use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamDTM';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamStepRepeat';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

# Add pilot hole to layer and step
sub AddPilotHole {
	my $self           = shift;
	my $inCAM          = shift;
	my $jobId          = shift;
	my $stepName       = shift;
	my $layer          = shift;
	my $reducedSize    = shift // 70;     # Pilot holes are 70% diameter of rout size
	my $minReducedSize = shift // 500;    # Minimal pilot holes 500um

	CamHelper->SetStep( $inCAM, $stepName );

	my $usrName = CamHelper->GetUserName($inCAM);

	# roout tools
	my @tools = CamDTM->GetToolTable( $inCAM, "drill" );

	# Get information about all chains
	my $route = RouteFeatures->new();
	$route->Parse( $inCAM, $jobId, $stepName, $layer );

	my @chains = $route->GetChains();

	foreach my $chain (@chains) {

		my $chainNum  = $chain->{".rout_chain"};
		my $chainSize = $chain->{".tool_size"} / 1000;                              # in mm
		my $pilotSize = $self->GetPilotHole( \@tools, $chainSize, $reducedSize );

		if ( $pilotSize < $minReducedSize / 1000 ) {
			$pilotSize = $self->GetPilotHole( \@tools, $chainSize, 100 );
		}

		die "No pilot holes found for rout tool: ${chainSize}um" unless ( defined $pilotSize );

		$inCAM->COM("chain_list_reset");
		$inCAM->COM( "chain_list_add",  "chain" => $chainNum );
		$inCAM->COM( "chain_del_pilot", "layer" => $layer );                        # delete pilot if exist

		$inCAM->COM(
					 "chain_add_pilot",
					 "layer"          => $layer,
					 "pilot_size"     => $pilotSize,
					 "mode"           => "plunge",
					 "ext_layer"      => $layer,
					 "offset_along"   => "0",
					 "offset_perpend" => "0"
		);
	}

}

# Return best pilot hole for chain size
sub GetPilotHole {
	my $self        = shift;
	my @drillTools  = @{ shift(@_) };    #available drill tool size
	my $routSize    = shift;             #rout size
	                                     # Value means pilot hole percentage size of rout size.
	                                     # Default 100% pilot diameter == rout diameter
	my $reducedSize = shift // 100;

	my $lastTool = undef;

	for ( my $i = 0 ; $i < scalar(@drillTools) ; $i++ ) {

		my $drill = $drillTools[$i];
		chomp($drill);

		if ( $drill <= $routSize * ( $reducedSize / 100 ) ) {

			$lastTool = $drill;
		}
		else {

			last;
		}
	}
	return $lastTool;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Routing::PilotHole';
	use aliased 'Packages::InCAM::InCAM';

	my $jobId = "d321973";
	my $inCAM = InCAM->new();

	my $step = "o+1";

	my $max = PilotHole->AddPilotHole( $inCAM, $jobId, $step, "f", 80 );

}

1;
