
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnWizard::WizardCore::WizardCore;

#3th party library
use strict;
use warnings;

#local library

use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::Coupon::CpnWizard::WizardCore::WizardStep1';
use aliased 'Programs::Coupon::CpnSettings::CpnSettings';
use aliased 'Programs::Coupon::CpnSource::CpnSource';
use aliased 'Packages::Events::Event';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	#$self->{"layout"} = shift;

	$self->{"steps"} = [];

	# Events

	$self->{"stepChangedEvt"} = Event->new();

	return $self;
}

sub Next {
	my $self = shift;

	my $curStep = $self->{"steps"}->[-1];

	my $errMess = "";
	my $s       = undef;

	if ( $curStep->Build( \$errMess ) ) {

		$s = $curStep->GetNextStep();
		push( @{ $self->{"steps"} }, $s );

	}
	else {

		die "Failed to build step $curStep $errMess";

	}

	my $lastStep = $self->{"steps"}->[-1];

	$self->{"stepChangedEvt"}->Do($lastStep);

}

sub Back {
	my $self = shift;

	if ( scalar( @{ $self->{"steps"} } ) > 1 ) {

		splice @{ $self->{"steps"} }, scalar( @{ $self->{"steps"} } ) - 1, 1;
	}
	else {

		die "Unable to back, there is no another back step";
	}

	my $lastStep = $self->{"steps"}->[-1];

	$self->{"stepChangedEvt"}->Do($lastStep);

	#return $self->{"steps"}->[-1];
}

sub Begin {
	my $self = shift;

	my $lastStep = $self->{"steps"}->[-1];

	$self->{"stepChangedEvt"}->Do($lastStep);

}

sub End {
	my $self = shift;

	my $lastStep = $self->{"steps"}->[-1];

	$self->{"stepChangedEvt"}->Do($lastStep);

}

sub Init {
	my $self    = shift;
	my $xmlPath = shift;

	my $cpnSource = CpnSource->new($xmlPath);

	my $s = WizardStep1->new( $self->{"inCAM"}, $self->{"jobId"}, $cpnSource );

	$s->UpdateGroupFilter( [ 1] );
	$s->Init();

	push( @{ $self->{"steps"} }, $s );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::Coupon::CpnWizard::WizardCore::WizardCore';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f13609";

	my $xmlPath = 'c:\Export\CouponExport\cpn.xml';

	my $wizard = WizardCore->new( $inCAM, $jobId );
	$wizard->Init($xmlPath);

	$wizard->Next();    # go to step 2

	$wizard->Next();    # go to step 3

}

1;

