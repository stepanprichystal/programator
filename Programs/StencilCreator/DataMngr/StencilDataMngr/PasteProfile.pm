
#-------------------------------------------------------------------------------------------#
# This sctructure contain information: type of layer: mask, silk, copeer etc...
# Amd Which layer merge
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::StencilCreator::DataMngr::StencilDataMngr::PasteProfile;

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

	$self->{"w"}       = shift;
	$self->{"h"}       = shift;
	$self->{"rotated"} = 0;

	$self->{"pasteData"}    = undef;
	$self->{"pdOri"} = undef;
	$self->{"pdSwitchOri"} = undef;

	return $self;
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

	( $self->{"w"}, $self->{"h"} ) = ( $self->{"h"}, $self->{"w"} );

	# rotate paste data if exist
	if ( $self->{"pasteData"} ) {

		$self->{"pasteData"}->SwitchDim();
		if ( $self->{"rotated"} ) {

		}
	}
}
sub GetPasteData {
	my $self      = shift;

	return $self->{"pasteData"};
}

# Set paste data obj plus origin of paste data
# origin inside paste data profile
sub SetPasteData {
	my $self      = shift;
	my $pasteData = shift;
	my $x         = shift;
	my $y         = shift;

	my %ori = ( "x" => $x, "y" => $y );

	$self->{"pasteData"} = $pasteData;
	$self->{"pdOri"}     = \%ori;

	my %switchOri = ( "y" => $self->{"w"} - ( $x + $pasteData->{"w"} ), "x" => $y );
	$self->{"pdSwitchOri"} = \%switchOri;
}



sub GetWidth {
	my $self = shift;

	return $self->{"w"};

}

sub GetHeight {
	my $self = shift;

	return $self->{"h"};

}

sub GetPDOrigin {
	my $self = shift;

	if ( $self->{"rotated"} ) {

		return  $self->{"pdSwitchOri"} ;

	}
	else {

		return  $self->{"pdOri"} ;
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

