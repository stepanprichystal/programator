#-------------------------------------------------------------------------------------------#
# Description: Contain special function, which work with routing
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::RoutingOperation;

#3th party library
use strict;
use warnings;

#local library

use aliased 'Helpers::GeneralHelper';
 
use aliased 'CamHelpers::CamHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Packages::Polygon::Features::RouteFeatures::RouteFeatures';
use aliased 'Enums::EnumsPaths';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

#Return final thickness of pcb base on Cu layer number
sub AddPilotHole {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;
	my $layer    = shift;

	CamHelper->OpenJobAndStep( $inCAM, $jobId, $stepName );

	my $usrName = CamHelper->GetUserName($inCAM);

	# roout tools
	my @tools = ();

	#determine if take user or site file rout_size.tab
	my $toolTable = EnumsPaths->InCAM_users . $usrName . "\\hooks\\rout_size.tab";

	unless ( -e $toolTable ) {
		$toolTable = EnumsPaths->InCAM_hooks . "rout_size.tab";
	}

	@tools = @{FileHelper->ReadAsLines($toolTable)};
	@tools = sort { $a <=> $b } @tools;

	# Get information about all chains
	my $route = RouteFeatures->new();
	$route->Parse( $inCAM, $jobId, $stepName, $layer );

	my @chains = $route->GetChains();

	foreach my $chain (@chains) {

		my $chainNum  = $chain->{".rout_chain"};
		my $chainSize = $chain->{".tool_size"} / 1000; # in mm
		my $pilotSize = $self->GetPilotHole( \@tools, $chainSize );
		$inCAM->COM("chain_list_reset");
		$inCAM->COM( "chain_list_add", "chain" => $chainNum );
		$inCAM->COM( "chain_del_pilot", "layer" => $layer ); # delete pilot if exist
		 
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
	my $self       = shift;
	my @drillTools = @{ shift(@_) };    #available drill tool size
	my $routSize   = shift;             #rout size

	my $lastTool;

	for ( my $i = 0 ; $i < scalar(@drillTools) ; $i++ ) {

		my $drill = $drillTools[$i];
		chomp($drill);

		if ( $drill <= $routSize ) {

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

	#use aliased 'Packages::Routing::RoutingOperation';
 	#use aliased 'Packages::InCAM::InCAM';

	#my $jobId = "f13610";
	#my $inCAM = InCAM->new();

	#my $step  = "o+1";
	#my $layer = "f";
	#my $test = RoutingOperation->AddPilotHole( $inCAM, $jobId, $step, $layer);

	#print $test;

}

1;
