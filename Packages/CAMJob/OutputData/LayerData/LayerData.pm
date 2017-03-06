
#-------------------------------------------------------------------------------------------#
# Description: Structure contain information about prepared job layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::OutputData::LayerData::LayerData;

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

	$self->{"type"}     = shift;    # type of Packages::Gerbers::OutputData::Enums
	$self->{"oriLayer"} = shift;    # ori matrix layer

	$self->{"enTit"} = shift;       # titles
	$self->{"czTit"} = shift;
	$self->{"enInf"} = shift;       # description
	$self->{"czInf"} = shift;

	$self->{"output"} = shift;      # name of prepared layer in matrix

	# Property for type Type_DRILLMAP

	$self->{"parent"} = undef;      # layer, which drill map is based on

	return $self;
}

sub SetOutput {
	my $self = shift;

	$self->{"output"} = shift;
}

sub GetOutput {
	my $self = shift;

	return $self->{"output"};
}

sub GetType {
	my $self = shift;

	return $self->{"type"};
}

sub GetOriLayer {
	my $self = shift;

	return $self->{"oriLayer"};
}

sub GetNumber {
	my $self = shift;

	return $self->{"number"}

}

sub GetTitle {
	my $self = shift;
	my $lang   = shift;

	if ($lang eq "cz") {
		return $self->{"czTit"};
	}
	elsif($lang eq "en") {

		return $self->{"enTit"};
	}
}

sub GetInfo {
	my $self = shift;
	my $lang   = shift;

	if ($lang eq "cz") {
		return $self->{"czInf"};
	}
	elsif($lang eq "en") {

		return $self->{"enInf"};
	}
}

sub SetParent {
	my $self = shift;

	$self->{"parent"} = shift;
}

sub GetParent {
	my $self = shift;

	return $self->{"parent"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

