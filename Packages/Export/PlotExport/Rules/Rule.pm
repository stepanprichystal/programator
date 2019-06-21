#-------------------------------------------------------------------------------------------#
# Description: Structure which keep inforamtion about possible type od layers, which can be
# placed on one opfx film
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Packages::Export::PlotExport::Rules::Rule;

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

	$self->{"orientation"} = shift;           # orientation of layers on film horoyontal/verticall
	$self->{"layerPlotOnce"} = shift // 0;    # if 1 layer can by plotted more than once (in manz rule sets)

	my @layerTypes = ();
	$self->{"layerTypes"} = \@layerTypes;     # one or more types of layer, which can be merged in one film

	return $self;
}

#
sub AddSingleTypes {

	my $self = shift;
	@{ $self->{"layerTypes"} } = @_;

}

sub AddType1 {

	my $self  = shift;
	my @types = @{ shift(@_) };

	unless ( scalar(@types) ) {

		return 0;
	}

	push( $self->{"layerTypes"}, \@types );
}

sub AddType2 {

	my $self  = shift;
	my @types = @{ shift(@_) };

	unless ( scalar(@types) ) {

		return 0;
	}

	push( $self->{"layerTypes"}, \@types );
}

sub AddTypes {

	my $self  = shift;
	my @types = @{ shift(@_) };

	unless ( scalar(@types) ) {

		return 0;
	}

	push( $self->{"layerTypes"}, \@types );
}

sub GetLayerTypes {
	my $self = shift;

	return @{ $self->{"layerTypes"} };

}

sub GetOrientation {
	my $self = shift;

	return $self->{"orientation"};

}

sub GetLayerPlotOnce {

	my $self = shift;

	return $self->{"layerPlotOnce"};
}

#1;

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
