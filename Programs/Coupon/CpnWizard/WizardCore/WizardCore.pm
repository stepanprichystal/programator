
#-------------------------------------------------------------------------------------------#
# Description: Wizard core, responsible for go next/back through all wizard steps
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
	$self->{"asyncWorker"}  = shift;

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
	my $self           = shift;
	my $errMess        = shift;
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

		$self->{"stepChangedEvt"}->Do($lastStep) if ($raiseChangeEvt);
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

	$self->{"stepChangedEvt"}->Do($lastStep) if ($raiseChangeEvt);

	#return $self->{"steps"}->[-1];
}

sub Begin {
	my $self = shift;

	for ( my $i = scalar( @{ $self->{"steps"} } ) - 1 ; $i > 0 ; $i-- ) {

		$self->Back(0);
	}

	my $lastStep = $self->{"steps"}->[-1];

	$self->{"stepChangedEvt"}->Do($lastStep);
}

sub End {
	my $self    = shift;
	my $errMess = shift;

	my $result = 1;

	for ( my $i = scalar( @{ $self->{"steps"} } ) - 1 ; $i < $self->{"totalStepCnt"} - 1 ; $i++ ) {

		unless ( $self->Next( $errMess, 0 ) ) {

			$result = 0;
			last;
		}
	}

	my $lastStep = $self->{"steps"}->[-1];
	$self->{"stepChangedEvt"}->Do($lastStep);

	return $result;
}

# Set initial state ov wizard by default value
sub InitByDefault {
	my $self      = shift;
	my $cpnSource = shift;

	foreach my $constr ( $cpnSource->GetConstraints() ) {

		# Default user filter -> all microstrips are checked on the begining
		$self->{"userFilter"}->{ $constr->GetId() } = 1;

		# Default - all strips put to one group
		$self->{"userGroups"}->{ $constr->GetId() } = 1;

	}

	# Default global settings
	$self->{"globalSett"} = CpnSettings->new();

	my $s = WizardStep1->new();
	$s->Init( $self->{"inCAM"},      $self->{"jobId"},      $cpnSource, $self->{"userFilter"},
			  $self->{"userGroups"}, $self->{"globalSett"}, $self->{"asyncWorker"} );

	$s->Load();
	@{ $self->{"steps"} } = $s;
}

sub InitByConfig {
	my $self                = shift;
	my $cpnSource           = shift;
	my $oldConfigUserFilter = shift;    # keys represent strip id and value if strip is used in coupon
	my $oldConfigUserGroups = shift;    # contain strips splitted into group. Key is strip id, val is group number
	my $oldConfigGlobalSett = shift;    # global settings of coupon

	# Set initial state
	# Old config user filter
	$self->{"userFilter"} = $oldConfigUserFilter;

	# Old config user filter
	$self->{"userGroups"} = $oldConfigUserGroups;

	# Old config user filter
	$self->{"globalSett"} = $oldConfigGlobalSett;

	my $s = WizardStep1->new();
	$s->Init( $self->{"inCAM"},      $self->{"jobId"},      $cpnSource, $self->{"userFilter"},
			  $self->{"userGroups"}, $self->{"globalSett"}, $self->{"asyncWorker"} );

	$s->Load();
	@{ $self->{"steps"} } = $s;
}

# Init wizard by values from old configuration
sub LoadConfig {
	my $self         = shift;
	my $cpnGroupSett = shift;    # group settings for each group
	my $cpnStripSett = shift;    # strip settings for each strip by constraint id
	my $errMess      = shift;

	my $result = 1;

	# Load second step
	
	my $curStep = $self->{"steps"}->[-1];

	if ( $curStep->Build($errMess) ) {

		my $s = $curStep->GetNextStep();
		push( @{ $self->{"steps"} }, $s );

		my $lastStep = $self->{"steps"}->[-1];
		$lastStep->Load( 1, $cpnGroupSett, $cpnStripSett );

		$self->{"stepChangedEvt"}->Do($lastStep);

	}
	else {
		$result = 0;
	}

	return $result;
}

sub GetCurrentStepNumber {
	my $self = shift;

	return $self->{"steps"}->[-1]->GetStepNumber();
}

sub GetStep {
	my $self       = shift;
	my $stepNumber = shift;

	return $self->{"steps"}->[$stepNumber];
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

