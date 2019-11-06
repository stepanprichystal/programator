
#-------------------------------------------------------------------------------------------#
# Description: Special layer - prepreg, contain special propery and operation for this
# type of layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::StackupBase::Layer::PrepregLayer;
use base('Packages::Stackup::StackupBase::Layer::StackupLayer');

use Class::Interface;
&implements('Packages::Stackup::StackupBase::Layer::IStackupLayer');

#3th party library
use strict;
use warnings;

#local library

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	# child prepregs
	my @prepregs = ();
	$self->{"prepregs"} = \@prepregs;

	$self->{"parent"} = 0;

	# Identification of material by Multicall ml.xml

	$self->{"qId"} = undef;    # quality of material

	$self->{"noFlow"} = 0;     # no flow prepreg for RigidFlex

	$self->{"noFlowType"} = undef; # no flow prepreg for RigidFlex

	return $self;
}

sub AddChildPrepreg {
	my $self    = shift;
	my $prepreg = shift;

	push( @{ $self->{"prepregs"} }, $prepreg );
}

sub GetAllPrepregs {
	my $self = shift;

	return @{ $self->{"prepregs"} };
}

sub GetQId {
	my $self = shift;
	return $self->{"qId"};
}

sub GetIsNoFlow {
	my $self = shift;

	return $self->{"noFlow"};
}

sub GetNoFlowType {
	my $self = shift;

	die "Prepreg is not NoFLow " unless ( $self->GetIsNoFlow() );

	return $self->{"noFlowType"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

