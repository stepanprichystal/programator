
#-------------------------------------------------------------------------------------------#
# Description: Interface, allow build nif section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Other::TableDrawing::TableLayout::CellLayout;
use base qw(Packages::Other::TableDrawing::TableLayout::TableLayoutBase);

use Class::Interface;
&implements('Packages::ObjectStorable::JsonStorable::IJsonStorable');

#3th party library
use strict;
use warnings;
use List::Util qw(first);

#local library
use aliased 'Packages::Other::TableDrawing::Enums';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $id          = shift;
	my $text        = shift;
	my $textStyle   = shift;
	my $backgStyle  = shift;
	my $borderStyle = shift;
	my $xPosCnt     = shift;    # number of merged cells
	my $yPosCnt     = shift;    # number of merged cells

	my $self = {};
	$self = $class->SUPER::new(@_);
	bless $self;

	$self->{"id"}          = $id;
	$self->{"text"}        = $text;
	$self->{"textStyle"}   = $textStyle;
	$self->{"backgStyle"}  = $backgStyle;
	$self->{"borderStyle"} = $borderStyle;
	$self->{"xPosCnt"}     = $xPosCnt;       # number of merged cells
	$self->{"yPosCnt"}     = $yPosCnt;       # number of merged cells

	return $self;
}

sub GetId {
	my $self = shift;
	return $self->{"id"};
}

sub GetText {
	my $self = shift;

	return $self->{"text"};

}

sub GetTextStyle {
	my $self = shift;

	return $self->{"textStyle"};

}

sub GetBackgStyle {
	my $self = shift;

	return $self->{"backgStyle"};

}

sub GetBorderStyle {
	my $self = shift;

	return $self->{"borderStyle"};
}

sub GetIsMerged {
	my $self = shift;

	return ( $self->{"xPosCnt"} > 1 || $self->{"yPosCnt"} > 1 ) ? 1 : 0;
}

sub GetXPosCnt {
	my $self = shift;

	return $self->{"xPosCnt"};
}

sub GetYPosCnt {
	my $self = shift;

	return $self->{"yPosCnt"};
}

sub SetText {
	my $self = shift;

	$self->{"text"} = shift;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

