
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnWizard::WizardCore::WizardStepBase;

#3th party library
use strict;
use warnings;

#local library

use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"stepNumber"} = shift;
	$self->{"title"}      = shift;
 
	# common data structurews for all steps
	$self->{"cpnSource"}  = undef;
	$self->{"userFilter"} = undef;
	$self->{"userGroups"} = undef;
	$self->{"globalSett"} = undef;
	$self->{"asyncWorker"} = undef;

	# next step build by current step
	$self->{"nextStep"} = undef;

	return $self;
}

sub Init{
	my $self = shift;
	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
	$self->{"cpnSource"}  = shift;
	$self->{"userFilter"} = shift;
	$self->{"userGroups"} = shift;
	$self->{"globalSett"} = shift;
	$self->{"asyncWorker"} = shift;
}

sub GetNextStep {
	my $self = shift;

	return $self->{"nextStep"};
}

sub GetStepNumber {
	my $self = shift;

	return $self->{"stepNumber"};
}


sub RunAsyncWorker{
	my $self = shift;
	my $workerMethod   = shift;
	my $callbackMethod = shift;
	my $workerParams   = shift;
	my $inCAM          = shift;
	
	
	$self->{"asyncWorker"}->Run($workerMethod, $callbackMethod, $workerParams, $inCAM);
}
#-------------------------------------------------------------------------------------------#
# GEt method - get wizard step data model
#-------------------------------------------------------------------------------------------#

sub GetConstraints {
	my $self = shift;

	return $self->{"cpnSource"}->GetConstraints();

}

sub GetConstrGroups {
	my $self = shift;

	return $self->{"userGroups"};
}

sub GetConstrFilter {
	my $self = shift;

	return $self->{"userFilter"};
}

sub GetGlobalSett {
	my $self = shift;

	return $self->{"globalSett"};
}

sub GetTitle {
	my $self = shift;

	return $self->{"title"};

}

#-------------------------------------------------------------------------------------------#
# Update method - update wizard step data model
#-------------------------------------------------------------------------------------------#

sub UpdateConstrGroup {
	my $self     = shift;
	my $constrId = shift;
	my $groupVal = shift;

	$self->{"userGroups"}->{$constrId} = $groupVal;

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

