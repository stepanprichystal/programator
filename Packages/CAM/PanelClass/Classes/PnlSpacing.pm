
#-------------------------------------------------------------------------------------------#
# Description: Class is responsible for creating panel profile
# Import/Export settings method are meant for using class in bacground
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::PanelClass::Classes::PnlSpacing;
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
	my $self = $class->SUPER::new(  $name,@_ );
	bless $self;

	# Setting values necessary for procesing panelisation
	
	$self->{"spaceX"} = 0;
	$self->{"spaceY"} = 0;
	

	return $self;   
}


#-------------------------------------------------------------------------------------------#
#  GET/SET methods for setting class settings
#-------------------------------------------------------------------------------------------#


sub SetSpaceX {
	my $self = shift;
	my $val  = shift;

	$self->{"spaceX"} = $val;
}

sub GetSpaceX {
	my $self = shift;

	return $self->{"spaceX"};
}

sub SetSpaceY {
	my $self = shift;
	my $val  = shift;

	$self->{"spaceY"} = $val;
}

sub GetSpaceY {
	my $self = shift;

	return $self->{"spaceY"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

