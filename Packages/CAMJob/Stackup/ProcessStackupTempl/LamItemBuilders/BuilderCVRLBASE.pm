#-------------------------------------------------------------------------------------------#
# Description: Builder for cvrlener lamination
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::ProcessStackupTempl::LamItemBuilders::BuilderCVRLBASE;
use base('Packages::CAMJob::Stackup::ProcessStackupTempl::LamItemBuilders::LamItemBuilderBase');

#3th party library
use strict;
use warnings;
use List::Util qw(first);

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAMJob::Stackup::ProcessStackupTempl::Enums';
use aliased 'Packages::CAMJob::Stackup::ProcessStackupTempl::EnumsStyle';

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

	# Pads info
	my $steelPlateInf = $stckpMngr->GetSteelPlateInfo();

	my $filmInf           = $stckpMngr->GetFilmPacoflexUltraInfo();
	my $releaseInf        = $stckpMngr->GetReleaseFilm1500HTInfo();
	my $presspadInf       = $stckpMngr->GetPresspad5500Info();
	#my $filmInf     = $stckpMngr->GetFilmPacoplus4500Info();

	# Coverlays info
	my $cvrlTopInfo  = {};
	my $cvrlTopExist = $stckpMngr->GetExistCvrl( "top", $cvrlTopInfo );
	my $cvrlBotInfo  = {};
	my $cvrlBotExist = $stckpMngr->GetExistCvrl( "bot", $cvrlBotInfo );

	# LAYER: Steel plate top
	$lam->AddItem( "steelPlate", Enums->ItemType_PADSTEEL, undef, undef, undef, undef, $steelPlateInf->{"thick"} );

	# LAYER: Top outer release film
	$lam->AddItem( $releaseInf->{"ISRef"},
				   Enums->ItemType_PADRELEASE,
				   EnumsStyle->GetItemTitle( Enums->ItemType_PADRELEASE ),
				   undef, undef, $releaseInf->{"text"}, $releaseInf->{"thick"} );

	if ($cvrlTopExist) {
 

		# LAYER: Top paper pad
		$lam->AddItem( $presspadInf->{"ISRef"},
					   Enums->ItemType_PADPAPER, EnumsStyle->GetItemTitle( Enums->ItemType_PADPAPER ),
					   undef, undef,
					   $presspadInf->{"text"},
					   $presspadInf->{"thick"} );

		# LAYER: Top film pad
		my $filmItem = $lam->AddItem( $filmInf->{"ISRef"}, Enums->ItemType_PADFILM, EnumsStyle->GetItemTitle( Enums->ItemType_PADFILM ),
									  undef, undef, $filmInf->{"text"}, $filmInf->{"thick"} );
		$lam->AddChildItem( $filmItem, "top", $filmInf->{"ISRef"}, Enums->ItemType_PADFILMGLOSS, "Lesk", undef, undef, undef, 0 );
		$lam->AddChildItem( $filmItem, "bot", $filmInf->{"ISRef"}, Enums->ItemType_PADFILMMATT,  "Mat",  undef, undef, undef, 0 );

		# LAYER: Top cvrlener

		my $item = $lam->AddItem( $cvrlTopInfo->{"cvrlISRef"},
								  Enums->ItemType_MATCOVERLAY,
								  EnumsStyle->GetItemTitle( Enums->ItemType_MATCOVERLAY ),
								  "C",
								  $cvrlTopInfo->{"cvrlKind"},
								  $cvrlTopInfo->{"cvrlText"},
								  $cvrlTopInfo->{"cvrlThick"} );
		$lam->AddChildItem( $item, "bot",
							$cvrlTopInfo->{"cvrlISRef"},
							Enums->ItemType_MATCVRLADHESIVE,
							EnumsStyle->GetItemTitle( Enums->ItemType_MATCVRLADHESIVE ),
							undef,
							$cvrlTopInfo->{"adhesiveKind"},
							$cvrlTopInfo->{"adhesiveText"},
							$cvrlTopInfo->{"adhesiveThick"} );

	}

	# LAYER: core
	my $coreType = $stckpMngr->GetIsFlex() ? Enums->ItemType_MATFLEXCORE : Enums->ItemType_MATCORE;

	my $item =
	  $lam->AddItem( "core", $coreType, EnumsStyle->GetItemTitle($coreType), undef, undef, undef, $stckpMngr->GetThick( 0, 0 ) );
	$lam->AddChildItem( $item, "top", "coreCuTop", Enums->ItemType_MATCUCORE,  EnumsStyle->GetItemTitle(Enums->ItemType_MATCUCORE), "c", undef, undef, undef );
	$lam->AddChildItem( $item, "bot", "coreCuBot", Enums->ItemType_MATCUCORE,  EnumsStyle->GetItemTitle(Enums->ItemType_MATCUCORE), "s", undef, undef, undef );

	# LAYER: top cvrlener adhesive

	if ($cvrlBotExist) {

		my $item = $lam->AddItem( $cvrlBotInfo->{"cvrlISRef"},
								  Enums->ItemType_MATCOVERLAY,
								  EnumsStyle->GetItemTitle( Enums->ItemType_MATCOVERLAY ),
								  "S",
								  $cvrlBotInfo->{"cvrlKind"},
								  $cvrlBotInfo->{"cvrlText"},
								  $cvrlBotInfo->{"cvrlThick"} );
		$lam->AddChildItem( $item, "top",
							$cvrlBotInfo->{"cvrlISRef"},
							Enums->ItemType_MATCVRLADHESIVE,
							EnumsStyle->GetItemTitle( Enums->ItemType_MATCVRLADHESIVE ),
							undef,
							$cvrlBotInfo->{"adhesiveKind"},
							$cvrlBotInfo->{"adhesiveText"},
							$cvrlBotInfo->{"adhesiveThick"} );

		# LAYER: Bot film pad
		my $filmItem = $lam->AddItem( $filmInf->{"ISRef"}, Enums->ItemType_PADFILM, EnumsStyle->GetItemTitle( Enums->ItemType_PADFILM ),
									  undef, undef, $filmInf->{"text"}, $filmInf->{"thick"} );
		$lam->AddChildItem( $filmItem, "top", $filmInf->{"ISRef"}, Enums->ItemType_PADFILMMATT,  "Mat",  undef, undef, undef, 0 );
		$lam->AddChildItem( $filmItem, "bot", $filmInf->{"ISRef"}, Enums->ItemType_PADFILMGLOSS, "Lesk", undef, undef, undef, 0 );

		# LAYER: Bot paper pad
		$lam->AddItem( $presspadInf->{"ISRef"},
					   Enums->ItemType_PADPAPER, EnumsStyle->GetItemTitle( Enums->ItemType_PADPAPER ),
					   undef, undef,
					   $presspadInf->{"text"},
					   $presspadInf->{"thick"} );

	}

	# LAYER: Bot outer release film
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

