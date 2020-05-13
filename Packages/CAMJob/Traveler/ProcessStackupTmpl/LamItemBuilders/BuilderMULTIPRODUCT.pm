#-------------------------------------------------------------------------------------------#
# Description: Builder for stiffener lamination
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Traveler::ProcessStackupTmpl::LamItemBuilders::BuilderMULTIPRODUCT;
use base('Packages::CAMJob::Traveler::ProcessStackupTmpl::LamItemBuilders::LamItemBuilderBase');

#3th party library
use strict;
use warnings;
use List::Util qw(first);

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAMJob::Traveler::ProcessStackupTmpl::Enums';
use aliased 'Packages::CAMJob::Traveler::ProcessStackupTmpl::EnumsStyle';


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
	my $presspadInf = $stckpMngr->GetPresspad5500Info();
	my $releaseInf  = $stckpMngr->GetReleaseFilm1500HTInfo();

	# LAYER: Steel plate top
	$lam->AddItem( "steelPlate", Enums->ItemType_PADSTEEL, undef, undef, undef, undef, $steelPlateInf->{"thick"} );

	# LAYER: Top presspad
	$lam->AddItem( $presspadInf->{"ISRef"},
				   Enums->ItemType_PADPAPER, EnumsStyle->GetItemTitle( Enums->ItemType_PADPAPER ),
				   undef, undef,
				   $presspadInf->{"text"},
				   $presspadInf->{"thick"} );

	# LAYER: Top release film
	$lam->AddItem( $releaseInf->{"ISRef"},
				   Enums->ItemType_PADFILM, EnumsStyle->GetItemTitle( Enums->ItemType_PADFILM ),
				   undef, undef, $releaseInf->{"text"}, $releaseInf->{"thick"} );

	# LAYER: Top Stiffener

	my $stiffTopInfo = {};
	if ( $stckpMngr->GetExistStiff( "top", $stiffTopInfo ) ) {

		my $item = $lam->AddItem(
								  $stiffTopInfo->{"stiffISRef"}, Enums->ItemType_MATSTIFFENER,
								   EnumsStyle->GetItemTitle( Enums->ItemType_MATSTIFFENER ),
								  undef,                         $stiffTopInfo->{"stiffKind"},
								  $stiffTopInfo->{"stiffText"},  $stiffTopInfo->{"stiffThick"}
		);
		$lam->AddChildItem( $item, "bot",
							$stiffTopInfo->{"adhesiveISRef"},
							Enums->ItemType_MATADHESIVE,
							EnumsStyle->GetItemTitle( Enums->ItemType_MATADHESIVE ),
							undef,
							$stiffTopInfo->{"adhesiveKind"},
							$stiffTopInfo->{"adhesiveText"},
							$stiffTopInfo->{"adhesiveThick"} );

	}

	# LAYER: product
	my $curProducNum = ($lam->GetProductId() =~ /^P(\d+)$/i)[0];
	my $product = ($curProducNum-1) < 1 ? "" : "P".($curProducNum-1);
 
	my $item = $lam->AddItem( "product",
							  Enums->ItemType_MATPRODUCTDPS,
							  EnumsStyle->GetItemTitle( Enums->ItemType_MATPRODUCTDPS ),$product, undef, undef, $stckpMngr->GetThick( 1, 0 ) );

	$lam->AddChildItem( $item, "top", "productTop", Enums->ItemType_MATPRODUCTDPS, "TOP", undef, undef, undef, undef );
	$lam->AddChildItem( $item, "bot", "productBot", Enums->ItemType_MATPRODUCTDPS, "BOT", undef, undef, undef, undef );

	# LAYER: top Stiffener adhesive
	my $stiffBotInfo = {};
	if ( $stckpMngr->GetExistStiff( "bot", $stiffBotInfo ) ) {

		my $item = $lam->AddItem( $stiffBotInfo->{"stiffISRef"},
								  Enums->ItemType_MATSTIFFENER,
								  EnumsStyle->GetItemTitle( Enums->ItemType_MATSTIFFENER ),
								  undef,
								  $stiffBotInfo->{"stiffKind"},
								  $stiffBotInfo->{"stiffText"},
								  $stiffBotInfo->{"stiffThick"} );
		$lam->AddChildItem( $item, "top",
							$stiffBotInfo->{"adhesiveISRef"},
							Enums->ItemType_MATADHESIVE,
							EnumsStyle->GetItemTitle( Enums->ItemType_MATADHESIVE ),
							undef,
							$stiffBotInfo->{"adhesiveKind"},
							$stiffBotInfo->{"adhesiveText"},
							$stiffBotInfo->{"adhesiveThick"} );

	}

	# LAYER: Bot release film
	$lam->AddItem( $releaseInf->{"ISRef"},
				   Enums->ItemType_PADFILM, EnumsStyle->GetItemTitle( Enums->ItemType_PADFILM ),
				   undef, undef, $releaseInf->{"text"}, $releaseInf->{"thick"} );

	# LAYER: Bot presspad
	$lam->AddItem( $presspadInf->{"ISRef"},
				   Enums->ItemType_PADPAPER, EnumsStyle->GetItemTitle( Enums->ItemType_PADPAPER ),
				   undef, undef,
				   $presspadInf->{"text"},
				   $presspadInf->{"thick"} );

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

