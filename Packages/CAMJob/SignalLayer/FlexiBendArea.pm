#-------------------------------------------------------------------------------------------#
# Description: Adjustment of customer schema
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::SignalLayer::FlexiBendArea;

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'Packages::Polygon::Features::PolyLineFeatures::PolyLineFeatures';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamSymbolSurf';
use aliased 'CamHelpers::CamSymbol';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::Stackup::StackupOperation';
use aliased 'Packages::Stackup::Enums' => 'EnumsStack';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#
# Check if mpanel contain requsted schema by customer
sub PutCuToBendArea {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $step      = shift;
	my $clearance = shift // 250;    # Default clearance of Cu from bend border is 250µm

	my $result = 1;

	my $bendAreaL = "bend";
	unless ( CamHelper->LayerExists( $inCAM, $jobId, $bendAreaL ) ) {
		die "Benda area layer: $bendAreaL doesn't exists";
	}

	my $polyLine = PolyLineFeatures->new();
	$polyLine->Parse( $inCAM, $jobId, $step, $bendAreaL );

	my @polygons = $polyLine->GetPolygonsPoints();

	die "No bend area (polygons) found in bend layer: $bendAreaL" unless (@polygons);

	# put Cu only to rigid signal layer
	my @layers = ();

	my @lamPackages = StackupOperation->GetLaminatePackages($jobId);

	foreach my $lamPckg (@lamPackages) {

		if (    $lamPckg->{"packageTop"}->{"coreType"} eq EnumsStack->CoreType_FLEX
			 && $lamPckg->{"packageBot"}->{"coreType"} eq EnumsStack->CoreType_RIGID )
		{

			my $lName = $lamPckg->{"packageBot"}->{"layers"}->[0]->GetCopperName();

			die "Not a inner copper layer: $lName" if ( $lName !~ /^v\d+$/ );
			push( @layers, $lName );
		}
		elsif (    $lamPckg->{"packageBot"}->{"coreType"} eq EnumsStack->CoreType_RIGID
				&& $lamPckg->{"packageTop"}->{"coreType"} eq EnumsStack->CoreType_FLEX )
		{

			my $lName = $lamPckg->{"packageTop"}->{"layers"}->[-1]->GetCopperName();

			die "Not a inner copper layer: $lName" if ( $lName !~ /^v\d+$/ );
			push( @layers, $lName );
		}
	}

	CamHelper->SetStep( $inCAM, $step );
	CamLayer->AffectLayers( $inCAM, \@layers );

	foreach my $poly (@polygons) {

		my @points = map { { "x" => $_->[0], "y" => $_->[1] } } @{$poly};
		my @pointsSurf = @points[ 0 .. scalar(@points) - 2 ];

		#CamSymbolSurf->AddSurfaceSolidPattern( $inCAM, 1, 2000, 1 );
		CamSymbolSurf->AddSurfacePolyline( $inCAM, \@pointsSurf, 1 );
		CamSymbol->AddPolyline( $inCAM, \@points, "r" . ( 2 * $clearance ), "negative" );

	}

	CamLayer->ClearLayers($inCAM);

	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAMJob::SignalLayer::FlexiBendArea';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d222763";

	my $mess = "";

	my $result = FlexiBendArea->PutCuToBendArea( $inCAM, $jobId, "o+1" );

	print STDERR "Result is: $result, error message: $mess\n";

}

1;
