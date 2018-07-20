
#-------------------------------------------------------------------------------------------#
# Description: Layer builder
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnGenerator::CpnLayers::NegSignalLayer;

use base('Programs::Coupon::CpnGenerator::CpnLayers::LayerBase');

use Class::Interface;
&implements('Programs::Coupon::CpnGenerator::CpnLayers::ILayerBuilder');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::CAM::SymbolDrawing::SymbolDrawing';
use aliased 'CamHelpers::CamLayer';
use aliased 'Programs::Coupon::Enums';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveSurfFill';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveSurfPoly';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::Helper::SurfaceSolidPattern';
use aliased 'Packages::CAM::SymbolDrawing::Enums' => 'DrawEnums';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamFilter';

use aliased 'CamHelpers::CamSymbolSurf';
use aliased 'Packages::CAM::SymbolDrawing::Point';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	$self->{"surfFillGUID"} = undef;

	return $self;
}

sub Build {
	my $self = shift;
	my $margin = shift // 0;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	# add "break line" before GND filling which prevent to fill area where is place info text
	my $solidPattern = SurfaceSolidPattern->new( 0, 0 );

	my $p = PrimitiveSurfFill->new( $solidPattern, $margin, $margin, 0, 0, 1, 0, DrawEnums->Polar_POSITIVE );

	$self->{"surfFillGUID"} = $p->GetGroupGUID();

	$self->{"drawing"}->AddPrimitive($p);

}

sub MoveFillSurf {
	my $self = shift;
	my $back = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	if ( CamFilter->SelectBySingleAtt( $inCAM, $jobId, "feat_group_id", $self->{"surfFillGUID"} ) ) {

		my %lLim = CamJob->GetProfileLimits2( $inCAM, $jobId, $step );
		my %source;
		my %target;
		if ($back) {
			%source = ( "x" => 0, "y" => $lLim{"yMax"} );
			%target = ( "x" => 0, "y" => 0 );
		}
		else {
			%source = ( "x" => 0, "y" => 0 );
			%target = ( "x" => 0, "y" => $lLim{"yMax"} );
		}

		# move layer
		CamLayer->MoveSelSameLayer( $inCAM, $self->GetLayerName(), \%source, \%target );
	 
	}
	else {

		die "No positive surface fill (feat_group_id: " . $self->{"surfFillGUID"} . ") found in layer: " . $self->GetLayerName();
	}

}

sub MoveFillSurfBack {
	my $self = shift;

	$self->MoveFillSurf(1);

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

