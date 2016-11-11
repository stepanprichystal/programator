
#-------------------------------------------------------------------------------------------#
# Description: Optimize score data for scoring machine
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Scoring::ScoreOptimize::ScoreOptimize;

#3th party library
use strict;
use warnings;
use Math::Trig;

#local library
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

	$self->{"helper"} = Helper->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"scoreChecker"}->GetAccuracy() );
	$self->{"optimizator"} = Optimizator->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"scoreChecker"} );

	$self->{"finalLayer"} = "score_layer";    # layer name, which contain control optimized score lines

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

# return, structure (type of ScoreLayer) which contain optimized score data
sub GetScoreData {
	my $self = shift;

	return $self->{"optimizator"}->GetScoreData();
}

# from optimiyed score layer , create layer in matrix
sub CreateScoreLayer {
	my $self = shift;
	my $mess = shift;

	my $res = $self->{"helper"}->CreateLayer( $self->GetScoreData(), $self->{"finalLayer"} );

	return $res;
}

# check if optimialiyation succeed
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
#
#	use aliased 'Packages::Scoring::ScoreChecker::ScoreChecker';
#	use aliased 'Packages::InCAM::InCAM';
#
#	my $jobId = "f52456";
#
#	my $inCAM = InCAM->new();
#
#	my $checker = ScoreChecker->new( $inCAM, $jobId, "panel" );
#
#	print 1;

}

1;

