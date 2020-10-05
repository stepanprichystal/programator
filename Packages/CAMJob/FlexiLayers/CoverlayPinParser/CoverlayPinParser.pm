
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
use List::MoreUtils qw(uniq);

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
use aliased 'Packages::CAMJob::FlexiLayers::CoverlayPinParser::Enums';
use aliased 'Enums::EnumsRout';
use aliased 'Packages::CAMJob::FlexiLayers::CoverlayPinParser::Pin';

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
	$self->{"layer"}          = shift // "cvrlpins";

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
		$$errMess .=
		  "Not all features in layer: " . $self->{"layer"} . " has attribute .string (features id: " . join( ";", map { $_->{"id"} } @wrong ) . ")";
	}

	return $result;

}

sub GetLayerName {
	my $self = shift;

	return $self->{"layer"};
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

	return grep { $_->{"att"}->{".string"} eq Enums->PinString_REGISTER } @{ $self->{"helperFeatures"} };
}

sub GetCutLines {
	my $self = shift;

	return grep { $_->{"att"}->{".string"} eq Enums->PinString_CUTLINE } @{ $self->{"helperFeatures"} };
}

sub GetSolderLines {
	my $self = shift;

	return grep { $_->{"att"}->{".string"} eq Enums->PinString_SOLDERLINE } @{ $self->{"helperFeatures"} };
}

sub GetEndLines {
	my $self = shift;

	return
	  grep { $_->{"att"}->{".string"} eq Enums->PinString_ENDLINEIN || $_->{"att"}->{".string"} eq Enums->PinString_ENDLINEOUT } $self->GetFeatures();
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

		$f->AddIncludeAtt( ".string", Enums->PinString_ENDLINEIN );
		$f->AddIncludeAtt( ".string", Enums->PinString_ENDLINEOUT );
		$f->AddIncludeAtt( ".string", Enums->PinString_SIDELINE1 );
		$f->AddIncludeAtt( ".string", Enums->PinString_SIDELINE2 );
		$f->AddIncludeAtt( ".string", Enums->PinString_BENDLINE );

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
	my @helper = grep {
		     $_->{"att"}->{".string"} eq Enums->PinString_CUTLINE
		  || $_->{"att"}->{".string"} eq Enums->PinString_SOLDERLINE
		  || $_->{"att"}->{".string"} eq Enums->PinString_REGISTER
	} $polyLine->GetFeatures();
	$self->{"helperFeatures"} = \@helper;

	my @polyFeats = grep {
		     $_->{"att"}->{".string"} ne Enums->PinString_CUTLINE
		  && $_->{"att"}->{".string"} ne Enums->PinString_SOLDERLINE
		  && $_->{"att"}->{".string"} ne Enums->PinString_REGISTER
	} $polyLine->GetFeatures();

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

					$f->{"newDir"} = $f->{"newDir"} eq EnumsRout->Dir_CW ? EnumsRout->Dir_CCW : EnumsRout->Dir_CW;
				}
			}
		}

		# Parse bend area pins
		my @pins = ();

		# Each pin contain at least one of theses attributes
		my @pinsFeats =
		  grep {
			     $_->{"att"}->{".string"} eq Enums->PinString_ENDLINEIN
			  || $_->{"att"}->{".string"} eq Enums->PinString_ENDLINEOUT
			  || $_->{"att"}->{".string"} eq Enums->PinString_REGISTER
		  }

		  grep { defined $_->{"att"}->{"feat_group_id"} } @feats;

		my @pinsFeatsGUID = uniq( map { $_->{"att"}->{"feat_group_id"} } @pinsFeats );

		foreach my $featGroupId (@pinsFeatsGUID) {

			# @feats contains sorted pins line
			my @allPinFeats = (grep { $_->{"att"}->{"feat_group_id"} eq $featGroupId } @helper, @feats);
			my $holderType = Enums->PinHolder_NONE;
			$holderType = Enums->PinHolder_IN if ( scalar( grep { $_->{"att"}->{".string"} eq Enums->PinString_ENDLINEIN } @allPinFeats ) );
			$holderType = Enums->PinHolder_OUT
			  if ( scalar( grep { $_->{"att"}->{".string"} eq Enums->PinString_ENDLINEOUT } @allPinFeats ) );
			my $regPadExist = scalar( grep { $_->{"att"}->{".string"} ne Enums->PinString_REGISTER } @allPinFeats )? 1: 0;
 
			my $pin = Pin->new( $featGroupId, $holderType, $regPadExist, \@allPinFeats );
			push( @pins, $pin );
		}

		my $pinBendArea = PinBendArea->new( \@feats, \@pins );

		push( @{ $self->{"pinBendAreas"} }, $pinBendArea );
	}

	# Pins of type "only Register pad" do not refer to any BendArea, add them to first existing area
	my @pinsAll = grep { $_->{"att"}->{".string"} eq Enums->PinString_REGISTER } @helper;

	my %tmp;
	@tmp{ map { $_->GetPinsGUID() } $self->GetBendAreas() } = ();
	my @regPins = grep { !exists $tmp{ $_->{"att"}->{"feat_group_id"} } } @pinsAll;

	foreach my $regPinFeat (@regPins) {

		my $pin = Pin->new( $regPinFeat->{"att"}->{"feat_group_id"}, Enums->PinHolder_NONE, 1, [$regPinFeat] );
		$self->{"pinBendAreas"}->[0]->AddPin($pin);
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAMJob::FlexiLayers::CoverlayPinParser::CoverlayPinParser';
	use aliased 'Packages::InCAM::InCAM';

	my $jobId = "d266089";
	my $inCAM = InCAM->new();

	my $step  = "o+1";
	my $layer = "s";

	my $parser = CoverlayPinParser->new( $inCAM, $jobId, $step, );

	my $errMess = "";

	unless ( $parser->CheckBendArea( \$errMess ) ) {

		print $errMess;

	}

	my @areas = $parser->GetBendAreas();
	die;

}

1;

