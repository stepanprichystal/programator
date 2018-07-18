
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

	$self->{"totalStepCnt"} = shift;
	$self->{"asyncWorker"} = shift;

	$self->{"steps"} = [];

	# Properties common for all steps

	$self->{"userFilter"} = {};
	$self->{"userGroups"} = {};
	$self->{"globalSett"} = CpnSettings->new();

	# Events

	$self->{"stepChangedEvt"} = Event->new();

	return $self;
}

sub Next {
	my $self    = shift;
	my $errMess = shift;
	my $raiseChangeEvt = shift // 1;

	my $result = 1;

	my $curStep = $self->{"steps"}->[-1];

	my $s = undef;

	if ( $curStep->Build($errMess) ) {

		$s = $curStep->GetNextStep();

		push( @{ $self->{"steps"} }, $s );

	}
	else {

		$result = 0;
	}

	if ($result) {
		my $lastStep = $self->{"steps"}->[-1];
		$lastStep->Load();
		
		$self->{"stepChangedEvt"}->Do($lastStep) if($raiseChangeEvt);
	}
	
	return $result;

}

sub Back {
	my $self = shift;
	my $raiseChangeEvt = shift // 1;

	if ( scalar( @{ $self->{"steps"} } ) > 1 ) {

		splice @{ $self->{"steps"} }, scalar( @{ $self->{"steps"} } ) - 1, 1;
	}
	else {

		die "Unable to back, there is no another back step";
	}

	my $lastStep = $self->{"steps"}->[-1];


	$self->{"stepChangedEvt"}->Do($lastStep) if($raiseChangeEvt);

	#return $self->{"steps"}->[-1];
}

sub Begin {
	my $self = shift;

	for ( my $i = scalar( @{$self->{"steps"}} ) - 1 ; $i > 0; $i-- ) {

		$self->Back(0);
	}

	my $lastStep = $self->{"steps"}->[-1];


	$self->{"stepChangedEvt"}->Do($lastStep);
}

sub End {
	my $self = shift;
	my $errMess = shift;

	my $result = 1;

	for ( my $i = scalar( @{$self->{"steps"}} ) - 1 ; $i < $self->{"totalStepCnt"} -1; $i++ ) {

		unless($self->Next($errMess, 0)){
			
			$result = 0;
			last;
		}
	}
 
 	my $lastStep = $self->{"steps"}->[-1];
	$self->{"stepChangedEvt"}->Do($lastStep);
	
	return $result;
}

sub Init {
	my $self    = shift;
	my $xmlPath = shift;

	my $cpnSource = CpnSource->new($xmlPath);

	# Set initial state

	foreach my $constr ( $cpnSource->GetConstraints() ) {

		# User filter -> all microstrips are checked on the begining
		$self->{"userFilter"}->{ $constr->GetId() } = 1;

		# All strips put to one group
		$self->{"userGroups"}->{ $constr->GetId() } = 1;

	}

	$self->{"globalSett"} = CpnSettings->new();

	my $s = WizardStep1->new();
	$s->Init( $self->{"inCAM"}, $self->{"jobId"}, $cpnSource, $self->{"userFilter"}, $self->{"userGroups"}, $self->{"globalSett"}, $self->{"asyncWorker"} );
	$s->Load();

	push( @{ $self->{"steps"} }, $s );

}

sub GetCurrentStepNumber{
	my $self    = shift;
	
	return $self->{"steps"}->[-1]->GetStepNumber();
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

	my $xmlPath = 'r:\PCB\Safiral_4vv.xml';

	my $wizard = WizardCore->new( $inCAM, $jobId );
	$wizard->Init($xmlPath);

	$wizard->Next();    # go to step 2

	$wizard->Next();    # go to step 3

}

1;

