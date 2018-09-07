
#-------------------------------------------------------------------------------------------#
# Description: TifFile - interface for NC operations
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::TifFile::TifNCOperations;
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

	$self->{"key"} = "NCOperations";

	return $self;
}

sub AddMachines {
	my $self     = shift;
	my @machines = @{ shift(@_) };

	foreach my $m (@machines) {

		$self->{"tifData"}->{ $self->{"key"} }->{$m} = {};
	}

}

sub AddOperations {
	my $self = shift;
	my $opName = shift;
	my $opLayers = shift;
	 

}

#sub GetSignalLayers {
#	my $self = shift;
#
#	my $layers = $self->{"tifData"}->{ $self->{"key"} };
#
#	if ( defined $layers ) {
#		return %{$layers};
#	}
#	else {
#
#		my %h;
#		return %h;
#	}
#
#}
#
#sub SetSignalLayers {
#	my $self   = shift;
#	my $layers = shift;
#
#	$self->{"tifData"}->{ $self->{"key"} } = $layers;
#
#	$self->_Save();
#}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

