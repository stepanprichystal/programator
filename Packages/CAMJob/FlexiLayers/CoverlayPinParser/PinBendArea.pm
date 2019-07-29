
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
use aliased 'Packages::CAMJob::FlexiLayers::CoverlayPinParser::Enums';

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
# Each pin contain features (side_pin_line1 side_pin_line2, end_pin_line, register_pin, cut_pin, solder_pin)
# Features of specific pin has same value of grou_feat_id attribute
sub GetPinsFeatures {
	my $self = shift;

	my @feature = grep { defined $_->{"att"}->{"feat_group_id"} } @{ $self->{"features"} };

	my @featGroupId = uniq( map { $_->{"att"}->{"feat_group_id"} } @feature );

	my @pinsFeats = ();

	foreach my $featGroupId (@featGroupId) {

		my @feats = grep { $_->{"att"}->{"feat_group_id"} eq $featGroupId } @feature;

		push( @pinsFeats, \@feats );
	}

	return @pinsFeats;

}

# Return number of pin in bend area
sub GetPinCnt {
	my $self = shift;

	my @feature = grep { defined $_->{"att"}->{"feat_group_id"} } @{ $self->{"features"} };

	my @featGroupId = uniq( map { $_->{"att"}->{"feat_group_id"} } @feature );

	return scalar(@featGroupId);
}

# Each pin is marked by feat_group_id attribute. Return all values of this attribute
sub GetPinsGUID {
	my $self = shift;

	my @feature = grep { defined $_->{"att"}->{"feat_group_id"} } @{ $self->{"features"} };

	@feature = grep { $_->{"att"}->{".string"} eq Enums->PinString_ENDLINE } @feature;

	my @featGroupId = uniq( map { $_->{"att"}->{"feat_group_id"} } @feature );

	return @featGroupId;
}

# Return envelop points of pin (only features with .string att: PinString_SIDELINE2)
sub GetPinEnvelop {
	my $self    = shift;
	my $pinGUID = shift;

	my @feature = grep { defined $_->{"att"}->{"feat_group_id"} && $_->{"att"}->{"feat_group_id"} eq $pinGUID } @{ $self->{"features"} };

	my @sideLines = grep { $_->{"att"}->{".string"} eq Enums->PinString_SIDELINE2 } @feature;

	die " Pin \"Side lines\" count is not equal to two" if ( scalar(@sideLines) != 2 );

	my @envelop = ();
	push( @envelop, { "x" => $sideLines[0]->{"x1"}, "y" => $sideLines[0]->{"y1"} } );
	push( @envelop, { "x" => $sideLines[0]->{"x2"}, "y" => $sideLines[0]->{"y2"} } );
	push( @envelop, { "x" => $sideLines[1]->{"x1"}, "y" => $sideLines[1]->{"y1"} } );
	push( @envelop, { "x" => $sideLines[1]->{"x2"}, "y" => $sideLines[1]->{"y2"} } );

	return @envelop;
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

