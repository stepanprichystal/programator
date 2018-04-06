#-------------------------------------------------------------------------------------------#
# Description: Represent Universal Drill tool manager
# This manager contain general information about all tools in NC layer
# Each tool contain
# - DrillSize
# - Process type
# - Depth
# - Magazine
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::UniDTM::UniDTM;
use base("Packages::CAM::UniDTM::UniDTM::UniDTMBase");

#3th party library
use strict;
use warnings;

#local library

use aliased 'Packages::CAM::UniDTM::Enums';
use aliased 'Enums::EnumsDrill';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	$self = $class->SUPER::new(@_);
	bless $self;

	return $self;
}

# Return tool depth
sub GetToolDepth {
	my $self        = shift;
	my $drillSize   = shift;
	my $typeProcess = shift;

	my $mess = "";
	unless ( $self->{"check"}->CheckToolDepthSet( \$mess ) ) {

		die "Tool depth in layer: " . $self->{"layer"} . " is wrong.\n $mess";
	}

	my $tool = $self->GetTool( $drillSize, $typeProcess );

	if ($tool) {
		return $tool->GetDepth();

	}
	else {

		die "Tool: $drillSize with type: $typeProcess doesn't exist.\n";
	}
}

sub GetToolMagazine {
	my $self        = shift;
	my $drillSize   = shift;
	my $typeProcess = shift;

	my $tool = $self->GetTool( $drillSize, $typeProcess );

	if ($tool) {
		return $tool->GetMagazine();
	}
	else {

		die "Tool: $drillSize with type: $typeProcess doesn't exist.\n";
	}
}

# Return tool which has minimal diameter
sub GetMinTool {
	my $self        = shift;
	my $processType = shift;

	my @tools = $self->GetUniqueTools();

	if ($processType) {

		@tools = grep { $_->GetTypeProcess() eq $processType } @tools;
	}

	my $minTool  = undef;
	my $minToolD = undef;

	for ( my $i = 0 ; $i < scalar(@tools) ; $i++ ) {

		my $t = $tools[$i];

		if ( !defined $minToolD || $t->GetDrillSize() < $minToolD ) {
			$minTool  = $t;
			$minToolD = $t->GetDrillSize();
		}
	}

	return $minTool;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAM::UniDTM::UniDTM';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId    = "d152457";
	my $stepName = "panel";
	my $unitDTM  = UniDTM->new( $inCAM, $jobId, "o+1", "m", 1 );
	
	my @tools = $unitDTM->GetUniqueTools();
	
	die;

#	use aliased 'CamHelpers::CamNCHooks';
#	use aliased 'Packages::InCAM::InCAM';
#
#	my $materialName = "PCL370HR";
#	my $machine      = "machine_a";
#	my $path         = "\\\\incam\\incam_server\\site_data\\hooks\\ncd\\";
#
#	my %toolParams = CamNCHooks->GetMaterialParams( $materialName, $machine, $path );
#
#	my $uniTool = $unitDTM->GetTool(1100);
#
#	my $magOk = 0;
#	my $parameters = CamNCHooks->GetToolParam( $uniTool, \%toolParams, \$magOk );
#
#	print $parameters ."\n".$magOk;

}

1;

