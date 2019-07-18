
#-------------------------------------------------------------------------------------------#
# Description: Bend area contains:
# - reference to 2 transition zones
# - features which crates whole bend area
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::FlexiLayers::CoverlayPinParser::PinBendArea;

#3th party library
use strict;
use warnings;
use List::MoreUtils qw(uniq);

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

	$self->{"features"} = shift;
	return $self;
}

sub GetFeatures {
	my $self = shift;
	return @{ $self->{"features"} };
}

# Return array of pin
# Each pin contain features (side_pin_line, end_pin_line, register_pin, cut_pin, solder_pin)
# Features of specific pin has same value of grou_feat_id attribute
sub GetPinsFeatures {
	my $self = shift;

	my @feature = grep {defined $_->{"att"}->{"feat_group_id"} }  @{ $self->{"features"} };

	my @featGroupId = uniq( map { $_->{"att"}->{"feat_group_id"} } @feature);

	my @pinsFeats = ();

	foreach my $featGroupId (@featGroupId) {

		my @feats = grep { $_->{"att"}->{"feat_group_id"} eq $featGroupId } @feature ;

		push( @pinsFeats, \@feats );
	}

	return @pinsFeats;

}

# Return number of pin in bend area
sub GetPinCnt {
	my $self = shift;

	my @feature = grep {defined $_->{"att"}->{"feat_group_id"} }  @{ $self->{"features"} };

	my @featGroupId = uniq( map { $_->{"att"}->{"feat_group_id"} } @feature);

	return scalar(@featGroupId);

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

