#-------------------------------------------------------------------------------------------#
# Description: Base class of symbol. Contain common property like polarity, list of primitives
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::SymbolDrawing::Symbol::SymbolBase;

#3th party library
use strict;
use warnings;
use Storable qw(dclone);

#local library

use aliased 'Packages::CAM::SymbolDrawing::Enums';
use aliased 'Packages::CAM::SymbolDrawing::Point';
use aliased 'Packages::CAM::SymbolDrawing::SymbolInfo';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {

	my $self = shift;
	$self = {};
	bless $self;

	$self->{"polarity"} = shift;

	unless ( defined $self->{"polarity"} ) {
		$self->{"polarity"} = Enums->Polar_POSITIVE;
	}

	#$self->{"position"} = shift
	my @prims = ();
	$self->{"primitives"} = \@prims;    # primitives, whci create this symbol
	my @syms = ();
	$self->{"symbols"} = \@syms;        # can contain another chold symbols

	return $self;
}

sub AddPrimitive {
	my $self      = shift;
	my $primitive = shift;

	push( @{ $self->{"primitives"} }, $primitive );

}

sub AddSymbol {
	my $self     = shift;
	my $symbol   = shift;
	my $position = shift;

	push( @{ $self->{"symbols"} }, SymbolInfo->new( $symbol, $position ) );
}

sub GetPrimitives {
	my $self = shift;

	return @{ $self->{"primitives"} };

}

sub GetSymbols {
	my $self = shift;

	return @{ $self->{"symbols"} };

}

sub GetPolarity {
	my $self = shift;

	return $self->{"polarity"};

}

sub Copy {
	my $self = shift;

	return dclone($self);
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

