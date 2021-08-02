#-------------------------------------------------------------------------------------------#
# Description: Stackup checks
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::StackupCheck;

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);
use List::Util qw(first);

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamCopperArea';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';
use aliased 'Packages::Stackup::Stackup::Stackup';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

use constant USAGE_OK       => "usage_ok";          # no need to change stackup usage
use constant USAGE_OK_EMPTY => "usage_empty";       # layer is phzsicaly empty (except fiducial marks in panel frame)
use constant USAGE_INCREASE => "usage_increase";    # usage in copper layers has increased
use constant USAGE_DECREASE => "usage_decraase";    # usage in copper layers has decreased
use constant USAGETOL       => 2;                   #tolerance +-1 %

# Check if usage in multical/instack stackups is in tolerance with real usage in layers
# Restul data - array of items:
# - layer: inner layer name
# - realUsage: usage computed from panel
# - stackupUsage: usage stored in stackup multical/instack
# - status: USAGE_OK/USAGE_OK_EMPTY/USAGE_INCREASE/USAGE_DECREASE
sub CuUsageCheck {
	my $self       = shift;
	my $inCAM      = shift;
	my $jobId      = shift;
	my $resultData = shift // [];

	my $result = 1;

	my $stackup = Stackup->new( $inCAM, $jobId, 1 );

	my $pcbThick     = $stackup->GetFinalThick();
	my $outerCuThick = $stackup->GetCuLayer("c")->GetThick();

	my @sigInner = CamJob->GetSignalLayerNames( $inCAM, $jobId, 1 );

	my @innerCuUsage = ();

	foreach my $l (@sigInner) {

		my %area = ();
		my ($num) = $l =~ m/^v(\d+)$/;

		if ( $num % 2 == 0 ) {

			%area = CamCopperArea->GetCuArea( $outerCuThick, $pcbThick, $inCAM, $jobId, "panel", $l, undef );
		}
		else {
			%area = CamCopperArea->GetCuArea( $outerCuThick, $pcbThick, $inCAM, $jobId, "panel", undef, $l );
		}

		# Round to integer
		my $stackupUsage = sprintf( "%.0f", $stackup->GetCuLayer($l)->GetUssage() * 100 );
		my $realUsage    = sprintf( "%.0f", $area{"percentage"} );
		my $status = $self->__UsageStatus( $realUsage, $stackupUsage );
		push( @innerCuUsage, { "layer" => $l, "realUsage" => $realUsage, "stackupUsage" => $stackupUsage, "status" => $status } );
	}


	foreach my $item  (@innerCuUsage){
		push(@{$resultData}, $item);
	}
 
	my @errUsage = grep { $_->{"status"} eq USAGE_INCREASE || $_->{"status"} eq USAGE_DECREASE } @innerCuUsage;

	return scalar(@errUsage) > 0 ? 0 : 1;
}

# Return:
# - usage_ok = no need to change stackup usage
# - usage_increase
# - usage_decraase

sub __UsageStatus {
	my $self         = shift;
	my $layerUsage   = shift;
	my $stackupUsage = shift;

	# Consider it as empty layer
	return USAGE_OK_EMPTY if ( $stackupUsage == 0 );

	my $result = USAGE_OK;

	if ( $layerUsage - $stackupUsage > USAGETOL ) {

		$result = USAGE_INCREASE;
	}
	elsif ( $stackupUsage - $layerUsage > USAGETOL ) {

		$result = USAGE_DECREASE;
	}

	return $result;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use Data::Dump qw(dump);
	#
	use aliased 'Packages::CAMJob::Stackup::StackupCheck';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d276231";

	my $mess = "";

	my $usedSch = "";

	my $result = SchemeCheck->ProducPanelSchemeOk( $inCAM, $jobId, \$usedSch );

	print STDERR "Result is: $result, schema is: $usedSch\n";

}

1;
