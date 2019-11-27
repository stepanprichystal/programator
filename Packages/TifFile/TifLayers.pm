
#-------------------------------------------------------------------------------------------#
# Description: TifFile - interface for signal layers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::TifFile::TifLayers;
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

	$self->{"keySig"} = "signalLayers";
	$self->{"keyOth"} = "otherLayers";

	return $self;
}

sub GetLayer {
	my $self  = shift;
	my $lName = shift;

	my $lTIF = undef;

	# a) Firstly look at signal layers
	my %sigLayers = $self->GetSignalLayers();
	$lTIF = $sigLayers{$lName} if ( defined $sigLayers{$lName} );

	# b) Secondly look at oter layers
	my %othLayers = $self->GetOtherLayers();
	$lTIF = $othLayers{$lName} if ( defined $othLayers{$lName} );

	return $lTIF;
}

sub GetSignalLayers {
	my $self = shift;

	my $layers = $self->{"tifData"}->{ $self->{"keySig"} };

	if ( defined $layers ) {
		return %{$layers};
	}
	else {

		my %h;
		return {};
	}
}

sub SetSignalLayers {
	my $self   = shift;
	my $layers = shift;

	$self->{"tifData"}->{ $self->{"keySig"} } = $layers;

	$self->_Save();
}

sub GetOtherLayers {
	my $self = shift;

	my $layers = $self->{"tifData"}->{ $self->{"keyOth"} };

	if ( defined $layers ) {
		return %{$layers};
	}
	else {

		my %h;
		return %h;
	}

}

sub SetOtherLayers {
	my $self   = shift;
	my $layers = shift;

	$self->{"tifData"}->{ $self->{"keyOth"} } = $layers;

	$self->_Save();
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

