
#-------------------------------------------------------------------------------------------#
# Description: Cover exporting layers as gerber274x
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Scoring::ScoreOptimize::ScoreOptimize;

#3th party library
use strict;
use warnings;
use Math::Trig;

#local library
#use aliased 'Helpers::GeneralHelper';
#use aliased 'Packages::ItemResult::ItemResult';
#use aliased 'Enums::EnumsPaths';
#use aliased 'Helpers::JobHelper';
#use aliased 'Helpers::FileHelper';
#use aliased 'CamHelpers::CamHelper';
#use aliased 'Packages::Export::GerExport::Helper';
#
#use aliased 'CamHelpers::CamJob';
#use aliased 'CamHelpers::CamStepRepeat';
#use aliased 'Packages::Polygon::Features::ScoreFeatures::ScoreFeatures';

#use aliased 'Packages::Scoring::ScoreChecker::Enums';
#use aliased 'Packages::Scoring::ScoreChecker::InfoClasses::ScoreInfo';
#use aliased 'Packages::Scoring::ScoreChecker::PcbPlace';
#use aliased 'Packages::Scoring::ScoreChecker::OriginConvert';

use aliased 'Packages::Scoring::ScoreOptimize::Optimizator';
use aliased 'Packages::Scoring::ScoreOptimize::Helper';

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

	$self->{"helper"} = Helper->new( $self->{"inCAM"}, $self->{"jobId"} );
	$self->{"optimizator"} = Optimizator->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"scoreChecker"} );


	$self->{"finalLayer"} = "score_layer";    # layer which contain control optimiyed score

	return $self;
}

sub Init {
	my $self = shift;
}

sub Run {
	my $self     = shift;
	my $optimize = shift;

	$self->{"optimizator"}->Run($optimize);
}

sub GetScoreData {
	my $self = shift;

	return $self->{"optimizator"}->GetScoreData();
}

sub CreateScoreLayer {
	my $self = shift;
	my $mess = shift;

	my $res = $self->{"helper"}->CreateLayer( $self->GetScoreData(), $self->{"finalLayer"} );

	return $res;
}

sub ReCheck {
	my $self = shift;
	my $mess = shift;

	my $res = $self->{"helper"}->ReCheck( $self->{"finalLayer"}, $mess );

	return $res;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Scoring::ScoreChecker::ScoreChecker';
	use aliased 'Packages::InCAM::InCAM';

	my $jobId = "f52456";

	my $inCAM = InCAM->new();

	my $checker = ScoreChecker->new( $inCAM, $jobId, "panel" );

	print 1;

}

1;

