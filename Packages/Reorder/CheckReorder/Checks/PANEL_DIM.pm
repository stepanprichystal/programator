#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::CheckReorder::Checks::PANEL_DIM;
use base('Packages::Reorder::CheckReorder::Checks::CheckBase');

use Class::Interface;
&implements('Packages::Reorder::CheckReorder::Checks::ICheck');

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Helpers::JobHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::ProductionPanel::StandardPanel::StandardExt';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamStepRepeat';

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

	unless ($jobExist) {

		return 0;
	}

	# 1) if job exist, recognize if pcb has standard panel parameters.
	# If so, check if dimenison are smaller than actual smallest standard for given type of pcb and material
	my $pnl = StandardExt->new( $inCAM, $jobId );
	if ( $pnl->IsStandardCandidate() ) {

		my $smallest = "";
		if ( $pnl->SmallerThanStandard( \$smallest ) ) {

			$self->_AddChange(   "Dps má parametry standardu, ale přířez je menší než náš aktuálně nejmenší standard ($smallest). "
							   . "Předělej desku na standard.", 1 );
		}
	}
 
	# 2) This class can change panel dimension (in future). 
	# Do control check if SR step are whole inside active area
 
		my %limActive = CamStep->GetActiveAreaLim( $inCAM, $jobId, "panel" );
		my %limSR = CamStepRepeat->GetStepAndRepeatLim( $inCAM, $jobId, "panel" );

		if (    $limActive{"xMin"}  > $limSR{"xMin"}
			 || $limActive{"yMax"}  < $limSR{"yMax"}
			 || $limActive{"xMax"}  < $limSR{"xMax"}
			 || $limActive{"yMin"}  > $limSR{"yMin"} )
		{
			$self->_AddChange(  "SR stepy jsou umístěny za aktivní oblastí. Zkontroluj, zda technické okolí nezasahuje do desek v panelu." );

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

