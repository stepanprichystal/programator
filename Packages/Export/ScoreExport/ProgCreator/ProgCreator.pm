
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for AOI files creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::ScoreExport::ProgCreator::ProgCreator;

#3th party library
use strict;
use warnings;

#local library
#use aliased 'Enums::EnumsGeneral';
#
#use aliased 'Packages::Scoring::ScoreChecker::ScoreChecker';
#use aliased 'Packages::Scoring::ScoreOptimize::ScoreOptimize';
#
#use aliased 'Packages::Export::ScoreExport::Enums';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamHooks';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::Export::ScoreExport::ProgCreator::ProgBuilder';
use aliased 'Packages::Scoring::ScoreChecker::Enums' => "ScoEnums";

use aliased 'Packages::Scoring::ScoreOptimize::ScoreLayer::ScoreLine';
use aliased 'Packages::Scoring::ScoreOptimize::ScoreLayer::ScoreSet';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $self = {};
	bless $self;

	$self->{"inCAM"}     = shift;
	$self->{"jobId"}     = shift;
	$self->{"coreThick"} = shift;
	$self->{"frLim"} = shift;
	$self->{"step"} = "panel";

	$self->{"pcbThick"} = JobHelper->GetFinalPcbThick( $self->{"jobId"} ) / 1000;

	# get information about panel dimension
	my %lim = CamJob->GetProfileLimits( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"} );

	$self->{"width"}  = abs( $lim{"xmax"} - $lim{"xmin"} );
	$self->{"height"} = abs( $lim{"ymax"} - $lim{"ymin"} );



	return $self;
}

sub Build {
	my $self      = shift;
	my $type      = shift;
	my $scoreData = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	# get coordinate of left bottom olec hole
	my @marks = CamHooks->GetLayerCamMarks( $inCAM, $jobId, $step, "c" );
	my $originVsco =
	  ( grep { $_->{"att"}->{".geometry"} && $_->{"att"}->{".geometry"} =~ /olec/i && $_->{"att"}->{".pnl_place"} =~ /left-bot/i } @marks )[0];
	my $originHsco =
	  ( grep { $_->{"att"}->{".geometry"} && $_->{"att"}->{".geometry"} =~ /olec/i && $_->{"att"}->{".pnl_place"} =~ /right-bot/i } @marks )[0];

	my %originV = ( "x" => $originVsco->{"x1"}, "y" => $originVsco->{"y1"} );
	my %originH = ( "x" => $originHsco->{"x1"}, "y" => $originHsco->{"y1"} );

	# add control lines to sets
	$self->__AddControlLines($scoreData);

	$self->{"scoreFileV"} = $self->__BuildVScore( $type, $scoreData, \%originV );
	$self->{"scoreFileH"} = $self->__BuildHScore( $type, $scoreData, \%originH );

}

sub __BuildVScore {
	my $self      = shift;
	my $type      = shift;
	my $scoreData = shift;
	my $origin    = shift;

	my $dir = ScoEnums->Dir_VSCORE;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	my $str = "";

	my $Vbuilder = ProgBuilder->new( $inCAM, $jobId, $self->{"coreThick"}, $self->{"pcbThick"}, $self->{"width"}, $self->{"height"}, $dir );

	# change origin in score data
	$scoreData->SetNewOrigin($origin);

	my @sets = $scoreData->GetSets($dir);

	$str .= $Vbuilder->BuildHeader();
	$str .= $Vbuilder->BuildBody( $type, \@sets );
	$scoreData->ResetOrigin();

	return $str;
}

sub __BuildHScore {
	my $self      = shift;
	my $type      = shift;
	my $scoreData = shift;
	my $origin    = shift;

	my $dir = ScoEnums->Dir_HSCORE;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	my $str = "";

	my $hBuilder = ProgBuilder->new( $inCAM, $jobId, $self->{"coreThick"}, $self->{"pcbThick"}, $self->{"width"}, $self->{"height"}, $dir );

	# change origin in score data
	$scoreData->SetNewOrigin($origin);

	my @sets = $scoreData->GetSets($dir);

	# we have to "rotate" hotizontal score lines, because panel is rotated by 90 deg on machine
	# then is scored from top to bot like vertical score
	$self->__RotateHSets( \@sets );

	$str .= $hBuilder->BuildHeader();
	$str .= $hBuilder->BuildBody( $type, \@sets );
	$scoreData->ResetOrigin();

	return $str;
}

sub SaveFile {
	my $self = shift;
	my $dir  = shift;

	my $result = 1;

	my $archive = JobHelper->GetJobArchive( $self->{"jobId"} );
	my $fPath   = $archive;

	if ( $dir eq ScoEnums->Dir_VSCORE ) {

		$fPath .= $self->{"jobId"} . "-X.jum";

		if ( -e $fPath ) {
			unlink($fPath);
		}

		my $f;
		if ( open( $f, ">", $fPath ) ) {
			print $f $self->{"scoreFileV"};
			close($f);
		}

	}
	elsif ( $dir eq ScoEnums->Dir_HSCORE ) {

		$fPath .= $self->{"jobId"} . "-Y.jum";

		if ( -e $fPath ) {
			unlink($fPath);
		}

		my $f;
		if ( open( $f, ">", $fPath ) ) {
			print $f $self->{"scoreFileH"};
			close($f);
		}
	}

	unless ( -e $fPath ) {

		$result = 0;
	}

	return $result;

}

sub __RotateHSets {
	my $self = shift;
	my $sets = shift;

	foreach my $set ( @{$sets} ) {

		# set set score lines
		foreach my $line ( $set->GetLines() ) {

			my $s = $line->GetStartP();
			my $e = $line->GetEndP();

			my $val = $s->{"x"};
			$s->{"x"} = $s->{"y"};
			$s->{"y"} = -$val;

			my $val2 = $e->{"x"};
			$e->{"x"} = $e->{"y"};
			$e->{"y"} = -$val2;

		}
	}
}

# Add test score lines. One for every direction in technical frame
sub __AddControlLines {
	my $self      = shift;
	my $scoreData = shift;

	my $frLim = $self->{"frLim"};

	if ( $self->{"frLim"} ) {

		foreach my $k ( keys %{$frLim} ) {

			$frLim->{$k} *= 1000;
		}
	}

	my $width  = $self->{"width"} * 1000;
	my $height = $self->{"height"} * 1000;

	# ==================================
	# horizontal score
	# ==================================
	my $hPoint;
	my %hLineS;
	my %hLineE;

	$hPoint = $height - 5000;

	$hLineS{"x"} = - 2000; # start out of pcb 2mm
	$hLineS{"y"} = $height - 5000;
	$hLineE{"x"} = 5000 + 40000;
	$hLineE{"y"} = $height - 5000;

	# multi VV
	if ($frLim) {

		$hPoint -= $height - $frLim->{"yMax"};

		$hLineS{"x"} += $frLim->{"xMin"};
		$hLineS{"y"} -= $height - $frLim->{"yMax"};
		$hLineE{"x"} += $frLim->{"xMin"};
		$hLineE{"y"} -= $height - $frLim->{"yMax"};
	}

	# horizontal line

	my $hScoreSet = ScoreSet->new( $hPoint, ScoEnums->Dir_HSCORE );
	my $hline = ScoreLine->new( ScoEnums->Dir_HSCORE );
	$hline->SetStartP( \%hLineS );
	$hline->SetEndP( \%hLineE );
	$hScoreSet->AddScoreLine($hline);

	$scoreData->AddScoreSet($hScoreSet);

	# ==================================
	# vertical score
	# ==================================
	my $vPoint;
	my %vLineS;
	my %vLineE;

	$vPoint = $width - 5000;

	$vLineS{"x"} = $width - 5000;
	$vLineS{"y"} = $height + 2000; # start out of pcb 2mm;
	$vLineE{"x"} = $width - 5000;
	$vLineE{"y"} = $height - 5000 - 40000;

	# multi VV
	if ($frLim) {

		$vPoint -= $width - $frLim->{"xMax"};

		$vLineS{"x"} -= $width - $frLim->{"xMax"};
		$vLineS{"y"} -= $height - $frLim->{"yMax"};
		$vLineE{"x"} -= $width - $frLim->{"xMax"};
		$vLineE{"y"} -= $height - $frLim->{"yMax"};
	}

	# horizontal line

	my $vScoreSet = ScoreSet->new( $vPoint, ScoEnums->Dir_VSCORE );
	my $vline = ScoreLine->new( ScoEnums->Dir_VSCORE );
	$vline->SetStartP( \%vLineS );
	$vline->SetEndP( \%vLineE );
	$vScoreSet->AddScoreLine($vline);

	$scoreData->AddScoreSet($vScoreSet);

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

