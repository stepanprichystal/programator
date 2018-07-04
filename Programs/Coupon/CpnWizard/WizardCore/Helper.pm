
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnWizard::WizardCore::Helper;

#3th party library
use strict;
use warnings;

#local library

use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::Coupon::CpnSettings::CpnSettings';
use aliased 'Programs::Coupon::CpnSource::CpnSource';
use aliased 'Programs::Coupon::CpnBuilder::BuildParams';
use aliased 'Programs::Coupon::CpnPolicy::GroupPolicy';

use aliased 'Programs::Coupon::CpnPolicy::LayoutPolicy';
use aliased 'Programs::Coupon::CpnPolicy::SortPolicy';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub GetBestGroupCombination {
	my $self      = shift;
	my $cpnSource = shift;
	my $filter    = shift;
	my $cpnSett   = shift;

	my $resultVariant = shift;

	# Return structure => Array of groups combinations
	# Each combination contain groups,
	# Each group contain strips
	my $groupPolicy = GroupPolicy->new( $cpnSource, $cpnSett->GetMaxTrackCnt() );

	# take combination with smallest cnt of groups
	my @groupsComb = $groupPolicy->GenerateGroups($filter);

	# if more than one group
	# take groups combinations with smalelst amoun of group, unitill find the best

	my $combFound = 0;
	while ( !$combFound  && scalar(@groupsComb)  ) {

		my $curGroupCnt  = scalar( @{ $groupsComb[0] } );
		my @curGroupComb = ();

		for ( my $i = scalar(@groupsComb) - 1 ; $i >= 0 ; $i-- ) {

			if ( scalar( @{ $groupsComb[$i] } ) == $curGroupCnt ) {
				push( @curGroupComb, splice @groupsComb, $i, 1 );
			}
		}

		my $variant = $self->GetBestGroupVariant( $cpnSource, \@curGroupComb, $cpnSett );

		# variant was found
		if ( defined $variant ) {
			$resultVariant = $variant;
			$combFound = 1;
		}

		# continue in searching
		elsif ( !defined $variant && scalar(@groupsComb) ) {

			next;

		}

	}

	return $resultVariant;
}

sub GetBestGroupVariant {
	my $self      = shift;
	my $cpnSource = shift;
	my @groupCombs = @{ shift(@_) };
	my $cpnSett   = shift;

	my $cpnVariant = undef;

	# Check if is possible build coupon, if so, get best variant
	my $groupPolicy = GroupPolicy->new( $cpnSource, $cpnSett->GetMaxTrackCnt() );

	# Generate structure => Arraz of group combination
	# Each combination contain groups,
	# Each group contain pools
	# Each pool contain strips
	my @groupsPoolComb = ();

	my $combPools = [];
 
	foreach my $comb (@groupCombs) {

		my $combPools = [];

		if ( $groupPolicy->VerifyGroupComb( $comb, $cpnSett->GetPoolCnt(), $cpnSett->GetMaxStripsCntH(), $combPools ) ) {

			push( @groupsPoolComb, $combPools );
		}
	}

	my @layers = map { $_->{"NAME"} } $cpnSource->GetCopperLayers();

	my $layoutPolicy = LayoutPolicy->new(
										  \@layers,                         $cpnSett->GetPoolCnt(),
										  $cpnSett->GetShareGNDPads(),      $cpnSett->GetMaxTrackCnt(),
										  $cpnSett->GetTrackPadIsolation(), $cpnSett->GetTracePad2GNDPad(),
										  $cpnSett->GetPadTrackSize(),      $cpnSett->GetPadGNDSize(),
										  $cpnSett->GetRouteBetween(),      $cpnSett->GetRouteAbove(),
										  $cpnSett->GetRouteBelow(),        $cpnSett->GetRouteStraight()
	);

	my @variants = ();

	my $idx = 0;

	#my @test = ($groupsPoolComb[0]);
	#@groupsPoolComb = $groupsPoolComb[-1];
	foreach my $comb (@groupsPoolComb) {

		my $cpnVariant = $layoutPolicy->GetStripLayoutVariants($comb);

		if ( defined $cpnVariant ) {
			push( @variants, $cpnVariant );
		}
	}

	if ( scalar(@variants) ) {

		# Sort policy

		my $sortPolicy   = SortPolicy->new();
		my @sortVariants = $sortPolicy->SortVariants( \@variants );

		$cpnVariant = $sortVariants[0];

	}

	return $cpnVariant;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::Stencil::StencilCreator::StencilCreator';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f13609";

	#my $creator = StencilCreator->new( $inCAM, $jobId, Enums->StencilSource_JOB, "f13609" );
	my $creator = StencilCreator->new( $inCAM, $jobId, Enums->StencilSource_CUSTDATA );

	$creator->Run();

}

1;

