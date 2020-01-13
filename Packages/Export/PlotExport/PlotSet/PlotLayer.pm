#-------------------------------------------------------------------------------------------#
# Description: Wrapper for operations connected with inCam attributes
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Packages::Export::PlotExport::PlotSet::PlotLayer;

#3th party library
use strict;
use warnings;

#local library

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};

	bless $self;

	$self->{"name"}         = shift;
	$self->{"polarity"}     = shift;
	$self->{"mirror"}       = shift;
	$self->{"compensation"} = shift;
	$self->{"stretchX"}     = shift;
	$self->{"stretchY"}     = shift;
	$self->{"pcbSize"}      = shift;
	$self->{"pcbLimits"}    = shift;    # limits by frmames (big/small) taken from layer c
	                                    # Helper propery, when create opfx

	$self->{"outputLayer"} = undef;     #name of final output layer, contain rotated, mirrored, comp data

	return $self;
}

sub GetName {
	my $self = shift;

	return $self->{"name"};

}

sub GetComp {
	my $self = shift;

	return $self->{"compensation"};

}

sub Mirror {
	my $self = shift;

	return $self->{"mirror"};

}

sub GetPolarity {
	my $self = shift;

	return $self->{"polarity"};

}

sub GetStretchX {
	my $self = shift;

	return $self->{"stretchX"};

}

sub GetStretchY {
	my $self = shift;

	return $self->{"stretchY"};

}

sub GetWidth {
	my $self = shift;

	return $self->{"pcbSize"}->{"xSize"};
}

sub GetHeight {
	my $self = shift;

	return $self->{"pcbSize"}->{"ySize"};
}

sub GetLimits {
	my $self = shift;

	return $self->{"pcbLimits"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#my $self             = shift;
	#	my $inCAM            = shift;

	#use aliased 'HelperScripts::DirStructure';

	#DirStructure->Create();

}

1;
