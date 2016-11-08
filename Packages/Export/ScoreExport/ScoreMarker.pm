
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for AOI files creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::ScoreExport::ScoreMarker;

#3th party library
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamAttributes';
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::Polygon::Features::ScoreFeatures::ScoreFeatures';
use aliased 'Packages::Scoring::ScoreChecker::Enums' => "ScoEnums";

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class = shift;

	my $self = {};
	bless $self;

	$self->{"inCAM"}        = shift;
	$self->{"jobId"}        = shift;
	$self->{"scoreChecker"} = shift;
	$self->{"frLim"}        = shift;
	
	$self->{"step"}        = "panel";

	#define length of control line

	if ( $self->{"frLim"} ) {

		$self->{"lenV"} = 15;
		$self->{"lenH"} = 20;
	}
	else {

		$self->{"lenV"} = 14;
		$self->{"lenH"} = 14;
	}

	# define limits of panel

	# get information about panel dimension
	my %lim = CamJob->GetProfileLimits( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"} );

	$self->{"xMin"} = 0;
	$self->{"xMax"} = abs( $lim{"xmax"} - $lim{"xmin"} );
	$self->{"yMin"} = 0;
	$self->{"yMax"} = abs( $lim{"ymax"} - $lim{"ymin"} );

	if ( $self->{"frLim"} ) {

		$self->{"width"}  = abs( $self->{"frLim"}->{"xMax"} - $self->{"frLim"}->{"xMin"} );
		$self->{"height"} = abs( $self->{"frLim"}->{"yMax"} - $self->{"frLim"}->{"yMin"} );

		$self->{"xMin"} = $self->{"frLim"}->{"xMin"};
		$self->{"xMax"} = $self->{"frLim"}->{"xMax"};
		$self->{"yMin"} = $self->{"frLim"}->{"yMin"};
		$self->{"yMax"} = $self->{"frLim"}->{"yMax"};
	}

	return $self;
}

sub Run {
	my $self = shift;

	my @points = $self->__GetPoints();
	$self->__DrawPoints( \@points );

}

sub __DrawPoints {
	my $self   = shift;
	my @points = @{ shift(@_) };
	my $inCAM  = $self->{"inCAM"};
	my $jobId  = $self->{"jobId"};

	# Create layer for liones, set attribute
	my $lName = GeneralHelper->GetGUID();

	$inCAM->COM( 'create_layer', "layer" => $lName, "context" => 'misc', "type" => 'document', "polarity" => 'positive', "ins_layer" => '' );
	CamLayer->WorkLayer( $inCAM, $lName );

	foreach my $point (@points) {

		my %startP = %{ $point->{"point"} };
		my %endP;

		if ( $point->{"dir"} eq ScoEnums->Dir_HSCORE ) {

			$endP{"x"} = $startP{"x"} + $self->{"lenH"};
			$endP{"y"} = $startP{"y"};

		}
		elsif ( $point->{"dir"} eq ScoEnums->Dir_VSCORE ) {

			$endP{"x"} = $startP{"x"};
			$endP{"y"} = $startP{"y"} - $self->{"lenV"};
		}

		$inCAM->COM(
					 'add_line',
					 attributes => 'no',
					 xs         => $startP{"x"},
					 ys         => $startP{"y"},
					 xe         => $endP{"x"},
					 ye         => $endP{"y"},
					 "symbol"   => "r300"
		);

	}

	CamAttributes->SetFeatuesAttribute( $inCAM, ".string", "score_control_line" );

	#copy to other layer
	# merge layer to final output layer
	my @layers = ( "mc", "c", "s", "ms" );

	foreach my $l (@layers) {

		if ( CamHelper->LayerExists( $inCAM, $jobId, $l ) ) {

			$inCAM->COM( "merge_layers", "source_layer" => $lName, "dest_layer" => $l );
		}
	}

	# Delete

	# delete rout temporary layer
	if ( CamHelper->LayerExists( $inCAM, $jobId, $lName ) ) {

		$inCAM->COM( 'delete_layer', "layer" => $lName );
	}
}

sub __GetPoints {
	my $self = shift;

	my $pcbPlace = $self->{"scoreChecker"}->GetPcbPlace();

	my @points = ();

	# horizontal mark lines
	my @hPos = $pcbPlace->GetScorePos( ScoEnums->Dir_HSCORE );

	foreach my $posInf (@hPos) {

		my %pointVL = { "x" => $self->{"xMin"}, "y" => $posInf->GetPosition() };
		my %pointVR = { "x" => $self->{"xMax"} - $self->{"lenH"}, "y" => $posInf->GetPosition() };

		my %pointL = ( "dir" => ScoEnums->Dir_HSCORE, "point" => \%pointVL );
		my %pointR = ( "dir" => ScoEnums->Dir_HSCORE, "point" => \%pointVR );

		push( @points, \%pointL );
		push( @points, \%pointR );
	}

	# vertical mark lines
	my @VPos = $pcbPlace->GetScorePos( ScoEnums->Dir_VSCORE );

	foreach my $posInf (@VPos) {

		my %pointVT = { "x" => $posInf->GetPosition(), "y" => $self->{"yMax"} };
		my %pointVB = { "x" => $posInf->GetPosition(), "y" => $self->{"yMin"} + $self->{"lenV"} };

		my %pointT = ( "dir" => ScoEnums->Dir_VSCORE, "point" => \%pointVT );
		my %pointB = ( "dir" => ScoEnums->Dir_VSCORE, "point" => \%pointVB );

		push( @points, \%pointT);
		push( @points, \%pointB);
	}

	return @points;

}

sub Cre {
	my $self          = shift;
	my $optimizeLName = shift;
	my $errMess       = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $checkSucc = 1;
	$$errMess .= "Errors during optimization, see 'score_layer':\n";

	my $step = "panel";

	# parse original layer
	CamHelper->SetStep( $inCAM, $step );

	my $layerOri = GeneralHelper->GetGUID();

	$inCAM->COM( 'flatten_layer', "source_layer" => "score", "target_layer" => $layerOri );

	my $hCountOri  = 0;
	my $vCountOri  = 0;
	my $errMessOri = "";
	$self->__GetScore( $step, $layerOri, \$hCountOri, \$vCountOri, \$errMessOri );

	my $hCountOpt  = 0;
	my $vCountOpt  = 0;
	my $errMessOpt = "";
	my $res        = $self->__GetScore( $step, $optimizeLName, \$hCountOpt, \$vCountOpt, \$errMessOpt );

	# result
	unless ($res) {

		$$errMess .= $errMessOpt . "\n";
		$checkSucc = 0;
	}

	if ( $hCountOri != $hCountOpt ) {

		$$errMess .= "Optimization fail. Some horizontal lines are missing/ excess/ not straight. See: score_layer";
		$checkSucc = 0;
	}

	if ( $vCountOri != $vCountOpt ) {

		$$errMess .= "Optimization fail. Some verticall lines are missing/ excess/ not straight. See: score_layer";
		$checkSucc = 0;
	}

	# delete helper layer

	if ( CamHelper->LayerExists( $inCAM, $jobId, $layerOri ) ) {
		$inCAM->COM( 'delete_layer', "layer" => $layerOri );
	}

	return $checkSucc;

}

sub __GetScore {
	my $self    = shift;
	my $step    = shift;
	my $layer   = shift;
	my $hCount  = shift;
	my $vCount  = shift;
	my $errMess = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $checkSucc = 1;

	CamLayer->WorkLayer( $inCAM, $layer );

	my $score = ScoreFeatures->new(1);
	$score->Parse( $inCAM, $jobId, $step, $layer );

	unless ( $score->IsStraight() ) {
		$$errMess .= "Score is not strictly horizontal or vertical.";
		$checkSucc = 0;
	}

	if ( $score->ExistOverlap() ) {
		$$errMess .= "Some scorelines  are overlapping.";
		$checkSucc = 0;
	}

	my @feats = $score->GetFeatures();

	# H
	my @h       = grep { $_->{"direction"} eq "horizontal" } @feats;
	my @hMerged = ();
	my $hCnt    = 0;
	foreach my $f (@h) {

		# merge lines, which has spacinf less than 100µm
		my $exist = scalar( grep { abs( $_->{"y1"} - $f->{"y1"} ) < $self->{"accuracy"} } @hMerged );

		unless ($exist) {
			push( @hMerged, $f );

		}
	}

	#V
	my @v       = grep { $_->{"direction"} eq "vertical" } @feats;
	my @vMerged = ();
	my $vCnt    = 0;

	foreach my $f (@v) {

		# merge lines, which has spacinf less than 100µm
		my $exist = scalar( grep { abs( $_->{"x1"} - $f->{"x1"} ) < $self->{"accuracy"} } @vMerged );

		unless ($exist) {
			push( @vMerged, $f );
		}
	}
	$$hCount = scalar(@hMerged);
	$$vCount = scalar(@vMerged);

	return $checkSucc;

}

sub CreateLayer {
	my $self      = shift;
	my $scoreData = shift;
	my $lName     = shift;    # name of layer, which contain final score data

	my $step = "panel";

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	#my %lim   = CamJob->GetProfileLimits( $inCAM, $jobId, $step );
	#my $stepW = abs( $lim{"xmax"} - $lim{"xmin"} );
	#my $stepH = abs( $lim{"ymax"} - $lim{"ymin"} );

	CamHelper->SetStep( $inCAM, $step );

	# Create layer
	if ( CamHelper->LayerExists( $inCAM, $jobId, $lName ) ) {
		$inCAM->COM( 'delete_layer', "layer" => $lName );
	}

	$inCAM->COM( 'create_layer', "layer" => $lName, "context" => 'misc', "type" => 'document', "polarity" => 'positive', "ins_layer" => '' );

	CamLayer->WorkLayer( $inCAM, $lName );

	my @sets = $scoreData->GetSets();

	foreach my $set (@sets) {

		my @lines = $set->GetLines();

		foreach my $line (@lines) {

			$inCAM->COM(
						 'add_line',
						 attributes => 'no',
						 xs         => $line->GetStartP()->{"x"} / 1000,
						 ys         => $line->GetStartP()->{"y"} / 1000,
						 xe         => $line->GetEndP()->{"x"} / 1000,
						 ye         => $line->GetEndP()->{"y"} / 1000,
						 "symbol"   => "r400"
			);

			my $x   = 0;
			my $y   = 0;
			my $sym = 0;
			if ( $set->GetDirection() eq ScoEnums->Dir_HSCORE ) {

				$x   = 10000;
				$y   = $line->GetStartP()->{"y"};
				$sym = 1000;
			}
			elsif ( $set->GetDirection() eq ScoEnums->Dir_VSCORE ) {

				$x   = $line->GetStartP()->{"x"};
				$y   = 10000;
				$sym = 2000;
			}

			$inCAM->COM(
						 "add_pad",
						 "attributes" => 'no',
						 "x"          => $x / 1000,
						 "y"          => $y / 1000,
						 "symbol"     => "r" . $sym
			);
		}

	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Packages::Export::PlotExport::PlotMngr';
	#
	#	use aliased 'Packages::InCAM::InCAM';
	#
	#	my $inCAM = InCAM->new();
	#
	#	my $jobId = "f13609";
	#
	#	my @layers = CamJob->GetBoardBaseLayers( $inCAM, $jobId );
	#
	#	foreach my $l (@layers) {
	#
	#		$l->{"polarity"} = "positive";
	#
	#		if ( $l->{"gROWname"} =~ /pc/ ) {
	#			$l->{"polarity"} = "negative";
	#		}
	#
	#		$l->{"mirror"} = 0;
	#		if ( $l->{"gROWname"} =~ /c/ ) {
	#			$l->{"mirror"} = 1;
	#		}
	#
	#		$l->{"compensation"} = 30;
	#		$l->{"name"}         = $l->{"gROWname"};
	#	}
	#
	#	@layers = grep { $_->{"name"} =~ /p[cs]/ } @layers;
	#
	#	my $mngr = PlotMngr->new( $inCAM, $jobId, \@layers );
	#	$mngr->Run();
}

1;

