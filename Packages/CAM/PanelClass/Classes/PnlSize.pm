
#-------------------------------------------------------------------------------------------#
# Description: Represent Panel size definition
# panel class name has following format:
# <material type>_<layer number type>_<dimension>_<special>
# - <material type> - mandatory (flex, rigid, al, hybrid, ..)
# - <layer number type> - mandatory (2v, vv)
# - <dimension> - optional (\d x \d)
# - <special> - optional, represent special durface in most cases (pbhal, grafit, au, ..)
#
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::PanelClass::Classes::PnlSize;
use base('Packages::CAM::PanelClass::Classes::PnlClassBase');

use Class::Interface;
&implements('Packages::ObjectStorable::JsonStorable::IJsonStorable');

#3th party library
use strict;
use warnings;


#local library
use aliased 'Programs::Panelisation::PnlCreator::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class   = shift;
	my $name = shift;
	my $self = $class->SUPER::new( $name,@_ );
	bless $self;

	# Setting values necessary for procesing panelisation
	$self->{"width"} = 0;
	$self->{"height"} = 0;
	
	$self->{"borders"}  = [];
	$self->{"spacings"} = [];

	return $self;   
}


#-------------------------------------------------------------------------------------------#
#  GET/SET methods for setting class settings
#-------------------------------------------------------------------------------------------#

sub SetBorders {
	my $self = shift;
	my $val  = shift;

	$self->{"borders"} = $val;
}

sub GetBorders {
	my $self = shift;

	return @{ $self->{"borders"} };
}

sub SetSpacings {
	my $self = shift;
	my $val  = shift;

	$self->{"spacings"} = $val;
}

sub GetSpacings {
	my $self = shift;

	return @{ $self->{"spacings"} };
}

sub SetWidth {
	my $self = shift;
	my $val  = shift;

	$self->{"width"} = $val;
}

sub GetWidth {
	my $self = shift;

	return $self->{"width"};
}

sub SetHeight {
	my $self = shift;
	my $val  = shift;

	$self->{"height"} = $val;
}

sub GetHeight {
	my $self = shift;

	return $self->{"height"};
}



#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

