
#-------------------------------------------------------------------------------------------#
# Description: Bend area contains:
# - reference to 2 transition zones
# - features which crates whole bend area
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::FlexiLayers::BendAreaParser::BendArea;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Connectors::TpvConnector::TpvMethods';
use aliased 'Enums::EnumsDrill';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"features"}  = shift;
	$self->{"tranZones"} = shift;
	return $self;
}

sub GetTransitionZones {
	my $self = shift;

	return @{ $self->{"tranZones"} }

}

sub GetFeatures {
	my $self = shift;
	return @{ $self->{"features"} };
}

sub GetPoints {
	my $self = shift;

	my @polygonPoints = ();

	for ( my $i = 0 ; $i < scalar( @{ $self->{"features"} } ) ; $i++ ) {

		my $line = $self->{"features"}->[$i];

		my @arr = ( $line->{"x1"}, $line->{"y1"} );
		push( @polygonPoints, \@arr );

		if ( $i == scalar( @{ $self->{"features"} } ) - 1 ) {

			$line = $self->{"features"}->[0];
			my @arrEnd = ( $line->{"x1"}, $line->{"y1"} );
			push( @polygonPoints, \@arrEnd );
		}
	}

	return @polygonPoints;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

