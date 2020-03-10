
#-------------------------------------------------------------------------------------------#
# Description: Special layer - Coverlay, contain special propery and operation for this
# type of layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::StackupBase::Layer::CoverlayLayer;
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

	$self->{"adhesiveThick"} = shift;

	#only if materialType is copper
	$self->{"method"} = undef;

	return $self;
}

# Thickness of adhesive in µm
sub GetAdhesiveThick {
	my $self = shift;

	return $self->{"adhesiveThick"};
}

# Return method of laminating coverlay
# Coverlay_SELECTIVE - bikini method
# Coverlay_FULL - full coverlaz sheet is laminated
sub GetMethod {
	my $self = shift;
	return $self->{"method"};
}

# Override method GetThick
# If Method is Coverlay_SELECTIVE, coverlay has 0µm thickness
# because is inserted into NoFlw prepreg window (prepreg has same thickness as coverlay)
sub GetThick {
	my $self = shift;
	my $thickInStackup = shift // 1;

	my $thick = $self->SUPER::GetThick();

	if ($thickInStackup) {

		$thick = 0 if ( $self->GetMethod() eq Enums->Coverlay_SELECTIVE );
	}

	return $thick;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

