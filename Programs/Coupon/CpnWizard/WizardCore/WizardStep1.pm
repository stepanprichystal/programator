
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnWizard::WizardCore::WizardStep1;
use base('Programs::Coupon::CpnWizard::WizardCore::WizardStepBase');

use Class::Interface;
&implements('Programs::Coupon::CpnWizard::WizardCore::IWizardStep');

#3th party library
use strict;
use warnings;

#local library

use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::Coupon::CpnWizard::WizardCore::WizardStep2';
use aliased 'Programs::Coupon::CpnSettings::CpnSettings';
use aliased 'Programs::Coupon::CpnSource::CpnSource';
use aliased 'Programs::Coupon::CpnWizard::WizardCore::Helper';
use aliased 'Programs::Coupon::CpnPolicy::GroupPolicy';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self = $class->SUPER::new( 1, @_ );
	bless $self;

	# data model for step class
	$self->{"filter"}     = undef;
	$self->{"userGroups"} = undef;
	$self->{"groupComb"}  = undef;
	$self->{"cpnSett"}    = undef;

	$self->{"constrGroup"} = undef;

	return $self;
}

sub Init {
	my $self = shift;

	$self->{"cpnSett"} = CpnSettings->new();

	# Generate default group combination

	my $cpnVariant = Helper->GetBestGroupCombination( $self->{"cpnSource"}, $self->{"filter"}, $self->{"cpnSett"} );

	# Get groups from cpn variant
	my $defGroupComb = [];

	#	my @allConstr = $self->{"cpnSource"}->GetConstraints();
	#
	#	push(@{$defGroupComb},  \@allConstr);

	foreach my $singlCpn ( $cpnVariant->GetSingleCpns() ) {

		my @xmlConstr = map { $_->Data()->{"xmlConstraint"} } $singlCpn->GetAllStrips();
		push( @{$defGroupComb}, \@xmlConstr );
	}

	my $groupPolicy = GroupPolicy->new( $self->{"cpnSource"}, $self->{"cpnSett"}->GetMaxTrackCnt() );

	$self->{"groupComb"} = $groupPolicy->GenerateGroupComb($defGroupComb);

	for ( my $i = 0 ; $i < scalar( @{ $self->{"groupComb"} } ) ; $i++ ) {

		foreach my $s ( @{ $self->{"groupComb"}->[$i] } ) {

			$self->{"constrGroup"}->{$s->{"id"}} = $i + 1;
		}
	}

	# Init default groups for all constraint

}

sub Build {
	my $self    = shift;
	my $errMess = shift;

	my $result = 1;

	#get group combination variants by user settings

	if ( defined $self->{"groupComb"} ) {

		$self->{"nextStep"} = WizardStep2->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"cpnSource"} );
		$self->{"nextStep"}->Init( $self->{"groupComb"}, $self->{"constrGroup"}, $self->{"filter"}, $self->{"cpnSett"} );

	}
	else {
		$result = 0;
	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
# Update method - update wizard step data model
#-------------------------------------------------------------------------------------------#
sub UpdateGroupFilter {
	my $self   = shift;
	my $filter = shift;

	$self->{"filter"} = $filter;
}

sub UpdateUserGroups {
	my $self       = shift;
	my $userGroups = shift;

	$self->{"userGroups"} = $userGroups;

	my $groupPolicy = GroupPolicy->new( $self->{"cpnSource"}, $self->{"cpnSett"}->GetMaxTrackCnt() );

	$self->{"groupComb"} = $groupPolicy->GenerateGroupComb( $self->{"userGroups"} );

}

#-------------------------------------------------------------------------------------------#
# Get data from model -
#-------------------------------------------------------------------------------------------#

sub GetConstraints {
	my $self = shift;

	return $self->{"cpnSource"}->GetConstraints();

}

sub GetConstrGroup {
	my $self = shift;

	return $self->{"constrGroup"};

}

#sub UpdateGlobalSettings {
#	my $self    = shift;
#	my $cpnSett = shift;
#
#	$self->{"cpnSett"} = $cpnSett;
#}

#sub UpdateData {
#	my $self         = shift;
#	my $filter       = shift // [];
#	my $userComb     = shift;
#	my $userGlobSett = shift;
#
#	my $cpnSett = CpnSettings->new();
#
#	if ( defined $userGlobSett ) {
#
#		$cpnSett = $userGlobSett;
#
#		# update settings
#	}
#
#	my $cpnVariant = Helper->GetBestGroupCombination( $self->{"cpnSource"}, $filter, $cpnSett );
#
#	return $cpnVariant;
#}

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

