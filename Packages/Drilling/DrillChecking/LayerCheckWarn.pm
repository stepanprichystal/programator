#-------------------------------------------------------------------------------------------#
# Description: Class is responsible for checking drilling warnings
# when some warning occur, NC export is still possible
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Drilling::DrillChecking::LayerCheckWarn;

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library

#use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Packages::Polygon::Features::RouteFeatures::RouteFeatures';
use aliased 'Packages::CAM::UniDTM::UniDTM';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

sub CheckNCLayers {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $stepName    = shift;
	my $layerFilter = shift;
	my $mess        = shift;

	my $result = 1;

	# Get all layers
	my @allLayers = ( CamJob->GetLayerByType( $inCAM, $jobId, "drill" ), CamJob->GetLayerByType( $inCAM, $jobId, "rout" ) );
	my @layers = ();

	# Filter if exist requsted layer
	if ($layerFilter) {

		my %tmp;
		@tmp{ @{$layerFilter} } = ();
		@layers = grep { exists $tmp{ $_->{"gROWname"} } } @allLayers;

	}
	else {
		@layers = @allLayers;
	}

	CamDrilling->AddNCLayerType( \@layers );
	CamDrilling->AddLayerStartStop( $inCAM, $jobId, \@layers );

	# Add histogram and uni DTM

	foreach my $l (@layers) {

		my %fHist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $stepName, $l->{"gROWname"} );
		$l->{"fHist"} = \%fHist;

		my %attHist = CamHistogram->GetAttHistogram( $inCAM, $jobId, $stepName, $l->{"gROWname"} );
		$l->{"attHist"} = \%attHist;

		if ( $l->{"gROWlayer_type"} eq "rout" ) {

			my $route = RouteFeatures->new();

			$route->Parse( $inCAM, $jobId, $stepName, $l->{"gROWname"}, 1 );
			my @f = $route->GetFeatures();
			$l->{"feats"} = \@f;

		}

		$l->{"uniDTM"} = UniDTM->new( $inCAM, $jobId, $stepName, $l->{"gROWname"}, 1 );

	}

	 
	
	# 1) Check if tool parameters are set correctly
	unless ( $self->CheckToolParameters( $inCAM, $jobId, $stepName, \@layers, $mess ) ) {

		$result = 0;
	}
	
 
	return $result;

}
 

# Check if tools are unique within while layer, check if all necessary parameters are set
sub CheckToolParameters {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;
	my @layers   = @{ shift(@_) };
	my $mess     = shift;

	my $result = 1;
 
	foreach my $l (@layers) {

		unless ( $l->{"uniDTM"}->GetChecks()->CheckMagazine($mess) ) {
			$result = 0;
			$$mess .= "\n";
		}
		
		unless ( $l->{"uniDTM"}->GetChecks()->CheckSpecialTools($mess) ) {
			$result = 0;
			$$mess .= "\n";
		}
		
		
	}
	
	 # 3) Check if rout layers don't contain tool less than 500µm
	foreach my $l ( grep { $_->{"gROWlayer_type"} eq "rout" } @layers ) {

		my @unitTools = $l->{"uniDTM"}->GetTools();

		foreach my $t (@unitTools) {

			if ( $t->GetDrillSize() < 500 ) {
				$result = 0;
				$$mess .= "NC layer \"" . $l->{"gROWname"} . "\".\n";
				$$mess .= "Routing layers should not contain tools diamaeter smaller than 500µm. Layer contains tool diameter: " . $t->GetDrillSize() . "µm.\n";
			}
		}
	}

	return $result;
}
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Drilling::DrillChecking::LayerCheckError';

	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f52456";

	my $mess = "";

	my $result = LayerCheckError->CheckNCLayers( $inCAM, $jobId, "o+1", undef, \$mess );

	print STDERR "Result is $result \n";

	print STDERR " $mess \n";

}

1;
