#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::ChangeReorder::Changes::SCORING;
use base('Packages::Reorder::ChangeReorder::Changes::ChangeBase');

use Class::Interface;
&implements('Packages::Reorder::ChangeReorder::Changes::IChange');

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library
use aliased 'Packages::Scoring::ScoreFlatten';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless($self);

	return $self;
}

# Delete and add new schema
sub Run {
	my $self = shift;
	my $mess = shift;

	my $inCAM  = $self->{"inCAM"};
	my $jobId  = $self->{"jobId"};
	my $isPool = $self->{"isPool"};

	# Check only standard orders
	if ($isPool) {
		return 1;
	}

	my $result = 1;

	my $stepName = "mpanel";

	my $sf = ScoreFlatten->new( $inCAM, $jobId, $stepName );

	my @scoreSteps = ();

	# 1) Check if flatten is needed
	if ( $sf->NeedFlatten( \@scoreSteps ) ) {

		# Check if there is jump scoring

		my @scoreStepsJump = ();
		my $jumpScoring    = $sf->JumpScoringExist( \@scoreStepsJump );

		# unless possible jumpscoring, flatten score
		unless ($jumpScoring) {

			$sf->FlattenNestedScore(1);
		}

	}

	return $result;


}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Reorder::ChangeReorder::Changes::SCHEMA' => "Change";
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f52457";

	my $check = Change->new( "key", $inCAM, $jobId );

	my $mess = "";
	print "Change result: " . $check->Run( \$mess );
}

1;

