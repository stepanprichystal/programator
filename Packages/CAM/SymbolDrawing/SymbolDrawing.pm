
#-------------------------------------------------------------------------------------------#
# Description: Class can parse incam layer fetures. Parsed features, contain only
# basic info like coordinate, attrubutes etc..
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::SymbolDrawing::SymbolDrawing;

#3th party library
use strict;
use warnings;

#local library

use aliased 'Packages::CAM::SymbolDrawing::Enums';
use aliased 'CamHelpers::CamSymbol';
use aliased 'Packages::CAM::SymbolDrawing::Point';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {

	my $self = shift;

	$self = {};
	bless $self;

	$self->{"inCAM"}    = shift;
	$self->{"position"} = shift;

	unless ( $self->{"position"} ) {
		$self->{"position"} = Point->new();
	}

	my @syms = ();
	$self->{"symbols"} = \@syms;

	return $self;
}

sub AddSymbol {
	my $self = shift;
	my $sym  = shift;

	push( @{ $self->{"symbols"} }, $sym );

}

sub Draw {
	my $self = shift;

	# 1)  Get all primitives
	my @primitives = ();
	foreach my $s ( @{ $self->{"symbols"} } ) {

		$self->__GetPrimitives( $s, \@primitives );
	}

	# 2) Mirror X,Y if set
	#$self->Mirror()

	# 3) Draw primitives
	$self->__DrawPrimitives( \@primitives );

}

sub __DrawPrimitives {
	my $self       = shift;
	my @primitives = @{ shift(@_) };

	foreach my $p (@primitives) {

		my $t = $p->GetType();

		if ( $t eq Enums->Primitive_LINE ) {

			$self->__DrawLine($p);
		}

	}

}

sub __DrawLine {
	my $self = shift;
	my $line = shift;
 
	# consider origin of whole draw

	my $sP = $line->GetStartP();
	my $eP = $line->GetEndP();
	$sP->Move( $self->{"position"}->X(), $self->{"position"}->Y() );
	$eP->Move( $self->{"position"}->X(), $self->{"position"}->Y() );

	CamSymbol->AddLine( $self->{"inCAM"}, $sP, $eP, $line->GetSymbol(), $line->GetPolarity() );

}

sub __GetPrimitives {
	my $self       = shift;
	my $symbol     = shift;
	my $primitives = shift;

	my @childSymbols = $symbol->GetSymbols();

	if ( scalar(@childSymbols) ) {

		# recusive search another nested symbols
		foreach my $s (@childSymbols) {

			$self->__GetPrimitives( $s, $primitives );
		}

	}
	else {

		#get primitives
		push( @{$primitives}, $symbol->GetPrimitives() );
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {
	
	use aliased 'Packages::CAM::SymbolDrawing::SymbolDrawing';
	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Packages::CAM::SymbolDrawing::SymbolLib::DimVertical1';

	my $inCAM = InCAM->new();
	
	
	my $dim = DimVertical1->new(Point->new(0, 0), Point->new(0, -80), Point->new(0, 10), Point->new(0, -90), "r200");
	
	my $draw = SymbolDrawing->new($inCAM);
	$draw->AddSymbol($dim);
	$draw->Draw();

}

1;

