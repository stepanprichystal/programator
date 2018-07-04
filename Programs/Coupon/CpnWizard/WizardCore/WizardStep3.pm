
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnWizard::WizardCore::WizardStep3;
use base('Programs::Coupon::CpnWizard::WizardCore::WizardStepBase');

use Class::Interface;
&implements('Programs::Coupon::CpnWizard::WizardCore::IWizardStep');

#3th party library
use strict;
use warnings;

#local library

use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::Coupon::CpnSettings::CpnSettings';
use aliased 'Programs::Coupon::CpnSource::CpnSource';
use aliased 'Programs::Coupon::CpnWizard::WizardCore::Helper';
use aliased 'Programs::Coupon::CpnPolicy::GroupPolicy';
use aliased 'Programs::Coupon::CpnBuilder::CpnBuilder';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self = $class->SUPER::new( 3, @_ );
	bless $self;

	# data model for step class
	$self->{"cpnVariant"} = undef;
	$self->{"cpnSett"}    = undef;
	$self->{"cpnLayout"}  = undef;

	return $self;
}

sub Init {
	my $self       = shift;
	my $cpnVariant = shift;
	my $cpnSett    = shift;

	$self->{"cpnVariant"} = $cpnVariant;
	$self->{"cpnSett"}    = $cpnSett;

}

sub Build {
	my $self    = shift;
	my $errMess = shift;

	my $result = 1;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $buildParams = BuildParams->new( $self->{"cpnVariant"} );
	my $builder = CpnBuilder->new( $inCAM, $jobId, $self->{"cpnSource"}, $self->{"cpnSett"} );

	if ( $builder->Build( $errMess, $buildParams ) ) {

		$self->{"cpnLayout"} = $builder->GetLayout();
	}
	else {

		die "Coupon was not biulded $errMess";
	}

	#	#get group combination variants by user settings
	#
	#	# 1) build combination structure
	#
	#	my $cpnVariant = Helper->GetBestGroupVariant( $self->{"groupComb"}, $self->{"cpnSett"} );
	#
	#	# generate new groups
	#	if ( !defined $cpnVariant && $autoGenerate ) {
	#
	#		$cpnVariant = Helper->GetBestGroupCombination( $self->{"cpnSource"}, $self->{"filter"}, $self->{"cpnSett"} );
	#
	#	}
	#
	#	# if cpn variant layout is ok, build is ok
	#	if ( defined $cpnVariant ) {
	#
	#		$self->{"nextStep"} = WizardStep3->new( $groupComb, $self->{"cpnSource"}, $cpnSett );
	#
	#	}
	#	else {
	#		$result = 0;
	#	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
# Update method - update wiyard step data model
#-------------------------------------------------------------------------------------------#
#sub UpdateGlobalSettings {
#	my $self    = shift;
#	my $cpnSett = shift;
#
#	$self->{"cpnSett"} = $cpnSett;
#}
#
#sub UpdateGroupSettings {
#
#	#	my $self      = shift;
#	#	my $cpnSett = shift;
#	#	my $group     = shift;
#	#
#	#	$self->{"cpnSett"} = $cpnSett;
#}
#
#sub UpdateAutogenerateGroup {
#	my $self         = shift;
#	my $autoGenerate = shift;
#
#	$self->{"autoGenerate"} = $autoGenerate;
#}

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

