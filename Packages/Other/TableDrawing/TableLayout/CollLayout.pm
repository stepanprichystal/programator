
#-------------------------------------------------------------------------------------------#
# Description: Interface, allow build nif section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Other::TableDrawing::TableLayout::CollLayout;
use base qw(Packages::Other::TableDrawing::TableLayout::TableLayoutBase);

use Class::Interface;
&implements('Packages::ObjectStorable::JsonStorable::IJsonStorable');

#3th party library
use strict;
use warnings;

#use File::Copy;

#local library
use aliased 'Packages::Other::TableDrawing::TableLayout::StyleLayout::BorderStyle';
use aliased 'Packages::Other::TableDrawing::Enums';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $id          = shift;
	my $key         = shift;
	my $width       = shift;
	my $backgStyle  = shift;
	my $borderStyle = shift;

	my $self = {};
	$self = $class->SUPER::new(@_);
	bless $self;

	$self->{"id"}          = $id;
	$self->{"key"}         = $key;
	$self->{"width"}       = $width;
	$self->{"backgStyle"}  = $backgStyle;
	$self->{"borderStyle"} = $borderStyle;
	
	return $self;
}

sub GetId {
	my $self = shift;

	return $self->{"id"};

}

sub GetKey {
	my $self = shift;

	return $self->{"key"};

}

sub GetWidth {
	my $self = shift;

	return $self->{"width"};

}

sub GetBackgStyle {
	my $self = shift;

	return $self->{"backgStyle"};

}

sub GetBorderStyle {
	my $self = shift;

	return $self->{"borderStyle"};

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

