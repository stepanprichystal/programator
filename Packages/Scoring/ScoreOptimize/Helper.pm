
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for AOI files creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Scoring::ScoreOptimize::Helper;

#3th party library
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamHelper';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Polygon::Features::ScoreFeatures::ScoreFeatures';
use aliased 'Packages::Scoring::ScoreChecker::Enums' => "ScoEnums";

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class = shift;

	my $self = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
	$self->{"accuracy"} = shift;

	return $self;
}

sub ReCheck {
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
			push(@hMerged, $f);
			 
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
				push(@vMerged, $f);
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

	$inCAM->COM( 'create_layer', "layer" => $lName, "context" => 'board', "type" => 'document', "polarity" => 'positive', "ins_layer" => '' );

	CamLayer->WorkLayer( $inCAM, $lName );

	my @sets = $scoreData->GetSets();

	foreach my $set (@sets) {

		my @lines = $set->GetLines();

		foreach my $line (@lines) {

			$inCAM->COM(
						 'add_line',
						 attributes => 'no',
						 xs         => $line->GetStartP()->{"x"} /1000,
						 ys         => $line->GetStartP()->{"y"}/1000,
						 xe         => $line->GetEndP()->{"x"}/1000,
						 ye         => $line->GetEndP()->{"y"}/1000,
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
						 "x"          => $x/1000,
						 "y"          => $y/1000,
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

