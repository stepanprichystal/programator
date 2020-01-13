
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
use List::Util qw(first);

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
	$self->{"pins"}     = shift;

	return $self;
}

sub GetFeatures {
	my $self = shift;
	return @{ $self->{"features"} };
}

# Return specific pin
sub GetPin {
	my $self    = shift;
	my $pinGUID = shift;

	my $pin = first { $_->GetGUID() eq $pinGUID } @{ $self->{"pins"} };

	return $pin;
}

# Return all pins
sub GetAllPins {
	my $self    = shift;
 
	return  @{ $self->{"pins"} };
}

# Return number of pin in bend area
sub GetPinsCnt {
	my $self        = shift;
	my $holderType  = shift;
	my $registerPad = shift;

	my @pins = @{ $self->{"pins"} };

	@pins = grep { $_->GetHolderType() eq $holderType } @pins   if ( defined $holderType );
	@pins = grep { $_->GetRegisterPad() eq $registerPad } @pins if ( defined $registerPad );

	return scalar(@pins);
}

# Each pin is marked by feat_group_id attribute. Return all values of this attribute
sub GetPinsGUID {
	my $self        = shift;
	my $holderType  = shift;
	my $registerPad = shift;

	my @pins = @{ $self->{"pins"} };

	@pins = grep { $_->GetHolderType() eq $holderType } @pins   if ( defined $holderType );
	@pins = grep { $_->GetRegisterPad() eq $registerPad } @pins if ( defined $registerPad );

	return map { $_->GetGUID() } @pins;
}

# Return array of points which form bend area polygon
# Polygon is closed: first point coonrdinate == last point
# Each point is defined by hash:
# - x; y       = coordinate of next point
# - xmid; ymid = coordinate of center of arc
# - dir        = direction of arc (cw/ccw) Enums->Dir_CW;Enums->Dir_CW
sub GetPoints {
	my $self = shift;

	my @polygonPoints = ();
	my @features      = $self->GetFeatures();

	# first point of polygon
	push( @polygonPoints, { "x" => $features[0]->{"x1"}, "y" => $features[0]->{"y1"} } );

	for ( my $i = 0 ; $i < scalar( @{ $self->{"features"} } ) ; $i++ ) {

		my $f = $self->{"features"}->[$i];

		my %p = ();
		$p{"x"} = $f->{"x2"};
		$p{"y"} = $f->{"y2"};
		if ( $f->{"type"} eq "A" ) {

			$p{"xmid"} = $f->{"xmid"};
			$p{"ymid"} = $f->{"ymid"};
			$p{"dir"}  = $f->{"newDir"};
		}

		push( @polygonPoints, \%p );
	}

	return @polygonPoints;
}

sub AddPin {
	my $self = shift;
	my $pin  = shift;

	push( @{ $self->{"pins"} }, $pin );
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

