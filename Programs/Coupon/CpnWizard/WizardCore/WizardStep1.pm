
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

	my $stepId = 1;
	my $title  = "Select microstrips, generate groups";

	my $self = $class->SUPER::new( $stepId, $title );
	bless $self;

	# data model for step class

	return $self;
}

sub Load {
	my $self = shift;

	# Generate default group combination

	# Get groups from cpn variant
	my $defGroupComb = [];

	my @allConstr = $self->{"cpnSource"}->GetConstraints();

	push( @{$defGroupComb}, \@allConstr );

}

sub Build {
	my $self    = shift;
	my $errMess = shift;

	my $result = 1;

	# get group combination variants by user settings

	if ( scalar( grep { $self->{"userFilter"}->{$_} } keys %{ $self->{"userFilter"} } ) ) {

		$self->{"nextStep"} = WizardStep2->new();
		$self->{"nextStep"}->Init($self->{"inCAM"}, 
								$self->{"jobId"},
									$self->{"cpnSource"},
								   $self->{"userFilter"},
								   $self->{"userGroups"},
								   $self->{"globalSett"});

	}
	else {
		$result = 0;
		$$errMess .= "No microstrips selected";
	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
# Update method - update wizard step data model
#-------------------------------------------------------------------------------------------#
sub UpdateConstrFilter {
	my $self     = shift;
	my $constrId = shift;
	my $selected = shift;

	$self->{"userFilter"}->{$constrId} = $selected;
}

sub AutogenerateGroups {
	my $self = shift;

	my $result = 1;

	# prepare filter - only selected constr
	my @filter = grep { $self->{"userFilter"}->{$_} == 1 } keys %{ $self->{"userFilter"} };

	my $cpnVariant = Helper->GetBestGroupCombination( $self->{"cpnSource"}, \@filter, $self->{"globalSett"} );

	if ( defined $cpnVariant ) {

		# set goups to constr
		my @singlCpns = $cpnVariant->GetSingleCpns();
		for ( my $i = 0 ; $i < scalar( scalar(@singlCpns) ) ; $i++ ) {

			my $singlCpn = $singlCpns[$i];
			$self->UpdateConstrGroup( $_, $i + 1 ) foreach ( map { $_->Id() } $singlCpn->GetAllStrips() );

		}

		print STDERR "Generated variant: $cpnVariant";
	}
	else {

		$result = 0;
	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
# Get data from model -
#-------------------------------------------------------------------------------------------#

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

