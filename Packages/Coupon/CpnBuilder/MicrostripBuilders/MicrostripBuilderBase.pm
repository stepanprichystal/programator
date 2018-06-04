
#-------------------------------------------------------------------------------------------#
# Description: Base class for BIF builders. Nif Builder is responsible for
# creation nif file depend on pcb type
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Coupon::CpnBuilder::MicrostripBuilders::MicrostripBuilderBase;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::CAM::SymbolDrawing::Point';
use aliased 'Packages::Coupon::CpnBuilder::CpnLayout::MicrostripLayout';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"}     = undef;
	$self->{"jobId"}     = undef;
	$self->{"settings"}  = undef;
	$self->{"constrain"} = undef;
 
	$self->{"layout"}    = MicrostripLayout->new();
	$self->{"padPosCnt"} = undef;                     # number of pad postitions placed horizontally side by side (1 or two) in probe measure area

	$self->{"layers"} = [];

	return $self;
}

sub Init {
	my $self = shift;

	$self->{"inCAM"}     = shift;
	$self->{"jobId"}     = shift;
	$self->{"settings"}  = shift;
	$self->{"constrain"} = shift;

	# Set microstrip layout properties common for all microstrip types
	
	$self->{"layout"}->SetModel( $self->{"constrain"}->GetModel() );    # model

	# Get info about layers + translate to inCAM name notation
	my $cpnSource = $self->{"constrain"}->GetCpnSource();
	$self->{"layout"}->SetTrackLayer( $cpnSource->GetInCAMLayer( $self->{"constrain"}->GetOption("TRACE_LAYER") ) );            #
	$self->{"layout"}->SetTopRefLayer( $cpnSource->GetInCAMLayer( $self->{"constrain"}->GetOption("TOP_MODEL_LAYER") ) );       #
	$self->{"layout"}->SetBotRefLayer( $cpnSource->GetInCAMLayer( $self->{"constrain"}->GetOption("BOTTOM_MODEL_LAYER") ) );    #

}

sub GetPadPositionsCnt {
	my $self = shift;

	return $self->{"padPosCnt"};
}

sub GetHeight {
	my $self = shift;

	return $self->{"height"};
}

sub GetLayout {
	my $self = shift;

	return $self->{"layout"};

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

