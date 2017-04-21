
#-------------------------------------------------------------------------------------------#
# Description: Label for pcb in pool
#
#  _ F12345
# |
#
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::PoolMerge::MergeGroup::LabelSym;
use base ("Packages::CAM::SymbolDrawing::Symbol::SymbolBase");

use Class::Interface;

&implements('Packages::CAM::SymbolDrawing::Symbol::ISymbol');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::CAM::SymbolDrawing::Enums';
use aliased 'Packages::CAM::SymbolDrawing::Point';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveLine';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveText';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $class     = shift;
	my $labelText = shift;    # number of pcb
	my $bot       = shift;    # mirror Y
	my $rotation  = shift;    # rotation 90 CCW
	my $maxWidth = shift; # max width of label, label is dynamic depand on this value (mm)

	my $polarity = undef;
	my $self     = {};
	$self = $class->SUPER::new($polarity);
	bless $self;

	$self->{"labelText"} = $labelText;
	$self->{"bot"}       = $bot;
	$self->{"rotation"}  = $rotation;
	$self->{"maxWidth"}  = $maxWidth;

	$self->__DefineSymbol();

	return $self;
}

sub __DefineSymbol {
	my $self = shift;

	# get size of arrw in x,y

	my $l1  = undef;
	my $l2  = undef;
	my $txt = undef;
 
 	my $charW = 2.35;
	# standard lenght is 2.35 8 number of char + 3.5mm line
	my $stadardW = (length($self->{"labelText"}) * 2.35) + 3.5;
	
	
	# compute new char width
	if($stadardW > $self->{"maxWidth"}){
		
		$charW =  ($self->{"maxWidth"} - 3.5)/length($self->{"labelText"});
	}
	
	if ( !$self->{"rotation"} && !$self->{"bot"} ) {
		
		$l1 = PrimitiveLine->new( Point->new( 0, 0.3 ), Point->new( 0,   3.1 ), "r300" );
		$l2 = PrimitiveLine->new( Point->new( 0, 3.1 ), Point->new( 2.8, 3.1 ), "r300" );
		$txt = PrimitiveText->new( $self->{"labelText"}, Point->new( 3.5, 1.95 ), $charW, 1 );
	}
	elsif ( $self->{"rotation"} && !$self->{"bot"} ) {
		
		$l1 = PrimitiveLine->new( Point->new( -0.3 , 0 ), Point->new( -3.1,  0 ), "r300" );
		$l2 = PrimitiveLine->new( Point->new( -3.1, 0 ), Point->new( -3.1, 2.8 ), "r300" );
		$txt = PrimitiveText->new( $self->{"labelText"}, Point->new( -1.95, 3.5 ), $charW, 1, 0, 90 );

	}
	elsif ( !$self->{"rotation"} && $self->{"bot"} ) {

		$l1 = PrimitiveLine->new( Point->new( 0, 0.3 ), Point->new( 0,   3.1 ), "r300" );
		$l2 = PrimitiveLine->new( Point->new( 0, 3.1 ), Point->new( -2.8, 3.1 ), "r300" );
		$txt = PrimitiveText->new( $self->{"labelText"}, Point->new( -3.5, 1.95 ), $charW, 1, 1, 0);
	}
	elsif ( $self->{"rotation"} && $self->{"bot"} ) {

		$l1 = PrimitiveLine->new( Point->new( 0.3, 0 ), Point->new( 3.1,  0 ), "r300" );
		$l2 = PrimitiveLine->new( Point->new( 3.1, 0 ), Point->new( 3.1, 2.8 ), "r300" );
		$txt = PrimitiveText->new( $self->{"labelText"}, Point->new( 1.95, 3.5 ), $charW, 1, 1, 90 );
	}

	$self->AddPrimitive($l1);
	$self->AddPrimitive($l2);
	$self->AddPrimitive($txt);

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

