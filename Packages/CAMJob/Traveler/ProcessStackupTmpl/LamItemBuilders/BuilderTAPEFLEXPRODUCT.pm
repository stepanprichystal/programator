#-------------------------------------------------------------------------------------------#
# Description: Builder for tape lamination on flex
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Traveler::ProcessStackupTmpl::LamItemBuilders::BuilderTAPEFLEXPRODUCT;
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
	my $rubberPadInf  = $stckpMngr->GetPressPadYOMFLEX200Info();

	# LAYER: Steel plate top
	$lam->AddItem( "steelPlate", Enums->ItemType_PADSTEEL, undef, undef, undef, undef, $steelPlateInf->{"thick"} );

	# LAYER: Top Stiffener

	my $tapeTopInfo = {};
	my $tapeTop     = $stckpMngr->GetExistTapeFlex( "top", $tapeTopInfo );
	my $tapeBotInfo = {};
	my $tapeBot     = $stckpMngr->GetExistTapeFlex( "bot", $tapeBotInfo );

	# LAYER: Top rubber pad
	$lam->AddItem( $rubberPadInf->{"ISRef"},
				   Enums->ItemType_PADRUBBERBROWN,
				   EnumsStyle->GetItemTitle( Enums->ItemType_PADRUBBERBROWN ),
				   undef, undef,
				   $rubberPadInf->{"text"},
				   $rubberPadInf->{"thick"} );

	if ($tapeTop) {

		my $item = $lam->AddItem(
								  $tapeTopInfo->{"tapeISRef"},
								  Enums->ItemType_MATTAPE,
								  EnumsStyle->GetItemTitle( Enums->ItemType_MATTAPE ),
								  undef,
								  undef,
								  $tapeTopInfo->{"tapeText"},
								  $tapeTopInfo->{"tapeThick"}
		);

		#		$lam->AddChildItem(
		#							$item,                                                        "bot",
		#							$stiffTopInfo->{"adhesiveISRef"},                             Enums->ItemType_MATSTIFFADHESIVE,
		#							EnumsStyle->GetItemTitle( Enums->ItemType_MATSTIFFADHESIVE ), undef,
		#							$stiffTopInfo->{"adhesiveKind"},                              $stiffTopInfo->{"adhesiveText"},
		#							$stiffTopInfo->{"adhesiveThick"}
		#		);

	}

	# LAYER: product
	my $curProducNum = ( $lam->GetProductId() =~ /^P(\d+)$/i )[0];
	my $product = ( $curProducNum - 1 ) < 1 ? "" : "P" . ( $curProducNum - 1 );

	my $item = $lam->AddItem( "product",
							  Enums->ItemType_MATPRODUCTDPS,
							  EnumsStyle->GetItemTitle( Enums->ItemType_MATPRODUCTDPS ),
							  $product, undef, undef, $stckpMngr->GetThick( 1, 0 ) );

	$lam->AddChildItem( $item, "top", "productTop", Enums->ItemType_MATPRODUCTDPS, "TOP", undef, undef, undef, undef );
	$lam->AddChildItem( $item, "bot", "productBot", Enums->ItemType_MATPRODUCTDPS, "BOT", undef, undef, undef, undef );

	# LAYER: top Stiffener adhesive

	if ($tapeBot) {

		my $item = $lam->AddItem( $tapeBotInfo->{"tpISRef"},
								  Enums->ItemType_MATTAPE, EnumsStyle->GetItemTitle( Enums->ItemType_MATTAPE ),
								  undef, undef,
								  $tapeBotInfo->{"tpText"},
								  $tapeBotInfo->{"tpThick"} );

		#		$lam->AddChildItem(
		#							$item,                                                        "top",
		#							$stiffBotInfo->{"adhesiveISRef"},                             Enums->ItemType_MATSTIFFADHESIVE,
		#							EnumsStyle->GetItemTitle( Enums->ItemType_MATSTIFFADHESIVE ), undef,
		#							$stiffBotInfo->{"adhesiveKind"},                              $stiffBotInfo->{"adhesiveText"},
		#							$stiffBotInfo->{"adhesiveThick"}
		#		);

	}

	# LAYER: Bot rubber pad
	$lam->AddItem( $rubberPadInf->{"ISRef"},
				   Enums->ItemType_PADRUBBERBROWN,
				   EnumsStyle->GetItemTitle( Enums->ItemType_PADRUBBERBROWN ),
				   undef, undef,
				   $rubberPadInf->{"text"},
				   $rubberPadInf->{"thick"} );

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

