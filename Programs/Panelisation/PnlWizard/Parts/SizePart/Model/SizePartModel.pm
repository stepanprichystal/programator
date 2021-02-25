
#-------------------------------------------------------------------------------------------#
# Description: Coupon layout
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Parts::SizePart::Model::SizePartModel;
use base('Programs::Panelisation::PnlWizard::Core::WizardModelBase');

use Class::Interface;
&implements('Packages::ObjectStorable::JsonStorable::IJsonStorable');

#3th party library
use strict;
use warnings;

#local library
#use aliased 'Programs::Coupon::CpnBuilder::CpnLayout::CpnSingleLayout';
#use aliased 'Programs::Coupon::CpnBuilder::CpnLayout::TitleLayout';

use aliased 'Programs::Panelisation::PnlWizard::Parts::SizePart::Model::UserDefinedModel';
use aliased 'Programs::Panelisation::PnlCreator::Enums' => 'PnlCreEnums';
#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class = shift;
	my $self  = {};
	$self = $class->SUPER::new(@_);
	bless $self;

	$self->{"creators"} = {};
	$self->{"selected"} = PnlCreEnums->SizePnlCreator_USERDEFINED;

	$self->{"creators"}->{ PnlCreEnums->SizePnlCreator_USERDEFINED } = UserDefinedModel->new();

	return $self;
}

sub SetSelectedCreator {
	my $self = shift;

	$self->{"selected"} = shift;

}

sub GetSelectedCreator {
	my $self = shift;

	return $self->{"selected"};

}

sub SetCreators {
	my $self = shift;

	$self->{"creators"} = shift;

}

sub GetCreators {
	my $self = shift;

	return $self->{"creators"};

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

