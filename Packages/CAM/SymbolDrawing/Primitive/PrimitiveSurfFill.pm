
#-------------------------------------------------------------------------------------------#
# Description: Class which represent primitive geometric - surface created by fill profile
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::SymbolDrawing::Primitive::PrimitiveSurfFill;
use base ("Packages::CAM::SymbolDrawing::Primitive::PrimitiveBase");

use Class::Interface;

&implements('Packages::CAM::SymbolDrawing::Primitive::IPrimitive');
#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::CAM::SymbolDrawing::Enums';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::Helper::SurfaceSolidPattern';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $class    = shift;
	my $pattern  = shift;
	my $marginX  = shift;
	my $marginY  = shift;
	my $srMarginX = shift;
	my $srMarginY = shift;
	my $considerFeat  = shift;
	my $featMargin  = shift;
	my $polarity = shift;    #
 
 
	my $self = {};
	$self = $class->SUPER::new( Enums->Primitive_SURFACEFILL, $polarity );
	bless $self;

	$self->{"pattern"}  = $pattern;
 
	$self->{"marginX"}  = $marginX;
	$self->{"marginY"} = $marginY;
	$self->{"SRMarginX"}  = $srMarginX;
	$self->{"SRMarginY"} = $srMarginY;
	$self->{"considerFeat"} = $considerFeat;
	$self->{"featMargin"} = $featMargin;
	 
 	unless(defined $pattern){
 		$pattern = "solid";
 	}
 

	return $self;
}

sub MirrorY {
	my $self = shift;
 	die "Mirror Y is not implemented"; 
}

sub MirrorX {
	my $self = shift;
 	die "Mirror X is not implemented"; 
}
 

sub GetPattern {
	my $self = shift;

	return $self->{"pattern"};
}

sub GetPatternParams {
	my $self = shift;

	return $self->{"patternParams"};
}

sub GetMarginX {
	my $self = shift;

	return $self->{"marginX"};
}

sub GetMarginY {
	my $self = shift;

	return $self->{"marginY"};
}

sub GetSRMarginX {
	my $self = shift;

	return $self->{"SRMarginX"};
}

sub GetSRMarginY {
	my $self = shift;

	return $self->{"SRMarginY"};
}

sub GetConsiderFeat {
	my $self = shift;

	return $self->{"considerFeat"};
}

sub GetFeatMargin {
	my $self = shift;

	return $self->{"featMargin"};
}

 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

