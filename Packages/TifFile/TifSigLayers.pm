
#-------------------------------------------------------------------------------------------#
# Description: TifFile - interface for signal layers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::TifFile::TifSigLayers;
use base ('Packages::TifFile::TifFile::TifFile');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	$self = $class->SUPER::new(@_);
	bless $self;

	$self->{"key"} = "signalLayers";

	return $self;
}

sub GetSignalLayers {
	my $self = shift;

	my $layers = $self->{"tifData"}->{ $self->{"key"} };

	if ( defined $layers ) {
		return %{$layers};
	}
	else {

		my %h;
		return %h;
	}

}

sub SetSignalLayers {
	my $self   = shift;
	my $layers = shift;

	$self->{"tifData"}->{ $self->{"key"} } = $layers;

	$self->_Save();
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

