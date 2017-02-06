
#-------------------------------------------------------------------------------------------#
# Description: Class can parse incam layer fetures. Parsed features, contain only
# basic info like coordinate, attrubutes etc..
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

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {

	my $self = shift;
	$self = {};
	bless $self;
	
	#$self->{"position"} = shift
	my @prims = ();
	$self->{"primitives"} = \@prims;  # primitives, whci create this symbol
	my @syms = ();
	$self->{"symbols"} = \@syms;	# can contain another chold symbols
 
	return $self;
}

 
sub AddPrimitive {
	my $self  = shift;
	my $primitive  = shift;
 
	 
	push( @{$self->{"primitives"}}, $primitive);

}


sub AddSymbol {
	my $self  = shift;
	my $symbol  = shift;
 
	 
	push( @{$self->{"symbols"}}, $symbol);

}  
 
sub GetPrimitives {
	my $self  = shift;
	 
	return @{$self->{"primitives"}};

}
 
sub GetSymbols {
	my $self  = shift;
	 
	return @{$self->{"symbols"}};

}


sub Copy{
	my $self  = shift;
 
	return dclone($self);
}



#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

