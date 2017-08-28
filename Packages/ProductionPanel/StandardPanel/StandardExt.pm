#-------------------------------------------------------------------------------------------#
# Description: Class contains extended functions working with standard panels like
# comparing standard and actual active area, etc..
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::ProductionPanel::StandardPanel::StandardExt;
use base('Packages::ProductionPanel::StandardPanel::StandardBase');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::ProductionPanel::StandardPanel::Enums';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStep';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::ProductionPanel::StandardPanel::Standard::StandardList';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	$self = $class->SUPER::new(@_);
	bless $self;

}

## If pcb is standard, return if active area is standard too
## Return:
## Type_STANDARDAREA
## Type_SMALLAREA
## Type_BIGAREA
## Type_BIGHAREA
## Type_BIGWAREA
#sub GetStandardAreaDiff {
#	my $self = shift;
#
#	my $isStandard = $self->IsStandard();
#
#	if ( $isStandard eq Enums->Type_NONSTANDARD ) {
#		die "Unable to determine are difference when pcb is not standard panel";
#	}
#	
#	# Get standard
#	my $s =  $self->GetStandard();
#
#	my $result = Enums->Type_STANDARDAREA;
#
#	if ( $isStandard eq Enums->Type_STANDARDNOAREA ) {
#
#		if ( $self->WArea() <= $s->WArea() && $self->HArea() <= $s->HArea() ) {
#
#			$result = Enums->Type_SMALLAREA;
#		}
#		elsif ( $self->WArea() > $s->WArea() && $self->HArea() > $s->HArea() ) {
#
#			$result = Enums->Type_BIGAREA;
#		}
#		elsif ( $self->WArea() <= $s->WArea() && $self->HArea() > $s->HArea() ) {
#
#			$result = Enums->Type_BIGHAREA;
#		}
#		elsif ( $self->WArea() > $s->WArea() && $self->HArea() <= $s->HArea() ) {
#
#			$result = Enums->Type_BIGWAREA;
#		}
#	}
#
#	return $result;
#}

# Return if pcb is smaller then smallest standard (only if pcb is standart candidate)
sub SmallerThanStandard {
	my $self = shift;
	my $standName = shift; # return smalles standard name (key)

	my @standards = ();

	unless ( $self->IsStandardCandidate( \@standards ) ) {
		die "Unable to compare pcb to find out if is smaller than active standards, because pcb is not \"standard candidate\"";
	}

	my $res = 0;

	# take smaller standards
	my $s = $standards[0];
	
	if(defined $standName){
		$$standName = $s->Key();
	}
	

	if ( $self->W() <= $s->W() && $self->H() < $s->H() ||  $self->W() < $s->W() && $self->H() <= $s->H() ) {
		$res = 1;
	}

	return $res;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::ProductionPanel::StandardPanel::StandardExt';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f52457";

	my $pnl = StandardExt->new( $inCAM, $jobId );
	print $pnl->SmallerThanStandard();

	print "fff";

}

1;

