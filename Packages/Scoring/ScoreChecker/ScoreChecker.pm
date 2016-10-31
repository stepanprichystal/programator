
#-------------------------------------------------------------------------------------------#
# Description: Cover exporting layers as gerber274x
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Scoring::ScoreChecker::ScoreChecker;

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
use aliased 'Packages::Scoring::ScoreChecker::PcbInfo';
use aliased 'Packages::Scoring::ScoreChecker::Enums';
use aliased 'Packages::Scoring::ScoreChecker::ScoreInfo';
use aliased 'Packages::Scoring::ScoreChecker::PcbPlace';

  #-------------------------------------------------------------------------------------------#
  #  Package methods
  #-------------------------------------------------------------------------------------------#

  sub new {

	my $class = shift;

	my $self = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
	$self->{"step"}  = shift;

	 
	$self->{"pcbPlace"} =  PcbPlace->new($self->{"inCAM"}, $self->{"jobId"}, $self->{"step"});
 
	my @hscore = $self->{"pcbPlace"}->GetScorePos(Enums->Dir_HSCORE);
	my @vscore = $self->{"pcbPlace"}->GetScorePos(Enums->Dir_VSCORE);
	
	#GetPcbOnScorePos

	return $self;
}

sub __LoadPcb {
	my $self = shift;

	# get step and repeat, break!

	# if rotated, switch dimension etc

	# for each, parse score if is present

	# save score line to new pcb object

}
 
sub IsJumScoring {
	my $self = shift;

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

