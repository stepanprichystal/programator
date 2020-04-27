#-------------------------------------------------------------------------------------------#
# Description: Builder for flex core lamination (coverlay; noflow prepreg)
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::ProcessStackup::LamItemBuilders::BuilderFLEXBASE;
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
	my $rubberPadInf  = $stckpMngr->GetPressPadFF10NInfo();
	my $filmInf       = $stckpMngr->GetReleaseFilmPacoViaInfo();

	my $cvrlTopInfo = {};

	my $prpgTopExist = $pLayers[0]->GetType() eq StackEnums->ProductL_MATERIAL
	  && $pLayers[0]->GetData()->GetType() eq StackEnums->MaterialType_PREPREG ? 1 : 0;

	my $prpgBotExist = $pLayers[-1]->GetType() eq StackEnums->ProductL_MATERIAL
	  && $pLayers[-1]->GetData()->GetType() eq StackEnums->MaterialType_PREPREG ? 1 : 0;

	#	my $cvrlTopExist = $prpgTopExist && $pLayers[0]->GetIsNoFlow() && $pLayers[0]->GetIsCoverlayIncl() ? 1 : 0;
	#	my $cvrlBotExist = $prpgTopExist && $pLayers[-1]->GetIsNoFlow() && $pLayers[-1]->GetIsCoverlayIncl() ? 1 : 0;

	# $stckpMngr->GetExistCvrl( "top", $cvrlTopInfo );
	#my $cvrlBotInfo  = {};
	#my $cvrlBotExist = $stckpMngr->GetExistCvrl( "bot", $cvrlBotInfo );

	# LAYER: Steel plate top
	$lam->AddItem( "steelPlate", Enums->ItemType_PADSTEEL, undef, undef, undef, undef, $steelPlateInf->{"thick"} );

	if ($prpgTopExist) {

		# LAYER: Top rubber pad
		$lam->AddItem( $rubberPadInf->{"ISRef"},
					   Enums->ItemType_PADRUBBER, EnumsStyle->GetItemTitle( Enums->ItemType_PADRUBBER ),
					   undef, undef,
					   $rubberPadInf->{"text"},
					   $rubberPadInf->{"thick"} );

	}

	# LAYER: Top release film
	$lam->AddItem( $filmInf->{"ISRef"}, Enums->ItemType_PADFILM, EnumsStyle->GetItemTitle( Enums->ItemType_PADFILM ),
				   undef, undef, $filmInf->{"text"}, $filmInf->{"thick"} );

	# MATERIAL LAYERS

	foreach my $pLayer (@pLayers) {

		if ( $pLayer->GetType() eq StackEnums->ProductL_MATERIAL ) {

			if (    $pLayer->GetType() eq StackEnums->ProductL_MATERIAL
				 && $pLayer->GetData()->GetType() eq StackEnums->MaterialType_PREPREG
				 && $pLayer->GetData()->GetIsNoFlow()
				 && $pLayer->GetData()->GetIsCoverlayIncl() )
			{

				$self->_ProcessStckpMatLayer( $lam, $stckpMngr, $pLayer->GetData()->GetCoverlay() );

			}

			$self->_ProcessStckpMatLayer( $lam, $stckpMngr, $pLayer->GetData() );
		}
		elsif ( $pLayer->GetType() eq StackEnums->ProductL_PRODUCT ) {

			my @layers = map { $_->GetData() } $pLayer->GetData()->GetLayers();

			my $coreL = first { $_->GetType() eq StackEnums->MaterialType_CORE } @layers;

			$self->_ProcessStckpMatLayer( $lam, $stckpMngr, $coreL );
		}
	}

	# LAYER: Bot release film
	$lam->AddItem( $filmInf->{"ISRef"}, Enums->ItemType_PADFILM, EnumsStyle->GetItemTitle( Enums->ItemType_PADFILM ),
				   undef, undef, $filmInf->{"text"}, $filmInf->{"thick"} );

	if ($prpgBotExist) {

		# LAYER: Top rubber pad
		$lam->AddItem( $rubberPadInf->{"ISRef"},
					   Enums->ItemType_PADRUBBER, EnumsStyle->GetItemTitle( Enums->ItemType_PADRUBBER ),
					   undef, undef,
					   $rubberPadInf->{"text"},
					   $rubberPadInf->{"thick"} );

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
