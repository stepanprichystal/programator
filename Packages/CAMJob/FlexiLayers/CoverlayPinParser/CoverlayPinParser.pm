
#-------------------------------------------------------------------------------------------#
# Description: Parse "bend area" layer for rigid flex pcb
# - BendArea class contain closed polygon features, which has always CCW direction
# - Features in "BendArea" not match with original layer features. (feat id can
#   be different, arcs can be aproxiamted)
# - Transition zone feature is oriented as well CCW, thus pcb rigid part of
#   is always on right
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::FlexiLayers::CoverlayPinParser::CoverlayPinParser;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Polygon::Features::PolyLineFeatures::PolyLineFeatures';
use aliased 'Packages::CAMJob::FlexiLayers::CoverlayPinParser::PinBendArea';
use aliased 'Packages::CAMJob::FlexiLayers::BendAreaParser::TransitionZone';
use aliased 'Packages::Polygon::Polygon::PolygonPoints';
use aliased 'Packages::Polygon::Enums' => 'PolyEnums';
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamFilter';
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
use aliased 'Packages::CAM::FeatureFilter::Enums' => 'EnumsFiltr';
use aliased 'Enums::EnumsRout';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

my $REGISTERPINSTRING = "register_pin";
my $CUTPINSTRING      = "cut_pin";
my $ENDPINLINE        = "end_pin_line";
my $PINLINE           = "pin_line";

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}          = shift;
	$self->{"jobId"}          = shift;
	$self->{"step"}           = shift;
	$self->{"bendAreaDir"}    = shift // PolyEnums->Dir_CCW;    # Packages::Polygon::Enums::Dir_<CW|CCW>
	$self->{"resizeBendArea"} = shift // 0;                     # Resize polygon feature of bend area
	$self->{"layer"}          = shift // "coverlaypins";

	# PROPERTIES

	$self->{"pinBendAreas"}   = [];
	$self->{"helperFeatures"} = [];

	$self->__LoadBendArea();

	return $self;
}

sub CheckBendArea {
	my $self    = shift;
	my $errMess = shift;

	my $result = 1;

	# Check if all efatures has filled .string attribute

	my @wrong = grep { !defined $_->{"att"}->{".string"} || $_->{"att"}->{".string"} eq "" } $self->GetFeatures();

	if (@wrong) {

		$result = 0;
		$errMess .=
		  "Not all features in layer: " . $self->{"layer"} . " has attribute .string (features id: " . join( ";", map { $_->{"id"} } @wrong ) . ")";
	}

	return $result;

}

sub GetFeatures {
	my $self = shift;

	my @f = map { $_->GetFeatures() } @{ $self->{"pinBendAreas"} };
	push( @f, @{ $self->{"helperFeatures"} } );

	return @f;
}

sub GetBendAreas {
	my $self = shift;

	return @{ $self->{"pinBendAreas"} };
}

sub GetBendAreaByLineId {
	my $self   = shift;
	my $lineId = shift;

	my $b;

	foreach my $area ( @{ $self->{"pinBendAreas"} } ) {

		if ( grep { $_->{"id"} eq $lineId } $area->GetFeatures() ) {
			$b = $area;
			last;
		}
	}

	return $b;
}

sub GetBendAreaLineByLineId {
	my $self   = shift;
	my $lineId = shift;

	foreach my $area ( @{ $self->{"pinBendAreas"} } ) {

		my $line = ( grep { $_->{"id"} eq $lineId } $area->GetFeatures() )[0];
		return $line if ($line);
	}
}

sub GetRegisterPads {
	my $self = shift;

	return grep { $_->{"att"}->{".string"} eq $REGISTERPINSTRING } @{ $self->{"helperFeatures"} };
}

sub GetCutLines {
	my $self = shift;

	return grep { $_->{"att"}->{".string"} eq $CUTPINSTRING } @{ $self->{"helperFeatures"} };
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
		my $f = FeatureFilter->new( $inCAM, $jobId, $tmp );

		$f->AddIncludeAtt( ".string", $ENDPINLINE );
		$f->AddIncludeAtt( ".string", $PINLINE );
		$f->SetIncludeAttrCond( EnumsFiltr->Logic_OR );

		if ( $f->Select() ) {
			$inCAM->COM( 'sel_resize_poly', "size" => $self->{"resizeBendArea"} );
			$polyLine->Parse( $inCAM, $jobId, $step, $tmp );
		}
		else {

			die "No line to polygon resize selected";
		}

		CamMatrix->DeleteLayer( $inCAM, $jobId, $tmp );
	}
	else {

		$polyLine->Parse( $inCAM, $jobId, $step, $layer );
	}

	# Separate helper symbol and bend areas
	my @helper = grep { $_->{"att"}->{".string"} eq $CUTPINSTRING || $_->{"att"}->{".string"} eq $REGISTERPINSTRING } $polyLine->GetFeatures();
	$self->{"helperFeatures"} = \@helper;

	my @polyFeats = grep { $_->{"att"}->{".string"} ne $CUTPINSTRING && $_->{"att"}->{".string"} ne $REGISTERPINSTRING } $polyLine->GetFeatures();

	# return parsed feature polygons, cyclic only CW or CCW)
	my @polygons = $polyLine->GetPolygonsFeatures( \@polyFeats );

	# 1) Check if there is detected some polygon area
	die "No bend area detected in step: $step; layer: $layer" if ( !scalar(@polygons) );

	foreach my $polygon (@polygons) {

		my @tranZones = ();

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

					$f->{"newDir"} = $f->{"oriDir"} eq EnumsRout->Dir_CW ? EnumsRout->Dir_CCW : EnumsRout->Dir_CW;
				}
			}
		}

		my $pinBendArea = PinBendArea->new( \@feats, \@tranZones );

		push( @{ $self->{"pinBendAreas"} }, $pinBendArea );
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

