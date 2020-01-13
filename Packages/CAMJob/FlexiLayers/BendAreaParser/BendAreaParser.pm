
#-------------------------------------------------------------------------------------------#
# Description: Parse "bend area" layer for rigid flex pcb
# - BendArea class contain closed polygon features, which has always CCW direction
# - Features in "BendArea" not match with original layer features. (feat id can
#   be different, arcs can be aproxiamted)
# - Transition zone feature is oriented as well CCW, thus pcb rigid part of
#   is always on right
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::FlexiLayers::BendAreaParser::BendAreaParser;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Polygon::Features::PolyLineFeatures::PolyLineFeatures';
use aliased 'Packages::CAMJob::FlexiLayers::BendAreaParser::BendArea';
use aliased 'Packages::CAMJob::FlexiLayers::BendAreaParser::TransitionZone';
use aliased 'Packages::Polygon::Polygon::PolygonPoints';
use aliased 'Packages::Polygon::Enums' => 'PolyEnums';
use aliased 'Enums::EnumsRout';
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamMatrix';
use aliased 'Packages::CAMJob::FlexiLayers::BendAreaParser::Enums';
#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#


sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}          = shift;
	$self->{"jobId"}          = shift;
	$self->{"step"}           = shift;
	$self->{"bendAreaDir"}    = shift // PolyEnums->Dir_CCW;    # Packages::Polygon::Enums::Dir_<CW|CCW>
	$self->{"resizeBendArea"} = shift // 0;                     # Resize polygon feature of bend area
	$self->{"layer"}          = shift // "bend";

	# PROPERTIES

	$self->{"bendAreas"} = [];

	$self->__LoadBendArea();

	return $self;
}

sub CheckBendArea {
	my $self    = shift;
	my $errMess = shift;

	my $result = 1;

	# 1) Check if polygons have two transition zone
	foreach my $bendArea ( @{ $self->{"bendAreas"} } ) {

		# 1) Check minimal number of bend area features (4)
		my @features = $bendArea->GetFeatures();

		if ( scalar(@features) < 4 ) {

			$$errMess .= "BendArea with features: " . join( "; ", map { $_->{"id"} } $bendArea->GetFeatures() ) . "\n";

			$$errMess .= "Number of bend area features has to be at least four (current number is: " . scalar(@features) . ")\n";
			$result = 0;
		}

		# 2) Check requested number of transition zone (2)
		my @tZones = $bendArea->GetTransitionZones();

		if ( scalar(@tZones) < 2 ) {

			$$errMess .= "BendArea with features: " . join( "; ", map { $_->{"id"} } $bendArea->GetFeatures() ) . "\n";
			$$errMess .= "Number of transition zone is less than: 2 (current number is: " . scalar(@tZones) . ". Feature attribute:transition_zone .)\n";
			$result = 0;
		}

		# 3) Check if transition yones contain only lines

		foreach my $tZone (@tZones) {

			if ( $tZone->GetFeature()->{"type"} !~ /^[LA]$/i ) {

				$$errMess .= "Only line/arc features are allowed for transition zone (err feat id: " . $tZone->GetFeature()->{"id"} . ")\n";
				$result = 0;
			}
		}

	}

	return $result;
}

sub GetLayerName {
	my $self = shift;

	return $self->{"layer"};
}

sub GetBendAreas {
	my $self = shift;

	return @{ $self->{"bendAreas"} };
}

sub __LoadBendArea {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};
	my $layer = $self->{"layer"};

	my $polyLine = PolyLineFeatures->new();

	# Copy coverlaypin data to new lazer and resize
	my $resizeLayer = GeneralHelper->GetGUID();
	if ( $self->{"resizeBendArea"} != 0 ) {

		my $tmp = GeneralHelper->GetGUID();
		CamMatrix->CopyLayer( $inCAM, $jobId, $self->{"layer"}, $step, $tmp, $step );
		CamLayer->WorkLayer( $inCAM, $tmp );
		$inCAM->COM( 'sel_resize_poly', "size" => $self->{"resizeBendArea"} );
		$polyLine->Parse( $inCAM, $jobId, $step, $tmp );

		CamMatrix->DeleteLayer( $inCAM, $jobId, $tmp );
	}
	else {

		$polyLine->Parse( $inCAM, $jobId, $step, $layer );
	}

	# return parsed feature polygons, cyclic only CW or CCW)
	my @polygons = $polyLine->GetPolygonsFeatures();

	# 1) Check if there is detected some polygon area
	die "No bend area detected in step: $step; layer: $layer" if ( !scalar(@polygons) );

	foreach my $polygon (@polygons) {


		# switch direction to CWW
		my @points = map { [ $_->{"x1"}, $_->{"y1"} ] } @{$polygon};    # rest of points "x2,y2"
		my $dir = PolygonPoints->GetPolygonDirection( \@points );

		my @feats = @{$polygon};

		if ( $dir ne $self->{"bendAreaDir"} ) {

			@feats = reverse(@feats);

			foreach my $f (@feats) {

				my $pX = $f->{"x2"};
				my $pY = $f->{"y2"};
				$f->{"x2"} = $f->{"x1"};
				$f->{"y2"} = $f->{"y1"};
				$f->{"x1"} = $pX;
				$f->{"y1"} = $pY;

				# switch direction
				if ( $f->{"type"} eq "A" ) {

					$f->{"newDir"} = $f->{"newDir"} eq EnumsRout->Dir_CW ? EnumsRout->Dir_CCW : EnumsRout->Dir_CW;
				}
			}
		}
		
		
		my @tranZones = ();

		foreach my $feat ( grep { defined $_->{"att"}->{Enums->BendArea_TRANZONEATT} } @feats ) {

			my $tZone = TransitionZone->new($feat);

			push( @tranZones, $tZone );

		}

		my $bendArea = BendArea->new( \@feats, \@tranZones );

		push( @{ $self->{"bendAreas"} }, $bendArea );

	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAMJob::FlexiLayers::BendAreaParser::BendAreaParser';
	use aliased 'Packages::InCAM::InCAM';

	my $jobId = "d113609";
	my $inCAM = InCAM->new();

	my $step  = "o+1";
	my $layer = "s";

	my $parser = BendAreaParser->new( $inCAM, $jobId, $step, );

	$parser->LoadBendArea();

	my $errMess = "";

	unless ( $parser->CheckBendArea( \$errMess ) ) {

		print $errMess;

	}
}

1;

