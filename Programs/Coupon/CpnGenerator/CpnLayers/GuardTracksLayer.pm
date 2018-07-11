
#-------------------------------------------------------------------------------------------#
# Description: Base class for BIF builders. Nif Builder is responsible for
# creation nif file depend on pcb type
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnGenerator::CpnLayers::GuardTracksLayer;

use base('Programs::Coupon::CpnGenerator::CpnLayers::LayerBase');

#use Class::Interface;
#&implements('Programs::Coupon::CpnBuilder::MicrostripBuilders::IModelBuilder');

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
	my $self            = shift;
	my $layout          = shift;    # microstrip layout
	my $cpnSingleLayout = shift;    # cpn single layout

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# Draw pad clearance
	if ( $layout->GetType() eq "single" ) {

		foreach my $line ( $layout->GetLines() ) {

			my $l =
			  PrimitiveLine->new( $line->{"startP"}, $line->{"endP"},
								  "s" . ( $layout->GetGuardTrackWidth() + $layout->GetGuardTrack2Shielding() ),
								  DrawEnums->Polar_NEGATIVE );
			$self->{"drawing"}->AddPrimitive($l);

		}

	}
	elsif ( $layout->GetType() eq "full" ) {

		foreach my $area ( $layout->GetAreas() ) {

			my %areaNeg = ();
			$areaNeg{"xMin"} = $area->{"xMin"} - $layout->GetGuardTrack2Shielding() / 1000;
			$areaNeg{"xMax"} = $area->{"xMax"} + $layout->GetGuardTrack2Shielding() / 1000;
			$areaNeg{"yMin"} = $area->{"yMin"} - $layout->GetGuardTrack2Shielding() / 1000;
			$areaNeg{"yMax"} = $area->{"yMax"} + $layout->GetGuardTrack2Shielding() / 1000;

			$self->{"drawing"}->AddPrimitive( PrimitiveSurfPoly->new( \%areaNeg, undef, DrawEnums->Polar_NEGATIVE ) );

		}
	}

	# draw sielding
	if ( $layout->GetType() eq "single" ) {

		foreach my $line ( $layout->GetLines() ) {

			my $l =
			  PrimitiveLine->new( $line->{"startP"}, $line->{"endP"}, "s" . $layout->GetGuardTrackWidth(), DrawEnums->Polar_POSITIVE );
			$self->{"drawing"}->AddPrimitive($l);

		}

	}
	elsif ( $layout->GetType() eq "full" ) {

		foreach my $area ( $layout->GetAreas() ) {

			$self->{"drawing"}->AddPrimitive( PrimitiveSurfPoly->new( $area, undef, DrawEnums->Polar_POSITIVE ) );

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

