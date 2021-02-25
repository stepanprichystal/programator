
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

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class = shift;
	my $self  = {};
	$self = $class->SUPER::new(@_);
	bless $self;
 
 
	$self->{"w"}             = undef;
	$self->{"h"}             = undef;
  
	return $self;

}

 

sub SetWidth {
	my $self = shift;

	$self->{"w"} = shift;

}

sub SetHeight {
	my $self = shift;

	$self->{"h"} = shift;

}

sub GetWidth {
	my $self = shift;

	return $self->{"w"};

}

sub GetHeight {
	my $self = shift;

	return $self->{"h"};

}
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	 
}

1;

