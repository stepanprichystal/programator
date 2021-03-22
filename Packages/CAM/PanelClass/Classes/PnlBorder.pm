
#-------------------------------------------------------------------------------------------#
# Description: Represent Panel border definition
# panel class name has following format:
# <material type>_<layer number type>_<dimension>_<special>
# - <material type> - mandatory (flex, rigid, al, hybrid, ..)
# - <layer number type> - mandatory (2v, vv)
# - <dimension> - optional (\d x \d)
# - <special> - optional, represent special durface in most cases (pbhal, grafit, au, ..)
#
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::PanelClass::Classes::PnlBorder;
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
	my $class = shift;
	my $name = shift;
	my $self = $class->SUPER::new( $name, @_ );
	bless $self;

	# Setting values necessary for procesing panelisation

	$self->{"leftBorder"}  = 0;
	$self->{"rightBorder"} = 0;
	$self->{"topBorder"}   = 0;
	$self->{"botBorder"}   = 0;

	return $self;
}

#-------------------------------------------------------------------------------------------#
#  GET/SET methods for setting class settings
#-------------------------------------------------------------------------------------------#


sub SetLeftBorder {
	my $self = shift;
	my $val  = shift;

	$self->{"leftBorder"} = $val;
}

sub GetLeftBorder {
	my $self = shift;

	return $self->{"leftBorder"};
}

sub SetRightBorder {
	my $self = shift;
	my $val  = shift;

	$self->{"rightBorder"} = $val;
}

sub GetRightBorder {
	my $self = shift;

	return $self->{"rightBorder"};
}

sub SetTopBorder {
	my $self = shift;
	my $val  = shift;

	$self->{"topBorder"} = $val;
}

sub GetTopBorder {
	my $self = shift;

	return $self->{"topBorder"};
}

sub SetBotBorder {
	my $self = shift;
	my $val  = shift;

	$self->{"botBorder"} = $val;
}

sub GetBotBorder {
	my $self = shift;

	return $self->{"botBorder"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

