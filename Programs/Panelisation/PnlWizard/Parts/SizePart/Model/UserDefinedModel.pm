
#-------------------------------------------------------------------------------------------#
# Description: Coupon layout
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Parts::SizePart::Model::UserDefinedModel;
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

	$self->{"modelKey"} = PnlCreEnums->SizePnlCreator_USERDEFINED;
	$self->{"data"}        = {};
	$self->{"data"}->{"w"} = undef;
	$self->{"data"}->{"h"} = undef;

	return $self;

}

sub GetModelKey {
	my $self = shift;

	return $self->{"modelKey"};

}

sub SetWidth {
	my $self = shift;

	$self->{"data"}->{"w"} = shift;

}

sub GetWidth {
	my $self = shift;

	return $self->{"data"}->{"w"};

}

sub SetHeight {
	my $self = shift;

	$self->{"data"}->{"h"} = shift;

}

sub GetHeight {
	my $self = shift;

	return $self->{"data"}->{"h"};

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;


