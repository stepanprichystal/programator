#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::CheckReorder::Checks::GOLD_CONNECTOR;
use base('Packages::Reorder::CheckReorder::Checks::CheckBase');

use Class::Interface;
&implements('Packages::Reorder::CheckReorder::Checks::ICheck');

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::FileHelper';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamGoldArea';
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

# Determine, if gold layers are preapred in job matrix
sub Run {
	my $self     = shift;
	my $inCAM    = $self->{"inCAM"};
	my $jobId    = $self->{"jobId"};
	my $jobExist = $self->{"jobExist"};    # (in InCAM db)
	my $isPool   = $self->{"isPool"};
	
	# Check only standard orders
	if($isPool){
		return 1;
	}

	my $stepName = "panel";

	# 1) if gold connector exist, check if opfx gold exist
	# if opfx doesn't exist, it means, thera are not prepared "gold layers" in matrix
	my $goldFinger = 0;

	foreach my $l ( ( "c", "s" ) ) {
		if (    CamHelper->LayerExists( $inCAM, $jobId, $l )
			 && CamGoldArea->GoldFingersExist( $inCAM, $jobId, $stepName, $l ) )
		{
			$goldFinger = 1;

			# Check if exist gold finger layers
			unless ( CamHelper->LayerExists( $inCAM, $jobId,"gold" . $l ) ) {
				$self->_AddChange("Vrstva: \"$l\" obsahuje zlacený konektor, ale není vytvořená vrstva: \"gold$l\". Vytvoř ji a vlož znovu schéma ať má vrstva technické okolí.", 1);
			}
		}
	}

	# 2) Test if conductive gold connector connection will be ok
	if ($goldFinger) {

		my $isInside = 1;

		my %limActive = CamStep->GetActiveAreaLim( $inCAM, $jobId, $stepName );
		my %limSR = CamStepRepeat->GetStepAndRepeatLim( $inCAM, $jobId, $stepName );

		if (    $limActive{"xMin"} + 1 > $limSR{"xMin"}
			 || $limActive{"yMax"} - 1 < $limSR{"yMax"}
			 || $limActive{"xMax"} - 1 < $limSR{"xMax"}
			 || $limActive{"yMin"} + 1 > $limSR{"yMin"} )
		{
			$self->_AddChange(   "Job obsahuje zlacený konektor, ale SR stepy jsou umístěny příliš blízko nebo až za aktivní oblastí. "
				  . "Zkontroluj, jestli bude propojení konektorů s ploškou v technickém okolí dostatečně silné (2mm). "
				  . "Pokud ne, změn pozici SR stepu." );

		}
	}
	
	

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Reorder::CheckReorder::Checks::GOLD_CONNECTOR_LAYER' => "Change";
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f60648";

	my $check = Change->new();

	print "Need change: " . $check->NeedChange( $inCAM, $jobId, 1 );
}

1;

