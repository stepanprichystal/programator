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

	# 2) Check if tool parameters are set correctly
	unless ( $self->CheckNonBoardLayers( $inCAM, $jobId, $mess ) ) {

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

		# if uniDTM check fail, dont do another control
		unless ( $l->{"uniDTM"}->CheckTools() ) {
			next;
		}

		unless ( $l->{"uniDTM"}->GetChecks()->CheckMagazine($mess) ) {
			$result = 0;
			$$mess .= "\n";
		}

		unless ( $l->{"uniDTM"}->GetChecks()->CheckSpecialTools($mess) ) {
			$result = 0;
			$$mess .= "\n";
		}

	}

	

	return $result;
}

# Check if some layers are non board
sub CheckNonBoardLayers {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $mess  = shift;

	my $result = 1;

	my @layers = CamJob->GetAllLayers( $inCAM, $jobId );
	CamDrilling->AddNCLayerType( \@layers );

	# search for layer which has defined "type" but is not board

	my @nonBoard = grep { defined $_->{"type"} && $_->{"gROWcontext"} ne "board" } @layers;
	@nonBoard = grep { $_->{"gROWname"} !~ /_/ && $_->{"gROWname"} !~ /v\d/ } @nonBoard;

	if ( scalar(@nonBoard) ) {

		@nonBoard = map { "\"".$_->{"gROWname"}."\"" } @nonBoard;
		my $str = join( "; ", @nonBoard );

		$result = 0;
		$$mess .= "Matrix contains rout/drill layers, which are not board ($str). Is it ok? \n";

	}

	return $result;
}
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

  use aliased 'Packages::Drilling::DrillChecking::LayerCheckWarn';

  use aliased 'Packages::InCAM::InCAM';

  my $inCAM = InCAM->new();
  my $jobId = "f71555";

  my $mess = "";

  my $result = LayerCheckWarn->CheckNCLayers( $inCAM, $jobId, "o+1", undef, \$mess );

  print STDERR "Result is $result \n";

  print STDERR " $mess \n";

}

1;
