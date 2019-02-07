
#-------------------------------------------------------------------------------------------#
# Description: Parsed InStack constrain
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::InStackJob::Constraint;

#3th party library
use strict;
use warnings;

#local library
use XML::LibXML;
use aliased 'Packages::CAM::InStackJob::Helper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"layerCnt"}      = shift;
	$self->{"units"}         = shift;
	$self->{"id"}            = shift;    # unique id from STACKUP_ORDERING_INDEX
	$self->{"type"}          = shift;
	$self->{"model"}         = shift;
	$self->{"xmlConstraint"} = shift;

	return $self;
}

sub GetId {
	my $self = shift;

	return $self->{"id"};
}

sub GetType {
	my $self = shift;

	return $self->{"type"};
}

sub GetModel {
	my $self = shift;

	return $self->{"model"};
}

sub GetTrackLayer {
	my $self = shift;
	my $inCAMLayers = shift // 0;    # if 1, InStack layer name will be convert to standard InCAM layer name

	return Helper->GetInCAMLayer( $self->GetOption("TRACE_LAYER"), $self->{"layerCnt"} ) if ($inCAMLayers);
	return $self->GetOption("TRACE_LAYER");
}

sub GetTopRefLayer {
	my $self = shift;
	my $inCAMLayers = shift // 0;    # if 1, InStack layer name will be convert to standard InCAM layer name

	return Helper->GetInCAMLayer( $self->GetOption("TOP_MODEL_LAYER"), $self->{"layerCnt"} ) if ($inCAMLayers);
	return $self->GetOption("TOP_MODEL_LAYER");
}

sub GetBotRefLayer {
	my $self = shift;
	my $inCAMLayers = shift // 0;    # if 1, InStack layer name will be convert to standard InCAM layer name

	return Helper->GetInCAMLayer( $self->GetOption("BOTTOM_MODEL_LAYER"), $self->{"layerCnt"} ) if ($inCAMLayers);
	return $self->GetOption("BOTTOM_MODEL_LAYER");
}

sub GetTrackExtraLayer {
	my $self = shift;
	my $inCAMLayers = shift // 0;    # if 1, InStack layer name will be convert to standard InCAM layer name

	return Helper->GetInCAMLayer( $self->GetOption("EXTRA_SIGNAL_LAYER"), $self->{"layerCnt"} ) if ($inCAMLayers);
	return $self->GetOption("EXTRA_SIGNAL_LAYER");
}

sub GetOption {
	my $self = shift;
	my $name = shift;
	my $considerUnit = shift; # if 1, value will be converted to defined units

	my $val = $self->{"xmlConstraint"}->{"$name"};
	
	if ( $considerUnit && $self->{"units"} eq "mm" ) {
		$val *= 25.4;
	}

	return $val;

}

sub GetParamDouble {
	my $self = shift;
	my $name = shift;

	my $att = ( grep { $_->{"NAME"} eq $name } $self->{"xmlConstraint"}->findnodes('./PARAMS/IMPEDANCE_CONSTRAINT_PARAMETER') )[0];
	die "Attribute doesnt exist $name." unless ($att);

	my $val = $att->getAttribute('DOUBLE_VALUE');    # space

	if ( $self->{"units"} eq "mm" ) {

		$val *= 25.4;
	}

	return $val;

}

sub ExistsParam {
	my $self = shift;
	my $name = shift;

	my $par = ( grep { $_->{"NAME"} eq $name } $self->{"xmlConstraint"}->findnodes('./PARAMS/IMPEDANCE_CONSTRAINT_PARAMETER') )[0];

	if ( defined $par ) {
		return 1;
	}
	else {
		return 0;
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

