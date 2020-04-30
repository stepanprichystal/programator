
#-------------------------------------------------------------------------------------------#
# Description: Interface, allow build nif section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Other::TableDrawing::TableLayout::StyleLayout::BorderStyle;
use base qw(Packages::Other::TableDrawing::TableLayout::TableLayoutBase);

use Class::Interface;
&implements('Packages::ObjectStorable::JsonStorable::IJsonStorable');

#3th party library
use strict;
use warnings;

#use File::Copy;

#local library
use aliased 'Packages::Other::TableDrawing::Enums';
use aliased 'Packages::Other::TableDrawing::TableLayout::StyleLayout::Color';
use aliased 'Packages::Other::TableDrawing::TableLayout::StyleLayout::StrokeStyle';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $top   = shift;
	my $bot   = shift;
	my $left  = shift;
	my $right = shift;

	my $self = {};
	$self = $class->SUPER::new(@_);
	bless $self;

	$self->{"eStyles"} = {};

	$self->{"eStyles"}->{"top"}   = $top;
	$self->{"eStyles"}->{"bot"}   = $bot;
	$self->{"eStyles"}->{"left"}  = $left;
	$self->{"eStyles"}->{"right"} = $right;
 
	return $self;
}
 
sub AddEdgeStyle {
	my $self        = shift;
	my $edge        = shift;                   #top/bot/left/right
	my $strokeStyle = shift;
	my $strokeWidth = shift;
	my $strokeColor = shift;
	my $dashLen     = shift;
	my $gapLen      = shift;

	my $style = StrokeStyle->new( $strokeStyle, $strokeWidth, $strokeColor, $dashLen, $gapLen );

	$self->{"eStyles"}->{"top"}   = $style if ( $edge eq "top" );
	$self->{"eStyles"}->{"bot"}   = $style if ( $edge eq "bot" );
	$self->{"eStyles"}->{"left"}  = $style if ( $edge eq "left" );
	$self->{"eStyles"}->{"right"} = $style if ( $edge eq "right" );

}

sub GetTopEdgeStyle {
	my $self = shift;

	return $self->{"eStyles"}->{"top"};

}

sub GetBotEdgeStyle {
	my $self = shift;

	return $self->{"eStyles"}->{"bot"};

}

sub GetLeftEdgeStyle {
	my $self = shift;

	return $self->{"eStyles"}->{"left"};

}

sub GetRightEdgeStyle {
	my $self = shift;

	return $self->{"eStyles"}->{"right"};

}

sub GetAllEdgesStyle {
	my $self = shift;

	return %{ $self->{"eStyles"} };
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

