
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


sub SetBorderLeft {
	my $self = shift;
	my $val  = shift;

	$self->{"leftBorder"} = $val;
}

sub GetBorderLeft {
	my $self = shift;

	return $self->{"leftBorder"};
}

sub SetBorderRight {
	my $self = shift;
	my $val  = shift;

	$self->{"rightBorder"} = $val;
}

sub GetBorderRight {
	my $self = shift;

	return $self->{"rightBorder"};
}

sub SetBorderTop {
	my $self = shift;
	my $val  = shift;

	$self->{"topBorder"} = $val;
}

sub GetBorderTop {
	my $self = shift;

	return $self->{"topBorder"};
}

sub SetBorderBot {
	my $self = shift;
	my $val  = shift;

	$self->{"botBorder"} = $val;
}

sub GetBorderBot {
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

