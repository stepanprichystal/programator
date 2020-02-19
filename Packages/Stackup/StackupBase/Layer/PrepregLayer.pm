
#-------------------------------------------------------------------------------------------#
# Description: Special layer - prepreg, contain special propery and operation for this
# type of layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::StackupBase::Layer::PrepregLayer;
use base('Packages::Stackup::StackupBase::Layer::StackupLayerBase');

use Class::Interface;
&implements('Packages::Stackup::StackupBase::Layer::IStackupLayer');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Stackup::Enums';

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

	$self->{"noFlowType"} = undef;    # no flow prepreg for RigidFlex
	
	$self->{"flexPress"} = undef;    # indicate if prepreg is laminated on flex core separately (preparing input product)

	# no flow prepreg can contain coverlay
	# Coverlay pieces has same height as prepreg and are placed into pre-milled prepreg windows
	$self->{"inclCoverlay"} = undef;

	return $self;
}

sub AddChildPrepreg {
	my $self    = shift;
	my $prepreg = shift;
	
	$self->{"thick"} += $prepreg->GetThick();

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

sub GetFlexPress {
	my $self = shift;

	die "Prepreg is not NoFLow " unless ( $self->GetIsNoFlow() );

	return $self->{"flexPress"};
}



sub GetCoverlay {
	my $self = shift;

	die "Prepreg is not NoFLow " unless ( $self->GetIsNoFlow() );

	return $self->{"inclCoverlay"};
}

sub GetIsCoverlayIncl {
	my $self = shift;

	die "Prepreg is not NoFLow " unless ( $self->GetIsNoFlow() );

	return defined $self->{"inclCoverlay"} ? 1 : 0;
}

sub AddCoverlay {
	my $self = shift;
	my $cvrl = shift;

	die "Prepreg is not NoFLow " unless ( $self->GetIsNoFlow() );
	#die "Prepreg is not type P1 " unless ( $self->GetNoFlowType() eq Enums->NoFlowPrepreg_P1);
	
	$self->{"noFlowType"} = Enums->NoFlowPrepreg_P1; # Change type of prepregs to P1

	$self->{"inclCoverlay"} = $cvrl;
}

sub SetThickCuUsage{
	my $self = shift;
	my $thick = shift;
	
	$self->{"thick"} = $thick;
}


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

