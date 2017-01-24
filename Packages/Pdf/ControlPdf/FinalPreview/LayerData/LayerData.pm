
#-------------------------------------------------------------------------------------------#
# This sctructure contain information: type of layer: mask, silk, copeer etc...
# Amd Which layer merge
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::FinalPreview::LayerData::LayerData;

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

	$self->{"type"}         = shift;
	$self->{"order"}        = undef;
	$self->{"surface"}      = undef;
	$self->{"output"}       = undef;

	my @l = ();
	$self->{"singleLayers"} = \@l;

	return $self;
}

sub PrintLayer {
	my $self = shift;

	if ( $self->{"output"} ) {

		return 1;
	}
	else {

		return 0;
	}

}

sub GetSurface {
	my $self = shift;

	return $self->{"surface"};
}

sub SetSurface {
	my $self = shift;

	$self->{"surface"} = shift;
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
	my $self    = shift;
	my $singleL = shift;

	push( @{ $self->{"singleLayers"} }, $singleL );
}

sub GetSingleLayers {
	my $self = shift;
	return @{ $self->{"singleLayers"} };
}

sub HasLayers {
	my $self = shift;
	scalar( @{ $self->{"singleLayers"} } );
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

