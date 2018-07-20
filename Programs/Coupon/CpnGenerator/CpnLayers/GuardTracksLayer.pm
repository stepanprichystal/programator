
#-------------------------------------------------------------------------------------------#
# Description: Layer builder
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnGenerator::CpnLayers::GuardTracksLayer;

use base('Programs::Coupon::CpnGenerator::CpnLayers::LayerBase');

use Class::Interface;
&implements('Programs::Coupon::CpnGenerator::CpnLayers::ILayerBuilder');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::CAM::SymbolDrawing::SymbolDrawing';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveText';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveLine';
use aliased 'Packages::CAM::SymbolDrawing::Point';
use aliased 'CamHelpers::CamLayer';
use aliased 'Programs::Coupon::Enums';
use aliased 'Packages::CAM::SymbolDrawing::Enums' => 'DrawEnums';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveSurfPoly';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	return $self;
}

sub Build {
	my $self      = shift;
	my $layout    = shift;        # microstrip layout
	my $layerLayout     = shift;	# layer layout
	my $clearance = shift // 0;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# Draw pad clearance
	if ($clearance) {
		if ( $layout->GetType() eq "single_line" ) {

			foreach my $line ( $layout->GetLines() ) {

				my $l =
				  PrimitiveLine->new( $line->{"startP"}, $line->{"endP"},
									  "s" . ( $layout->GetGuardTrackWidth() + $layout->GetGuardTrack2Shielding() ),
									  $self->_InvertPolar(DrawEnums->Polar_NEGATIVE, $layerLayout) );
				$self->{"drawing"}->AddPrimitive($l);

			}

		}
		elsif ( $layout->GetType() eq "full" ) {

			foreach my $area ( $layout->GetAreas() ) {

				# area containc rectangle points LB LT RT RB
				# Move coordinate
				my @areaNeg = ();

				push( @areaNeg, $area->[0]->Copy() );
				push( @areaNeg, $area->[1]->Copy() );
				push( @areaNeg, $area->[2]->Copy() );
				push( @areaNeg, $area->[3]->Copy() );

				$areaNeg[0]->Move( -$layout->GetGuardTrack2Shielding() / 1000, -$layout->GetGuardTrack2Shielding() / 1000 );
				$areaNeg[1]->Move( -$layout->GetGuardTrack2Shielding() / 1000, $layout->GetGuardTrack2Shielding() / 1000 );
				$areaNeg[2]->Move( +$layout->GetGuardTrack2Shielding() / 1000, +$layout->GetGuardTrack2Shielding() / 1000 );
				$areaNeg[3]->Move( +$layout->GetGuardTrack2Shielding() / 1000, -$layout->GetGuardTrack2Shielding() / 1000 );

				$self->{"drawing"}->AddPrimitive( PrimitiveSurfPoly->new( $area, undef, $self->_InvertPolar(DrawEnums->Polar_NEGATIVE, $layerLayout) ) );

			}
		}
	}
	else {

		# draw sielding
		if ( $layout->GetType() eq "single_line" ) {

			foreach my $line ( $layout->GetLines() ) {

				my $l =
				  PrimitiveLine->new( $line->{"startP"}, $line->{"endP"}, "s" . $layout->GetGuardTrackWidth(), $self->_InvertPolar(DrawEnums->Polar_POSITIVE, $layerLayout) );
				$self->{"drawing"}->AddPrimitive($l);

			}

		}
		elsif ( $layout->GetType() eq "full" ) {

			foreach my $area ( $layout->GetAreas() ) {

				$self->{"drawing"}->AddPrimitive( PrimitiveSurfPoly->new( $area, undef, $self->_InvertPolar(DrawEnums->Polar_POSITIVE, $layerLayout) ) );

			}
		}
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

