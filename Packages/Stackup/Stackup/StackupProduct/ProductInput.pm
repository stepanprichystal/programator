
#-------------------------------------------------------------------------------------------#
# Description: Input product can be created fro mnested Input Products
# Nested Input Product contain only core (plus core coppers) layers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::Stackup::StackupProduct::ProductInput;
use base('Packages::Stackup::Stackup::StackupProduct::ProductBase');

use Class::Interface;
&implements('Packages::Stackup::Stackup::StackupProduct::IProduct');

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

	# PROPERTIES

	$self->{"productType"} = Enums->Product_INPUT;

	# Only child inputs
	$self->{"emptyFoilTop"} = 0;	
	$self->{"emptyFoilBot"} = 0;	
	
	return $self;
}

# Return if core is rigid or flex
# Decision is basend on core thickness (less than 100µm is flex core )
sub GetCoreRigidType {
	my $self = shift;

	my $c;

	if ( $self->GetIsParent() ) {

		$c = ( map { $_->GetData() } $self->GetChildProducts() )[0];
	}
	else {

		$c = ( map { $_->GetData() } grep { $_->GetData()->GetType() eq Enums->MaterialType_CORE } $self->GetLayers() )[0];
	}

	return $c->GetCoreRigidType();
}

# Input product contains layer only in child input product
sub GetIsParent {
	my $self = shift;

	unless ( scalar( grep { $_->GetType() eq Enums->ProductL_PRODUCT } @{ $self->{"layers"} } ) ) {

		return 0;

	}
	else {

		return 1;

	}
}

sub GetCoreNumber {
	my $self = shift;

	if ( $self->GetIsParent() ) {

		die "Only child Input Product is represent by single core";

	}
	else {

		my $c = ( map { $_->GetData() } grep { $_->GetData()->GetType() eq Enums->MaterialType_CORE } $self->GetLayers() )[0];
		return $c->GetCoreNumber();
	}
}

# Return all child input products
sub GetChildProducts {
	my $self = shift;

	my @childs = grep { $_->GetType() eq Enums->ProductL_PRODUCT } @{ $self->{"layers"} };

	return @childs;
}


sub GetTopEmptyFoil {
	my $self = shift;

	return $self->{"emptyFoilTop"};
}

sub GetBotEmptyFoil {
	my $self = shift;

	return $self->{"emptyFoilBot"};
}

sub SetTopOuterCore {
	my $self = shift;

	#die "Only child input product allow set full copper" if ( $self->GetIsParent() );

	$self->{"outerCoreTop"} = shift;
}

sub SetBotOuterCore {
	my $self = shift;

	#die "Only child input product allow set full copper" if ( $self->GetIsParent() );

	$self->{"outerCoreBot"} = shift;
}

sub SetTopEmptyFoil {
	my $self = shift;

	#die "Only child input product allow set full copper" if ( $self->GetIsParent() );

	$self->{"emptyFoilTop"} = shift;
}

sub SetBotEmptyFoil {
	my $self = shift;

	#die "Only child input product allow set full copper" if ( $self->GetIsParent() );

	$self->{"emptyFoilBot"} = shift;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

