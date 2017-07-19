
#-------------------------------------------------------------------------------------------#
# This sctructure contain information: type of layer: mask, silk, copeer etc...
# Amd Which layer merge
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::StencilCreator::Forms::Layout::PasteData;

#3th party library
use strict;
use warnings;

#local library

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"w"}   = shift;
	$self->{"h"}  = shift;
	$self->{"rotated"} = 0;

	return $self;
}

sub GetWidth {
	my $self = shift;

	return $self->{"w"};

}

sub GetHeight {
	my $self = shift;

	return $self->{"h"};

}

# Switch width and height
sub SwitchDim {
	my $self = shift;

	if ( $self->{"rotated"} ) {
		$self->{"rotated"} = 0;
	}
	else {
		$self->{"rotated"} = 1;
	}

	( $self->{"w"}, $self->{"h"} ) = ( $self->{"h"}, $self->{"w"} )

}
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

