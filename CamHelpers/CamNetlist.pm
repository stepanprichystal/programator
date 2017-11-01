#-------------------------------------------------------------------------------------------#
# Description: Helper class, contains general function working with netlists
# Author:SPR
#-------------------------------------------------------------------------------------------#

package CamHelpers::CamNetlist;

#3th party library
use strict;
use warnings;

#loading of locale modules

use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamLayer';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::GeneralHelper';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

# Return all helper netlist steps name
# Netlist steps are steps, whixh name is:
# - ori_netlist_<edit step>
# - edit_netlist_<edit step>
sub GetNetlistSteps {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;    # if defined, remove netlist steps for this edited step

	my $patt = "_netlist_";

	if ($step) {

		$patt .= $step;
	}
	$patt = quotemeta($patt);
	my @steps = grep { $_ =~ /((ori)|(edit))$patt/i } CamStep->GetAllStepNames( $inCAM, $jobId );

	return @steps;

}

# Remove all helper netlist steps
# Netlist steps are steps, whixh name is:
# - ori_netlist_<edit step>
# - edit_netlist_<edit step>
sub RemoveNetlistSteps {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;    # if defined, remove netlist steps for this edited step

	my @steps = $self->GetNetlistSteps( $inCAM, $jobId, $step );

	foreach my $s (@steps) {

		$inCAM->INFO(
					  units             => 'mm',
					  "angle_direction" => 'ccw',
					  "entity_type"     => 'step',
					  "entity_path"     => "$jobId/$step",
					  "data_type"       => 'NETS_LIST'
		);

		my @netlists = ();

		for ( my $i = 0 ; $i < scalar( @{ $inCAM->{doinfo}{gNETS_LIST} } ) ; $i++ ) {

			my $netlistName = ${ $inCAM->{doinfo}{gNETS_LIST} }[$i];
			
			if($netlistName eq "curnet"){
				
				$inCAM->COM( "netlist_delete", "job" => $jobId, "step" => $s, "type" => "cur", "layers_list" => "" );
			}
			
		}

		CamStep->DeleteStep( $inCAM, $jobId, $s );
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'CamHelpers::CamNetlist';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f52457";
	my $step  = "panel";

	my @steps = CamNetlist->GetNetlistSteps( $inCAM, $jobId, "o+1" );

	print "ddd";

}

1;
