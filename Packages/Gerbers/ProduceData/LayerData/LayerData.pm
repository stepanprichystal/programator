
#-------------------------------------------------------------------------------------------#
# Description: Structure contain information about prepared job layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Gerbers::ProduceData::LayerData::LayerData;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::CAMJob::OutputData::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"type"}       = shift;
	$self->{"name"}       = shift;    # physic name of file
	$self->{"nameSuffix"} = shift;    # when more file has same name, add ordefr number which distinguish this

	$self->{"title"}  = shift;        # description of layer
	$self->{"info"}   = shift;        # extra info of layer
	$self->{"output"} = shift;        # name of prepared layer in matrix

	# Property for type Type_DRILLMAP

	$self->{"parent"} = undef;        # layer, which drill map is based on

	return $self;
}

sub GetType {
	my $self = shift;

	return $self->{"type"};
}

sub GetName {
	my $self = shift;

	my $name = "";

	if ( $self->{"type"} eq Enums->Type_DRILLMAP && $self->{"parent"} ) {

		$name = $self->{"parent"}->GetName() . "_map";
	}
	else {
		if ( $self->{"nameSuffix"} > 0 ) {

			$name = $self->{"name"} . "_" . $self->{"nameSuffix"};
		}
		else {

			$name = $self->{"name"};
		}
	}

}

sub GetTitle {
	my $self = shift;

	my $tit = "";

	if ( $self->{"type"} eq Enums->Type_DRILLMAP && $self->{"parent"} ) {

		$tit .= "Drill map for: " . $self->{"parent"}->GetName() . ".ger";
	}
	else {

		$tit = $self->{"title"};
	}

	return $tit;
}

sub GetInfo {
	my $self = shift;

	my $inf = "";

	if ( $self->{"type"} eq Enums->Type_DRILLMAP && $self->{"parent"} ) {

		$inf = "";
	}
	else {

		$inf = $self->{"info"};
	}

	return $inf;

}

sub SetOutput {
	my $self = shift;

	$self->{"output"} = shift;
}

sub GetOutput {
	my $self = shift;

	return $self->{"output"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

