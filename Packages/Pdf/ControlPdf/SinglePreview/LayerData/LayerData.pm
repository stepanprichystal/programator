#-------------------------------------------------------------------------------------------#
# Description: Special structure, contain data of exported layer
# type of layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::SinglePreview::LayerData::LayerData;

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

	$self->{"type"} = shift;

	$self->{"enTit"} = shift; # titles
	$self->{"czTit"} = shift;
	$self->{"enInf"} = shift; # description
	$self->{"czInf"} = shift;

	$self->{"output"} = undef;

	my @l = ();
	$self->{"singleLayers"} = \@l; # physic single layers, which will be merged in export layer

	return $self;
}

sub GetType {
	my $self = shift;

	return $self->{"type"};
}

sub GetOutputLayer {
	my $self = shift;

	return $self->{"output"};
}

sub SetOutputLayer {
	my $self  = shift;
	my $lName = shift;

	$self->{"output"} = $lName;
}

sub AddSingleLayer {
	my $self = shift;
	my $l    = shift;

	push( @{ $self->{"singleLayers"} }, $l );
}

sub GetSingleLayers {
	my $self = shift;
	return @{ $self->{"singleLayers"} };
}

sub GetTitle {
	my $self = shift;
	my $lang = shift;

	if ( $lang eq "cz" ) {

		return $self->{"czTit"};

	}
	elsif ( $lang eq "en" ) {

		return $self->{"enTit"};
	}

}

sub GetInfo {
	my $self = shift;
	my $lang = shift;

	if ( $lang eq "cz" ) {

		return $self->{"czInf"};

	}
	elsif ( $lang eq "en" ) {

		return $self->{"enInf"};
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

