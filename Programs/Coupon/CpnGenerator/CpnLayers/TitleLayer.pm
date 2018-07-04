
#-------------------------------------------------------------------------------------------#
# Description: Base class for BIF builders. Nif Builder is responsible for
# creation nif file depend on pcb type
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnGenerator::CpnLayers::TitleLayer;

use base('Programs::Coupon::CpnGenerator::CpnLayers::LayerBase');

#use Class::Interface;
#&implements('Programs::Coupon::CpnBuilder::MicrostripBuilders::IModelBuilder');

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
	my $layout = shift;    # microstrip layout

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	#my $origin = $layout->GetPosition();

	my $angle = 0;
	$angle = 90 if ( $layout->GetType() eq "left" );

	# draw logo

	# compute scale of logo. InCAM logo is height 3.6mm
	my $logoPos = $layout->GetLogoPosition();
	my $scaleX   = $self->{"settings"}->GetLogoWidth() / $self->{"settings"}->GetLogoSymbolWidth();
	my $scaleY   = $self->{"settings"}->GetLogoHeight() / $self->{"settings"}->GetLogoSymbolHeight();
 
	my $logo = PrimitivePad->new( $self->{"settings"}->GetLogoSymbol(), $layout->GetLogoPosition(),
								  0, DrawEnums->Polar_POSITIVE, $angle, 0, $scaleX, $scaleX );
	$self->{"drawing"}->AddPrimitive($logo);

	# Draw job id

	my $jobIdPos = $layout->GetJobIdPosition();

	my $pText = PrimitiveText->new(
									$layout->GetJobIdVal(),
									$layout->GetJobIdPosition(),
									$self->{"settings"}->GetTitleTextHeight() / 1000,
									$self->{"settings"}->GetTitleTextWidth() / 1000,
									$self->{"settings"}->GetTitleTextWeight() / 1000,
									0,
									$angle
	);

	$self->{"drawing"}->AddPrimitive($pText);
 

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

