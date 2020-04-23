#-------------------------------------------------------------------------------------------#
# Description: Builder for standard multilayer  lamination
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::ProcessStackup::LamItemBuilders::BuilderRIGIDFINAL;
use base('Packages::CAMJob::Stackup::ProcessStackup::LamItemBuilders::LamItemBuilderBase');

#3th party library
use strict;
use warnings;
use List::Util qw(first);

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAMJob::Stackup::ProcessStackup::Enums';
use aliased 'Packages::CAMJob::Stackup::ProcessStackup::EnumsStyle';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';

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
	my $lam       = shift;
	my $stckpMngr = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @pLayers = $lam->GetLamData()->GetLayers();

	# Pad info
	my $steelPlateInf = $stckpMngr->GetSteelPlateInfo();
	my $rubberPadInf  = $stckpMngr->GetPressPad01FGKInfo();

	# LAYER: Top rubber pad
	$lam->AddItem( $rubberPadInf->{"ISRef"},
				   Enums->ItemType_PADRUBBER, EnumsStyle->GetItemTitle( Enums->ItemType_PADRUBBER ),
				   undef, undef,
				   $rubberPadInf->{"text"},
				   $rubberPadInf->{"thick"} );

	# LAYER: Steel plate top
	$lam->AddItem( "steelPlate", Enums->ItemType_PADSTEEL, undef, undef, undef, undef, $steelPlateInf->{"thick"} );

	# MATERIAL LAYERS

	foreach my $pLayer (@pLayers) {

		if ( $pLayer->GetType() eq StackEnums->ProductL_MATERIAL ) {

			$self->_ProcessStckpMatLayer( $lam, $stckpMngr, $pLayer->GetData() );
		}
		elsif ( $pLayer->GetType() eq StackEnums->ProductL_PRODUCT ) {

			my $IProduct = $pLayer->GetData();
			my @matL     = $pLayer->GetData()->GetLayers( StackEnums->ProductL_MATERIAL );

			if ( $IProduct->GetProductType() eq StackEnums->Product_INPUT && !@matL ) {

				# Process core (there should be only one core, else INPUT would be press )

				foreach my $pChildL ( ( $IProduct->GetChildProducts() )[0]->GetData()->GetLayers() ) {

					$self->_ProcessStckpMatLayer( $lam, $stckpMngr, $pChildL->GetData() );
				}

			}
			else{

				$self->_ProcessStckpProduct( $lam, $stckpMngr, $IProduct );

			}
		}
	}

	# LAYER: Steel plate Bot
	$lam->AddItem( "steelPlate", Enums->ItemType_PADSTEEL, undef, undef, undef, undef, $steelPlateInf->{"thick"} );

	# LAYER: Top rubber pad
	$lam->AddItem( $rubberPadInf->{"ISRef"},
				   Enums->ItemType_PADRUBBER, EnumsStyle->GetItemTitle( Enums->ItemType_PADRUBBER ),
				   undef, undef,
				   $rubberPadInf->{"text"},
				   $rubberPadInf->{"thick"} );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
