#-------------------------------------------------------------------------------------------#
# Description: Builder for stiffener lamination
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Traveler::ProcessStackupTmpl::LamItemBuilders::BuilderCVRLPRODUCT;
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

	# Add extra layers - coverlays
#	my @extraPLayers = $lam->GetLamData()->GetExtraPressLayers();
#	die "No Extra coverlay press layer" unless ( scalar(@extraPLayers) );
#
#	foreach my $l (@extraPLayers) {
#
#		if ( $l->GetData()->GetCoveredCopperName() eq "c" ) {
#			unshift( @pLayers, $l );
#
#		}
#		elsif ( $l->GetData()->GetCoveredCopperName() eq "s" ) {
#			push( @pLayers, $l );
#		}
#
#	}

	# Pads info
	my $steelPlateInf     = $stckpMngr->GetSteelPlateInfo();
	my $filmInf           = $stckpMngr->GetFilmPacoflexUltraInfo();
	my $releaseInf        = $stckpMngr->GetReleaseFilm1500HTInfo();
	my $presspadInf       = $stckpMngr->GetPresspad5500Info();
	my $rubberThickPadInf = $stckpMngr->GetPressPadTB317KInfo();

	# Coverlays info
	my $cvrlTopInfo  = {};
	my $cvrlTopExist = $stckpMngr->GetExistCvrl( "top", $cvrlTopInfo );
	my $cvrlBotInfo  = {};
	my $cvrlBotExist = $stckpMngr->GetExistCvrl( "bot", $cvrlBotInfo );

	# LAYER: Steel plate top
	$lam->AddItem( "steelPlate", Enums->ItemType_PADSTEEL, undef, undef, undef, undef, $steelPlateInf->{"thick"} );

	if (    $pLayers[0]->GetType() eq StackEnums->ProductL_MATERIAL
		 && $pLayers[0]->GetData()->GetType() eq StackEnums->MaterialType_COVERLAY )
	{

		# LAYER: Top release paper
		$lam->AddItem( $releaseInf->{"ISRef"},
					   Enums->ItemType_PADRELEASE,
					   EnumsStyle->GetItemTitle( Enums->ItemType_PADRELEASE ),
					   undef, undef, $releaseInf->{"text"}, $releaseInf->{"thick"} );

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

		$self->_ProcessStckpMatLayer( $lam, $stckpMngr, $pLayers[0]->GetData() );
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

	$self->_ProcessStckpProduct( $lam, $stckpMngr, $lam->GetLamData() );

	if (    $pLayers[-1]->GetType() eq StackEnums->ProductL_MATERIAL
		 && $pLayers[-1]->GetData()->GetType() eq StackEnums->MaterialType_COVERLAY )
	{

		$self->_ProcessStckpMatLayer( $lam, $stckpMngr, $pLayers[-1]->GetData() );

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

		# LAYER: Bot release paper
		$lam->AddItem( $releaseInf->{"ISRef"},
					   Enums->ItemType_PADRELEASE,
					   EnumsStyle->GetItemTitle( Enums->ItemType_PADRELEASE ),
					   undef, undef, $releaseInf->{"text"}, $releaseInf->{"thick"} );

	}
	else {

		# LAYER: Bot rubber pad
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

