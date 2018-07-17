
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
use List::MoreUtils qw(uniq);

#local library

use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::Coupon::CpnSettings::CpnSettings';
use aliased 'Programs::Coupon::CpnSettings::CpnSingleSettings';
use aliased 'Programs::Coupon::CpnSettings::CpnStripSettings';
use aliased 'Programs::Coupon::CpnWizard::WizardCore::Helper';
use aliased 'Packages::ObjectStorable::JsonStorable::JsonStorable';
use aliased 'Programs::Coupon::CpnGenerator::CpnGenerator';
use aliased 'Packages::Events::Event';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
my $PROCESS_END_EVT : shared;    # evt raise when processing reorder is done

sub new {
	my $class = shift;

	my $stepId     = 3;
	my $title      = "Check coupon preview and finish wizard";
	my $cpnLayout  = shift;
	my $cpnVariant = shift;

	my $self = $class->SUPER::new( $stepId, $title );
	bless $self;

	# data model for step class
	$self->{"cpnLayout"}    = $cpnLayout;
	$self->{"cpnVariant"}   = $cpnVariant;
	$self->{"cpnGenerated"} = 0;
	

	# EVENTS
	$self->{"onGenerateCouponAsync"} = Event->new(); 

	return $self;
}

sub Load {
	my $self = shift;

	$self->{"cpnGenerated"} = 0;

}

sub Build {
	my $self    = shift;
	my $errMess = shift;

	my $result = 1;
	#
	#	my $groupGenPolicy = GeneratorPolicy->new( $self->{"cpnSource"}, $self->{"globalSett"}->GetMaxTrackCnt() );
	#
	#	# Create structure from strips and groups suitable for Layout algorithm
	#	my %constrFilter = %{ $self->GetConstrFilter() };
	#	my @constr = grep { $constrFilter{$_} } keys %constrFilter;
	#
	#	my @comb = ();
	#	foreach my $g ( $self->GetUniqueGroups() ) {
	#		my @strips = map { $self->{"cpnSource"}->GetConstraint($_) } grep { $self->{"userGroups"}->{$_} == $g } @constr;
	#
	#		push( @comb, \@strips );
	#	}
	#
	#	my $combStruct = $groupGenPolicy->GenerateGroupComb( \@comb );
	#
	#	# Create translate table (user group id => group id given by order)
	#	my %groupSettings = ();
	#	my @uniqGroups    = $self->GetUniqueGroups();
	#	for ( my $i = 0 ; $i < scalar(@uniqGroups) ; $i++ ) {
	#
	#		$groupSettings{$i} = $self->{"cpnGroupSett"}->{ $uniqGroups[$i] };
	#	}
	#
	#	# try build Cpnvariant
	#	my $variant =
	#	  Helper->GetBestGroupVariant( $self->{"cpnSource"}, [$combStruct], $self->{"globalSett"}, \%groupSettings );
	#
	#	if ( !defined $variant && $self->{"autogenerate"} ) {
	#
	#		$variant = Helper->GetBestGroupCombination( $self->{"cpnSource"}, \@constr, $self->{"globalSett"} );
	#
	#		if ( !defined $variant ) {
	#
	#			$$errMess .= "Unable to automatically generate coupon. Change settings or create more groups.";
	#		}
	#
	#	}
	#	elsif(!defined $variant && !$self->{"autogenerate"}) {
	#
	#		$$errMess .= "Unable to build coupon. Try allow option 'autogenerate'";
	#	}
	#
	#	# variant was found
	#	if ( defined $variant ) {
	#
	#		Helper->AddSett2CpnVarinat( $variant, $self->{"globalSett"}, \%groupSettings, $self->{"cpnStripSett"} );
	#
	#	}
	#	else {
	#
	#		$result = 0;
	#
	#	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
# Update method - update wizard step data model
#-------------------------------------------------------------------------------------------#

sub UpdateCpnGenerated {
	my $self = shift;

	$self->{"cpnGenerated"} = shift;
}
 
sub GenerateCoupon{
	my $self = shift;
	my $wizardFinish = shift;
	
	# Define params for async subroutine
	my @params = ();
	
	my $layout       = $self->GetCpnLayout();
	my $storable     = JsonStorable->new();
	my $cpnLayoutSer = $storable->Encode($layout);
	
	push( @params, $self->{"jobId"} );
	push( @params, $self->GetCpnGenerated() );
	push( @params, $wizardFinish );
	push( @params, $cpnLayoutSer );

 
	$self->RunAsyncWorker( \&GenerateCouponAsync, sub {  $self->{"onGenerateCouponAsync"}->Do(@_) }, \@params, $self->{"inCAM"} );
}
 
 
# Asynchrounous function, called from child thread
sub GenerateCouponAsync {
	my $className = shift;
	my $inCAM        = shift;
	my $jobId        = shift;
	my $cpnGenerated = shift;
	my $wizardFinish = shift;
	my $cpnLayoutSer    = shift; # serialized cpn layout
	
	my $errMess      = "";

	my $result = 1;

	my $storable = JsonStorable->new();
	my $cpnLayout = $storable->Decode($cpnLayoutSer);
 
	unless ($cpnGenerated) {
		my $generator = CpnGenerator->new( $inCAM, $jobId );
		
		$inCAM->SetDisplay(0);
		$generator->Generate($cpnLayout);
		$inCAM->SetDisplay(1);
	}

	# flatten coupon
	if ($wizardFinish) {

		my $generator = CpnGenerator->new( $inCAM, $jobId );
		$generator->FlattenCpn($cpnLayout);
	}
	
	my %res : shared = ();

	$res{"result"}       = $result;
	$res{"errMess"}      = $errMess;
	$res{"finishWizard"} = $wizardFinish;
 
	return \%res;
}

#-------------------------------------------------------------------------------------------#
# Get data from model -
#-------------------------------------------------------------------------------------------#

sub GetCpnLayout {
	my $self = shift;

	return $self->{"cpnLayout"};
}

sub GetCpnVariant {
	my $self = shift;

	return $self->{"cpnVariant"};
}

sub GetCpnGenerated {
	my $self = shift;

	return $self->{"cpnGenerated"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

