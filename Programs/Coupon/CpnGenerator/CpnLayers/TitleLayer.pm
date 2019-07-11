
#-------------------------------------------------------------------------------------------#
# Description: Layer builder
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnGenerator::CpnLayers::TitleLayer;

use base('Programs::Coupon::CpnGenerator::CpnLayers::LayerBase');

use Class::Interface;
&implements('Programs::Coupon::CpnGenerator::CpnLayers::ILayerBuilder');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::CAM::SymbolDrawing::SymbolDrawing';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveText';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitivePad';
use aliased 'Packages::CAM::SymbolDrawing::Point';
use aliased 'CamHelpers::CamLayer';
use aliased 'Programs::Coupon::Enums';
use aliased 'Packages::CAM::SymbolDrawing::Enums' => 'DrawEnums';

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
	my $self   = shift;
	my $layout = shift;    # title layout
	my $cpnSingleLayout = shift;    # cpn single layout

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	#my $origin = $layout->GetPosition();

	my $angle = 0;
	$angle = 90 if ( $layout->GetType() eq "left" );

	# draw logo

	# compute scale of logo. InCAM logo is height 3.6mm
	my $logoPos = $layout->GetLogoPosition();
	my $scaleX   = $layout->GetLogoWidth() / $layout->GetLogoSymbolWidth();
	my $scaleY   = $layout->GetLogoHeight() / $layout->GetLogoSymbolHeight();
 
	my $logo = PrimitivePad->new( $layout->GetLogoSymbol(), $layout->GetLogoPosition(),
								  0, DrawEnums->Polar_POSITIVE, $angle, 0, $scaleX, $scaleX );
	$self->{"drawing"}->AddPrimitive($logo);

	# Draw job id

	my $jobIdPos = $layout->GetJobIdPosition();

	my $pText = PrimitiveText->new(
									$layout->GetJobIdVal(),
									$layout->GetJobIdPosition(),
									$layout->GetTitleTextHeight() / 1000,
									$layout->GetTitleTextWidth() / 1000,
									$layout->GetTitleTextWeight() / 1000,
									0,
									$angle
	);
	
	$pText->AddAttribute(".n_electric");

	$self->{"drawing"}->AddPrimitive($pText);
 

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

