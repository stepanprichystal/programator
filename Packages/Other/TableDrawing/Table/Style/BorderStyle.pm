
#-------------------------------------------------------------------------------------------#
# Description: Interface, allow build nif section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Other::TableDrawing::Table::Style::BorderStyle;

#3th party library
use strict;
use warnings;

#use File::Copy;

#local library
use aliased 'Packages::Other::TableDrawing::Enums';
use aliased 'Packages::Other::TableDrawing::Table::Style::Color';
use aliased 'Packages::Other::TableDrawing::Table::Style::StrokeStyle';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"eStyles"} = {};

	$self->{"eStyles"}->{"top"}   = shift;
	$self->{"eStyles"}->{"bot"}   = shift;
	$self->{"eStyles"}->{"left"}  = shift;
	$self->{"eStyles"}->{"right"} = shift;

	return $self;
}

sub AddEdgeStyle {
	my $self        = shift;
	my $edge        = shift;    #top/bot/left/right
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

	return %{$self->{"eStyles"}};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

