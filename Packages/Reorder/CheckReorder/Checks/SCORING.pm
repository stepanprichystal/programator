#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::CheckReorder::Checks::SCORING;
use base('Packages::Reorder::CheckReorder::Checks::CheckBase');

use Class::Interface;
&implements('Packages::Reorder::CheckReorder::Checks::ICheck');

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

# Check if exist new version of nif, if so it means it is from InCAM
sub Run {
	my $self     = shift;
	
	my $inCAM    = $self->{"inCAM"};
	my $jobId    = $self->{"jobId"};
	my $jobExist = $self->{"jobExist"};    # (in InCAM db)
	my $isPool   = $self->{"isPool"};

	unless($jobExist){
		return 0;
	}

	# 1) Check if score in mpanel is flatenned (no SR steps contain score) 
 
	my $stepName = "mpanel";

	my $sf = ScoreFlatten->new( $inCAM, $jobId, $stepName );

	my @scoreSteps = ();

	# 1) Check if flatten is needed
	if ( $sf->NeedFlatten( \@scoreSteps ) ) {
		
		my $str = join(", ",@scoreSteps);
		
		$self->_AddChange("Step \"mpanel\" obsahuje SR stepy ($str), které obsahují pravděpodobně uživatelský jumpscoring. Přesuň drážku do stepu \"mpanel\" pomocí scriptu \"FlattenScoreScript.pl\"", 1 );
		
	}

 
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Reorder::CheckReorder::Checks::INCAM_JOB' => "Change";
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d10355";

	my $check = Change->new();

	print "Need change: " . $check->NeedChange( $inCAM, $jobId, 1 );
}

1;

