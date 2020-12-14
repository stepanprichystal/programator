#-------------------------------------------------------------------------------------------#
# Description: Builder for flex core lamination (coverlay; noflow prepreg)
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Traveler::ProcessStackupTmpl::LamItemBuilders::BuilderFLEXBASE;
use base('Packages::CAMJob::Traveler::ProcessStackupTmpl::LamItemBuilders::LamItemBuilderBase');

#3th party library
use strict;
use warnings;
use List::Util qw(first);

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAMJob::Traveler::ProcessStackupTmpl::Enums';
use aliased 'Packages::CAMJob::Traveler::ProcessStackupTmpl::EnumsStyle';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';
use aliased 'Helpers::JobHelper';

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

	#my $rubberPadInf  = $stckpMngr->GetPressPadTB317KInfo();
	#my $filmInf       = $stckpMngr->GetReleaseFilmPacoViaInfo();

	my $filmInf     = $stckpMngr->GetFilmPacoplus4500Info();
	my $releaseInf  = $stckpMngr->GetReleaseFilm1500HTInfo();
	my $presspadInf = $stckpMngr->GetPresspad5500Info();

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

	#	# LAYER: Top rubber pad
	#	$lam->AddItem( $rubberPadInf->{"ISRef"},
	#				   Enums->ItemType_PADRUBBERPINK, EnumsStyle->GetItemTitle( Enums->ItemType_PADRUBBERPINK ),
	#				   undef, undef,
	#				   $rubberPadInf->{"text"},
	#				   $rubberPadInf->{"thick"} );
	#
	#	# LAYER: Top release film
	#	$lam->AddItem( $filmInf->{"ISRef"}, Enums->ItemType_PADFILM, EnumsStyle->GetItemTitle( Enums->ItemType_PADFILM ),
	#				   undef, undef, $filmInf->{"text"}, $filmInf->{"thick"} );

	#   Add pacothane sendwitch TEMPORARY UNTIL move to big panel, then flexpad + MSC

	$lam->AddItem( $releaseInf->{"ISRef"},
				   Enums->ItemType_PADRELEASE,
				   EnumsStyle->GetItemTitle( Enums->ItemType_PADRELEASE ),
				   undef, undef, $releaseInf->{"text"}, $releaseInf->{"thick"} );

	if ($prpgTopExist) {

		$lam->AddItem( $presspadInf->{"ISRef"},
					   Enums->ItemType_PADPAPER, EnumsStyle->GetItemTitle( Enums->ItemType_PADPAPER ),
					   undef, undef,
					   $presspadInf->{"text"},
					   $presspadInf->{"thick"} );

		$lam->AddItem( $filmInf->{"ISRef"}, Enums->ItemType_PADFILM, EnumsStyle->GetItemTitle( Enums->ItemType_PADFILM ),
					   undef, undef, $filmInf->{"text"}, $filmInf->{"thick"} );

	}

	# MATERIAL LAYERS

	foreach my $pLayer (@pLayers) {

		if ( $pLayer->GetType() eq StackEnums->ProductL_MATERIAL ) {

			my $coverlay     = undef;
			my $coverlaySide = undef;

			if (    $pLayer->GetType() eq StackEnums->ProductL_MATERIAL
				 && $pLayer->GetData()->GetType() eq StackEnums->MaterialType_PREPREG
				 && $pLayer->GetData()->GetIsNoFlow()
				 && $pLayer->GetData()->GetIsCoverlayIncl() )
			{

				$coverlay = $pLayer->GetData()->GetCoverlay();

			}

			if ( defined $coverlay ) {

				my $cuLayer = $coverlay->GetCoveredCopperName();

				my %lPars = JobHelper->ParseSignalLayerName($cuLayer);
				$coverlaySide =
				  $stckpMngr->GetStackup()->GetSideByCuLayer( $lPars{"sourceName"}, $lPars{"outerCore"}, $lPars{"plugging"} );

			}

			if ( defined $coverlay && $coverlaySide eq "top" ) {
				$self->_ProcessStckpMatLayer( $lam, $stckpMngr, $pLayer->GetData() );
				$self->_ProcessStckpMatLayer( $lam, $stckpMngr, $coverlay );

			}
			elsif ( defined $coverlay && $coverlaySide eq "bot" ) {

				$self->_ProcessStckpMatLayer( $lam, $stckpMngr, $coverlay );
				$self->_ProcessStckpMatLayer( $lam, $stckpMngr, $pLayer->GetData() );
			}
			else {
				$self->_ProcessStckpMatLayer( $lam, $stckpMngr, $pLayer->GetData() );
			}
		}
		elsif ( $pLayer->GetType() eq StackEnums->ProductL_PRODUCT ) {

			my @layers = map { $_->GetData() } $pLayer->GetData()->GetLayers();

			my $coreL = first { $_->GetType() eq StackEnums->MaterialType_CORE } @layers;

			$self->_ProcessStckpMatLayer( $lam, $stckpMngr, $coreL );
		}
	}

	#	# LAYER: Bot release film
	#	$lam->AddItem( $filmInf->{"ISRef"}, Enums->ItemType_PADFILM, EnumsStyle->GetItemTitle( Enums->ItemType_PADFILM ),
	#				   undef, undef, $filmInf->{"text"}, $filmInf->{"thick"} );
	#
	#	# LAYER: Top rubber pad
	#	$lam->AddItem( $rubberPadInf->{"ISRef"},
	#				   Enums->ItemType_PADRUBBERPINK, EnumsStyle->GetItemTitle( Enums->ItemType_PADRUBBERPINK ),
	#				   undef, undef,
	#				   $rubberPadInf->{"text"},
	#				   $rubberPadInf->{"thick"} );

	#   Add pacothane sendwitch TEMPORARY UNTIL move to big panel, then flexpad + MSC

	if ($prpgBotExist) {

		$lam->AddItem( $filmInf->{"ISRef"}, Enums->ItemType_PADFILM, EnumsStyle->GetItemTitle( Enums->ItemType_PADFILM ),
					   undef, undef, $filmInf->{"text"}, $filmInf->{"thick"} );

		$lam->AddItem( $presspadInf->{"ISRef"},
					   Enums->ItemType_PADPAPER, EnumsStyle->GetItemTitle( Enums->ItemType_PADPAPER ),
					   undef, undef,
					   $presspadInf->{"text"},
					   $presspadInf->{"thick"} );

	}

	$lam->AddItem( $releaseInf->{"ISRef"},
				   Enums->ItemType_PADRELEASE,
				   EnumsStyle->GetItemTitle( Enums->ItemType_PADRELEASE ),
				   undef, undef, $releaseInf->{"text"}, $releaseInf->{"thick"} );

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
