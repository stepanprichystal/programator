#-------------------------------------------------------------------------------------------#
# Description: BBuilder for rigid core lamination
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::ProcessStackup::LamItemBuilders::BuilderRIGIDBASE;
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

	# Pad info
	my $steelPlateInf = $stckpMngr->GetSteelPlateInfo();
	my $filmInf       = $stckpMngr->GetReleaseFilmPacoViaInfo();

	# LAYER: Steel plate top
	$lam->AddItem( "steelPlate", Enums->ItemType_PADSTEEL, undef, undef, undef, undef, $steelPlateInf->{"thick"} );

	# LAYER: Top release film
	$lam->AddItem( $filmInf->{"ISRef"}, Enums->ItemType_PADFILM, EnumsStyle->GetItemTitle( Enums->ItemType_PADFILM ),
				   undef, undef, $filmInf->{"text"}, $filmInf->{"thick"} );

	# MATERIAL LAYERS
	my $pInput = $lam->GetLamData();

	foreach my $pLayer ( $pInput->GetLayers() ) {

		if ( $pLayer->GetType() eq StackEnums->ProductL_MATERIAL ) {

			$self->_ProcessStckpMatLayer( $lam, $stckpMngr, $pLayer->GetData() );
		}
		elsif ( $pLayer->GetType() eq StackEnums->ProductL_PRODUCT ) {

			foreach my $pChildL ( $pLayer->GetData()->GetLayers() ) {

				$self->_ProcessStckpMatLayer( $lam, $stckpMngr, $pChildL->GetData() );
			}

		}

	}

	# LAYER: Bot release film
	$lam->AddItem( $filmInf->{"ISRef"}, Enums->ItemType_PADFILM, EnumsStyle->GetItemTitle( Enums->ItemType_PADFILM ),
				   undef, undef, $filmInf->{"text"}, $filmInf->{"thick"} );

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

