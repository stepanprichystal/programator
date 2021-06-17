#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::ChangeReorder::Changes::PANEL_DIM;
use base('Packages::Reorder::ChangeReorder::Changes::ChangeBase');

use Class::Interface;
&implements('Packages::Reorder::ChangeReorder::Changes::IChange');

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamLayer';
use aliased 'Packages::ProductionPanel::StandardPanel::StandardExt';
use aliased 'Packages::ProductionPanel::StandardPanel::Enums';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Packages::ProductionPanel::ActiveArea::ActiveArea';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Reorder::Enums';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless($self);

	return $self;
}

# Check if mask is not negative in matrix
sub Run {
	my $self    = shift;
	my $errMess = shift;
	my $infMess = shift;

	my $inCAM       = $self->{"inCAM"};
	my $jobId       = $self->{"jobId"};
	my $reorderType = $self->{"reorderType"};

	my $result = 1;

	# Check only standard orders
	if ( $reorderType eq Enums->ReorderType_STD ) {

		my $stepName = "panel";

		# 1) Adjust active area borders to actual
		my $area = ActiveArea->new( $inCAM, $jobId );

		unless ( $area->IsBorderStandard() ) {

			my %b = $area->GetStandardBorder();

			my %areaLimPrev = CamStep->GetActiveAreaLim( $inCAM, $jobId, $stepName );
			my $aWPrev = abs( $areaLimPrev{"xMax"} - $areaLimPrev{"xMin"} );

			my $aHPrev   = abs( $areaLimPrev{"yMax"} - $areaLimPrev{"yMin"} );
			my $areaPrev = $aWPrev * $aHPrev;

			my $area =

			  CamStep->SetActiveAreaBorder( $inCAM, "panel", $b{"bl"}, $b{"br"}, $b{"bt"}, $b{"bb"} );

			# Some panels has decreased active area due to cutting panel from TOP
			# in order put them to smaller machines If area change more than 10% put info message

			use constant MINCHANGE => 10;    # 10%

			my %areaLimCur = CamStep->GetActiveAreaLim( $inCAM, $jobId, $stepName );
			my $aWCur      = abs( $areaLimCur{"xMax"} - $areaLimCur{"xMin"} );
			my $aHCur      = abs( $areaLimCur{"yMax"} - $areaLimCur{"yMin"} );
			my $areaCur    = $aWCur * $aHCur;

			my $change = ( 1 - $areaPrev / $areaCur );
			if ( ( 1 - $areaPrev / $areaCur ) > ( MINCHANGE / 100 ) ) {

				$$infMess .= "Aktivní plocha panelu byla automaticky zvětšena o " . int( $change * 100 ) 
				  . "\%. Zkontroluj jestli se nevleze na panel více stepů";

			}
		}
	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	  use aliased 'Packages::Reorder::ChangeReorder::Changes::MASK_POLAR' => "Change";
	  use aliased 'Packages::InCAM::InCAM';

	  my $inCAM = InCAM->new();
	  my $jobId = "f52457";

	  my $check = Change->new( "key", $inCAM, $jobId );

	  my $mess = "";
	  print "Change result: " . $check->Run( \$mess );
}

1;

