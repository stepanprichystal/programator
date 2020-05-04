#-------------------------------------------------------------------------------------------#
# Description: Builder for inner rigid flex
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::ProcessStackupTempl::LamItemBuilders::BuilderORIGIDFLEXFINAL;
use base('Packages::CAMJob::Stackup::ProcessStackupTempl::LamItemBuilders::LamItemBuilderBase');

#3th party library
use strict;
use warnings;
use List::Util qw(first);

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAMJob::Stackup::ProcessStackupTempl::Enums';
use aliased 'Packages::CAMJob::Stackup::ProcessStackupTempl::EnumsStyle';
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

	# remove coverlay if exist (will be laminated in separate lamination)
	if ( $lam->GetLamData()->GetExistExtraPress() ) {

		for ( my $i = scalar(@pLayers) - 1 ; $i >= 0 ; $i-- ) {

			if (    $pLayers[$i]->GetType() eq StackEnums->ProductL_MATERIAL
				 && $pLayers[$i]->GetData()->GetType() eq StackEnums->MaterialType_COVERLAY )
			{
				splice @pLayers, $i, 1;
			}
		}
	}

	# Pad info
	my $steelPlateInf     = $stckpMngr->GetSteelPlateInfo();
	my $rubberThickPadInf = $stckpMngr->GetPressPadTB317KInfo();
	my $rubberThinPadInf  = $stckpMngr->GetPressPad01FGKInfo();
	my $aluPadInf         = $stckpMngr->GetAluPlateInfo();

	# LAYER: Steel plate top
	$lam->AddItem( "steelPlate", Enums->ItemType_PADSTEEL, undef, undef, undef, undef, $steelPlateInf->{"thick"} );

	if (    $pLayers[0]->GetType() eq StackEnums->ProductL_PRODUCT
		 && $pLayers[0]->GetData()->GetProductType() eq StackEnums->Product_INPUT
		 && $pLayers[0]->GetData()->GetCoreRigidType() eq StackEnums->CoreType_FLEX )
	{
		# LAYER: Top rubber pad
		$lam->AddItem( $rubberThinPadInf->{"ISRef"},
					   Enums->ItemType_PADRUBBER, EnumsStyle->GetItemTitle( Enums->ItemType_PADRUBBER ),
					   undef, undef,
					   $rubberThinPadInf->{"text"},
					   $rubberThinPadInf->{"thick"} );

		# LAYER: Top alu pad
		$lam->AddItem( $aluPadInf->{"ISRef"}, Enums->ItemType_PADALU, EnumsStyle->GetItemTitle( Enums->ItemType_PADALU ),
					   undef, undef, $aluPadInf->{"text"}, $aluPadInf->{"thick"} );
	}
	else {
		# LAYER: Top rubber pad
		$lam->AddItem( $rubberThickPadInf->{"ISRef"},
					   Enums->ItemType_PADRUBBER, EnumsStyle->GetItemTitle( Enums->ItemType_PADRUBBER ),
					   undef, undef,
					   $rubberThickPadInf->{"text"},
					   $rubberThickPadInf->{"thick"} );
	}

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
			else {

				$self->_ProcessStckpProduct( $lam, $stckpMngr, $IProduct );

			}
		}
	}

	if (    $pLayers[-1]->GetType() eq StackEnums->ProductL_PRODUCT
		 && $pLayers[-1]->GetData()->GetProductType() eq StackEnums->Product_INPUT
		 && $pLayers[-1]->GetData()->GetCoreRigidType() eq StackEnums->CoreType_FLEX )
	{

		# LAYER: Bot alu pad
		$lam->AddItem( $aluPadInf->{"ISRef"}, Enums->ItemType_PADALU, EnumsStyle->GetItemTitle( Enums->ItemType_PADALU ),
					   undef, undef, $aluPadInf->{"text"}, $aluPadInf->{"thick"} );

		# LAYER: Bot rubber pad
		$lam->AddItem( $rubberThinPadInf->{"ISRef"},
					   Enums->ItemType_PADRUBBER, EnumsStyle->GetItemTitle( Enums->ItemType_PADRUBBER ),
					   undef, undef,
					   $rubberThinPadInf->{"text"},
					   $rubberThinPadInf->{"thick"} );

	}
	else {

		# LAYER: Top rubber pad
		$lam->AddItem( $rubberThickPadInf->{"ISRef"},
					   Enums->ItemType_PADRUBBER, EnumsStyle->GetItemTitle( Enums->ItemType_PADRUBBER ),
					   undef, undef,
					   $rubberThickPadInf->{"text"},
					   $rubberThickPadInf->{"thick"} );
	}

	# LAYER: Steel plate Bot
	$lam->AddItem( "steelPlate", Enums->ItemType_PADSTEEL, undef, undef, undef, undef, $steelPlateInf->{"thick"} );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
