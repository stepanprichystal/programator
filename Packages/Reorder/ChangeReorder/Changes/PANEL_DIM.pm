#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::ChangeReorder::Changes::PANEL_DIM;
use base('Packages::Reorder::ChangeReorder::Changes::ChangeBase');

use Class::Interface;
&implements('Packages::Reorder::ChangeReorder::Changes::IChange');

#3th party library
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
	my $self  = shift;
	my $mess = shift;
	
	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $isPool   = $self->{"isPool"};
	
	# Check only standard orders
	if($isPool){
		return 1;
	}
	
	
	my $stepName = "panel";
	
	my $result = 1;
 
	 # 1) Adjust active area borders to actual
	my $area = ActiveArea->new( $inCAM, $jobId );

	unless ( $area->IsBorderStandard() ) {

		my %b = $area->GetStandardBorder();

		# check if active area will be bigger after change borders
		if ( $area->BorderL() < $b{"bl"} || $area->BorderR() < $b{"br"} || $area->BorderT() < $b{"bt"} || $area->BorderB() < $b{"bb"} ) {

			$$mess .= "Panel doesn't have standard width of active area border. "
			  . "Active area would decrease in case of automatic border change to standard.";
			  
			  $result =  0;
		}
		else {

			CamStep->SetActiveAreaBorder( $inCAM, "panel", $b{"bl"}, $b{"br"}, $b{"bt"}, $b{"bb"});
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
	
	my $inCAM    = InCAM->new();
	my $jobId = "f52457";
	
	my $check = Change->new("key", $inCAM, $jobId);
	
	my $mess = "";
	print "Change result: ".$check->Run(\$mess);
}

1;

