
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnWizard::WizardCore::Helper;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::Coupon::CpnSettings::CpnSettings';
use aliased 'Programs::Coupon::CpnSettings::CpnSingleSettings';
use aliased 'Programs::Coupon::CpnSettings::CpnStripSettings';

use aliased 'Programs::Coupon::CpnSource::CpnSource';
use aliased 'Programs::Coupon::CpnPolicy::GroupPolicy';
use aliased 'Programs::Coupon::CpnPolicy::GeneratorPolicy';
use aliased 'Programs::Coupon::CpnPolicy::LayoutPolicy';
use aliased 'Programs::Coupon::CpnPolicy::SortPolicy';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub GetBestGroupCombination {
	my $self       = shift;
	my $cpnSource  = shift;
	my $filter     = shift;
	my $defCpnSett = shift;

	my $resultVariant = shift;

	# Return structure => Array of groups combinations
	# Each combination contain groups,
	# Each group contain strips
	my $groupGenPolicy = GeneratorPolicy->new( $cpnSource, $defCpnSett->GetMaxTrackCnt() );

	# take combination with smallest cnt of groups
	my @groupsComb = $groupGenPolicy->GenerateGroups($filter);

	# if more than one group
	# take groups combinations with smalelst amoun of group, unitill find the best

	my $combFound = 0;
	while ( !$combFound && scalar(@groupsComb) ) {

		my $curGroupCnt  = scalar( @{ $groupsComb[0] } );
		my @curGroupComb = ();

		for ( my $i = scalar(@groupsComb) - 1 ; $i >= 0 ; $i-- ) {

			if ( scalar( @{ $groupsComb[$i] } ) == $curGroupCnt ) {
				push( @curGroupComb, splice @groupsComb, $i, 1 );
			}
		}

		# Define group settings for each group
		my $defCpnGroupsSett = {};
		for ( my $i = 0 ; $i < $curGroupCnt ; $i++ ) {

			$defCpnGroupsSett->{$i} = CpnSingleSettings->new();
		}

		# Define strip settings for each strip
		my $defCpnStripSett = {};
		for ( my $i = 0 ; $i < scalar( @{$filter} ) ; $i++ ) {

			$defCpnStripSett->{ $filter->[$i] } = CpnStripSettings->new();
		}

		my $variant = $self->GetBestGroupVariant( $cpnSource, \@curGroupComb, $defCpnSett, $defCpnGroupsSett );

		# variant was found
		if ( defined $variant ) {

			$self->AddSett2CpnVarinat( $variant, $defCpnSett, $defCpnGroupsSett, $defCpnStripSett );

			$resultVariant = $variant;
			$combFound     = 1;
		}

		# continue in searching
		elsif ( !defined $variant && scalar(@groupsComb) ) {

			next;

		}

	}

	return $resultVariant;
}

sub GetBestGroupVariant {
	my $self          = shift;
	my $cpnSource     = shift;
	my @groupCombs    = @{ shift(@_) };
	my $cpnSett       = shift;
	my $cpnGroupsSett = shift;

	my $cpnVariant = undef;

	# Check if is possible build coupon, if so, get best variant
	my $groupPolicy = GroupPolicy->new( $cpnSource, $cpnSett->GetMaxTrackCnt() );

	# global settings
	$groupPolicy->SetGlobalSettings( $cpnSett->GetMaxTrackCnt() );

	# group settings
	foreach my $groupId ( keys %{$cpnGroupsSett} ) {

		$groupPolicy->SetGroupSettings( $groupId, $cpnGroupsSett->{$groupId}->GetPoolCnt(), $cpnGroupsSett->{$groupId}->GetMaxStripsCntH() );
	}

	# Generate structure => Arraz of group combination
	# Each combination contain groups,
	# Each group contain pools
	# Each pool contain strips
	my @groupsPoolComb = ();

	my $combPools = [];

	foreach my $comb (@groupCombs) {

		my $combPools = [];

		if ( $groupPolicy->VerifyGroupComb( $comb, $combPools ) ) {

			push( @groupsPoolComb, $combPools );
		}
	}

	my @layers = map { $_->{"NAME"} } $cpnSource->GetCopperLayers();

	my $layoutPolicy = LayoutPolicy->new( \@layers );

	# global settings
	$layoutPolicy->SetGlobalSettings(
									  $cpnSett->GetMaxTrackCnt(),       $cpnSett->GetShareGNDPads(),
									  $cpnSett->GetTrackPadIsolation(), $cpnSett->GetRouteBetween(),
									  $cpnSett->GetRouteAbove(),        $cpnSett->GetRouteBelow(),
									  $cpnSett->GetRouteStraight()
	);

	# group settings
	foreach my $groupId ( keys %{$cpnGroupsSett} ) {

		$layoutPolicy->SetGroupSettings( $groupId,
										 $cpnGroupsSett->{$groupId}->GetPoolCnt(),
										 $cpnGroupsSett->{$groupId}->GetTrackPad2GNDPad(),
										 $cpnGroupsSett->{$groupId}->GetPadTrackSize(),
										 $cpnGroupsSett->{$groupId}->GetPadGNDSize() )

	}

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

sub AddSett2CpnVarinat {
	my $self             = shift;
	my $variant          = shift;
	my $defCpnSett       = shift;
	my $defCpnGroupsSett = shift;
	my $defCpnStripSett  = shift;

	# set global settings to cpn variant
	$variant->SetCpnSettings($defCpnSett);

	# set ingle cpn settings
	foreach my $singleCpn ( $variant->GetSingleCpns() ) {

		die "Single cpn sdettings is not defined" unless(defined $defCpnGroupsSett->{ $singleCpn->GetOrder() });

		$singleCpn->SetCpnSingleSettings( $defCpnGroupsSett->{ $singleCpn->GetOrder() } );

		foreach my $s ( $singleCpn->GetAllStrips() ) {
			
			die "Strip cpn sdettings is not defined" unless(defined $defCpnStripSett->{ $s->Id() });
			
			$s->SetCpnStripSettings( $defCpnStripSett->{ $s->Id() } );
		}
	}
}

sub GetResourcePath{
	my $self = shift;
	
	return GeneralHelper->Root() . "\\Programs\\Coupon\\CpnWizard\\Resources\\";
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

