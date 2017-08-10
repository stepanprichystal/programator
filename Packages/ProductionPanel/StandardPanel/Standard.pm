#-------------------------------------------------------------------------------------------#
# Description: Class contains extended functions working with standard panels like
# comparing standard and actual active area, etc..
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::ProductionPanel::StandardPanel::Standard;
use base('Packages::ProductionPanel::StandardPanel::StandardBase');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::ProductionPanel::StandardPanel::Enums';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStep';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::ProductionPanel::StandardPanel::StandardDef';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	$self = $class->SUPER::new(@_);
	bless $self;

}

# If pcb is standard, return if active area is standard too
# Return:
# Type_STANDARDAREA
# Type_SMALLAREA
# Type_BIGAREA
# Type_BIGHAREA
# Type_BIGWAREA
sub GetStandardAreaDiff {
	my $self = shift;

	my $s          = undef;
	my $isStandard = $self->IsStandard($s);

	if ( $isStandard eq Enums->Type_NOSTANDARD ) {
		die "Unable to determine are difference when pcb is not standard panel";
	}

	my $result = Enums->Type_STANDARDAREA;

	if ( $isStandard eq Enums->Type_STANDARDNOAREA ) {

		if ( $self->{"wArea"} < $s->{"wArea"} && $self->{"hArea"} < $s->{"hArea"} ) {
			
			$result = Enums->Type_SMALLAREA;
		}
		elsif ( $self->{"wArea"} > $s->{"wArea"} && $self->{"hArea"} > $s->{"hArea"} ) {

			$result = Enums->Type_BIGAREA;
		}
		elsif ( $self->{"wArea"} < $s->{"wArea"} && $self->{"hArea"} > $s->{"hArea"} ) {
			
			$result = Enums->Type_BIGHAREA;
		}
		elsif ( $self->{"wArea"} > $s->{"wArea"} && $self->{"hArea"} <> $s->{"hArea"} ) {
			
			$result = Enums->Type_BIGWAREA;
		}
	}

	return $result;
}

# Return if pcb is smaller then smallest standard (only if pcb is standart candidate)
sub SmallerThanStandard{
	my $self = shift;
	
	my @standards = ();
	
	unless($self->IsStandardCandidate(\@standards)){
		die "Unable to compare pcb to find out if is smaller than active standards, because pcb is not \"standard candidate\"";
	}
	
	my $res = 0;
	
	# take smaller standards
	my $s = $standards[0];
	
	if(  $self->{"w"} < $s->{"w"} && $self->{"h"} < $s->{"h"} ) { 
		$res = 1;
	}
	
	return $res;
}


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::ProductionPanel::StandardPanel';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f52456";

	print "fff";

}

1;

