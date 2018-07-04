
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnWizard::WizardCore::WizardStep2;
use base('Programs::Coupon::CpnWizard::WizardCore::WizardStepBase');

use Class::Interface;
&implements('Programs::Coupon::CpnWizard::WizardCore::IWizardStep');

#3th party library
use strict;
use warnings;

#local library

use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::Coupon::CpnWizard::WizardCore::WizardStep3';
use aliased 'Programs::Coupon::CpnSettings::CpnSettings';
use aliased 'Programs::Coupon::CpnSource::CpnSource';
use aliased 'Programs::Coupon::CpnWizard::WizardCore::Helper';
use aliased 'Programs::Coupon::CpnPolicy::GroupPolicy';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(2,@_);
	bless $self;

	# data model for step class
	$self->{"groupComb"} = undef;
	$self->{"filter"}    = undef;
	$self->{"cpnSett"}   = undef;

	$self->{"autoGenerate"} = 1;

	return $self;
}

sub Init {
	my $self      = shift;
	my $groupComb = shift;
	my $filter    = shift;
	my $cpnSett   = shift;

	$self->{"groupComb"} = $groupComb;
	$self->{"filter"}    = $filter;
	$self->{"cpnSett"}   = $cpnSett;
	
	@{$self->{"filter"}} = (1,2);

}

sub Build {
	my $self    = shift;
	my $errMess = shift;

	my $result = 1;

	#get group combination variants by user settings

	# 1) build combination structure

	my $cpnVariant = Helper->GetBestGroupVariant( $self->{"cpnSource"}, $self->{"groupComb"}, $self->{"cpnSett"} );

	# generate new groups
	if ( !defined $cpnVariant && $self->{"autoGenerate"} ) {

		$cpnVariant = Helper->GetBestGroupCombination( $self->{"cpnSource"}, $self->{"filter"}, $self->{"cpnSett"} );

	}

	# if cpn variant layout is ok, build is ok
	if ( defined $cpnVariant ) {

		$self->{"nextStep"} = WizardStep3->new( $self->{"inCAM"}, $self->{"jobId"} );

		$self->{"nextStep"}->Init($self->{"cpnVariant"}, $self->{"cpnSett"});

	}
	else {
		$result = 0;
	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
# Update method - update wiyard step data model
#-------------------------------------------------------------------------------------------#
sub UpdateGlobalSettings {
	my $self    = shift;
	my $cpnSett = shift;

	$self->{"cpnSett"} = $cpnSett;
}

sub UpdateGroupSettings {

	#	my $self      = shift;
	#	my $cpnSett = shift;
	#	my $group     = shift;
	#
	#	$self->{"cpnSett"} = $cpnSett;
}

sub UpdateAutogenerateGroup {
	my $self         = shift;
	my $autoGenerate = shift;

	$self->{"autoGenerate"} = $autoGenerate;
}

#sub UpdateStepData {
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

