
#-------------------------------------------------------------------------------------------#
# Description: Coupon layout
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Parts::SizePart::Model::HEGOrderModel;
use base('Programs::Panelisation::PnlWizard::Core::WizardModelBase');

use Class::Interface;
&implements('Packages::ObjectStorable::JsonStorable::IJsonStorable');

#3th party library
use strict;
use warnings;

#local library
#use aliased 'Programs::Coupon::CpnBuilder::CpnLayout::CpnSingleLayout';
#use aliased 'Programs::Coupon::CpnBuilder::CpnLayout::TitleLayout';
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class = shift;
	my $self  = {};
	$self = $class->SUPER::new(@_);
	bless $self;

	$self->{"modelKey"}    = PnlCreEnums->SizePnlCreator_HEGORDER;
	 
	$self->{"settings"}->{"w"} = undef;
	$self->{"settings"}->{"h"} = undef;
	 

	return $self;

}

sub GetModelKey {
	my $self = shift;

	return $self->{"modelKey"};

}

sub SetWidth {
	my $self = shift;

	$self->{"settings"}->{"w"} = shift;

}

sub GetWidth {
	my $self = shift;

	return $self->{"settings"}->{"w"};

}

sub SetHeight {
	my $self = shift;

	$self->{"settings"}->{"h"} = shift;

}

sub GetHeight {
	my $self = shift;

	return $self->{"settings"}->{"h"};

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

