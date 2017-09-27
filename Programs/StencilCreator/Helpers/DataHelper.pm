
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::StencilCreator::Helpers::DataHelper;

#3th party library
use utf8;
use strict;
use warnings;
use List::Util qw[max min];
use List::MoreUtils qw(uniq);

#local library

use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamLayer';
use aliased 'Programs::StencilCreator::Enums';
use aliased 'CamHelpers::CamStep';
use aliased 'Programs::StencilCreator::Helpers::Helper';
use aliased 'Packages::Other::CustomerNote';
use aliased 'CamHelpers::CamStepRepeat';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}       = shift;
	$self->{"jobId"}       = shift;
	$self->{"dataMngr"}    = shift;
	$self->{"stencilMngr"} = shift;
	$self->{"stencilSrc"}  = shift;
	$self->{"jobIdSrc"}    = shift;

	my $custInfo = HegMethods->GetCustomerInfo( $self->{"jobId"} );
	$self->{"customerNote"} = CustomerNote->new( $custInfo->{"reference_subjektu"} );

	$self->{"isPool"} = 0;    # indicate if source is job if job is pool
	if ( $self->{"stencilSrc"} eq Enums->StencilSource_JOB && HegMethods->GetPcbIsPool( $self->{"jobIdSrc"} ) ) {
		$self->{"isPool"} = 1;
	}

	return $self;
}

sub SetSourceData {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# paste layer

	my $topLayer = Helper->GetStencilOriLayer( $inCAM, $jobId, "top" );
	my $botLayer = Helper->GetStencilOriLayer( $inCAM, $jobId, "bot" );

	# steps
	my @steps = grep { $_ =~ /^ori_/i } CamStep->GetAllStepNames( $inCAM, $jobId );

	# limits
	my %stepsSize = ();

	foreach my $stepName (@steps) {

		my %size = ();

		# 1) store step profile size
		my %profLim = CamJob->GetProfileLimits2( $inCAM, $jobId, $stepName );

		$size{"w"} = abs( $profLim{"xMax"} - $profLim{"xMin"} );
		$size{"h"} = abs( $profLim{"yMax"} - $profLim{"yMin"} );

		# store layer data size for sa..., sb... layers
		if ($topLayer) {

			# limits of paste data
			my %layerLim = CamJob->GetLayerLimits2( $inCAM, $jobId, $stepName, $topLayer->{"gROWname"} );
			my %dataSize = ();
			$dataSize{"w"} = abs( $layerLim{"xMax"} - $layerLim{"xMin"} );
			$dataSize{"h"} = abs( $layerLim{"yMax"} - $layerLim{"yMin"} );

			# position of paste data within paste profile
			$dataSize{"x"} = $layerLim{"xMin"} - $profLim{"xMin"};
			$dataSize{"y"} = $layerLim{"yMin"} - $profLim{"yMin"};

			$size{"top"} = \%dataSize;
		}
		if ($botLayer) {

			# bot normal
			# limits of paste data
			my %layerLim = CamJob->GetLayerLimits2( $inCAM, $jobId, $stepName, $botLayer->{"gROWname"} );
			my %dataSize = ();
			$dataSize{"w"} = abs( $layerLim{"xMax"} - $layerLim{"xMin"} );
			$dataSize{"h"} = abs( $layerLim{"yMax"} - $layerLim{"yMin"} );

			# position of paste data within paste profile
			$dataSize{"x"} = $layerLim{"xMin"} - $profLim{"xMin"};
			$dataSize{"y"} = $layerLim{"yMin"} - $profLim{"yMin"};

			$size{"bot"} = \%dataSize;

			# bot mirrored
			my %dataSizeMirr = ();

			CamHelper->SetStep( $inCAM, $stepName );
			my $mirr = GeneralHelper->GetGUID();
			$inCAM->COM( 'flatten_layer', "source_layer" => $botLayer->{"gROWname"}, "target_layer" => $mirr );
			CamLayer->MirrorLayerByProfCenter( $inCAM, $jobId, $stepName, $mirr, "y" );
			my %layerLimMir = CamJob->GetLayerLimits2( $inCAM, $jobId, $stepName, $mirr );
			$inCAM->COM( 'delete_layer', layer => $mirr );

			# limits of paste data
			$dataSizeMirr{"w"} = abs( $layerLimMir{"xMax"} - $layerLimMir{"xMin"} );
			$dataSizeMirr{"h"} = abs( $layerLimMir{"yMax"} - $layerLimMir{"yMin"} );

			# position of paste data within paste profile
			$dataSizeMirr{"x"} = $layerLimMir{"xMin"} - $profLim{"xMin"};
			$dataSizeMirr{"y"} = $layerLimMir{"yMin"} - $profLim{"yMin"};

			$size{"botMirror"} = \%dataSizeMirr;
		}

		$stepsSize{$stepName} = \%size;
	}

	$self->{"dataMngr"}->Init( \%stepsSize, \@steps, defined $topLayer ? 1 : 0, defined $botLayer ? 1 : 0 );

	# Set default values before start app

	# Set step, if exist SR step, set him

	my @SR = ();
	foreach my $s (@steps) {

		if ( CamStepRepeat->ExistStepAndRepeats( $inCAM, $jobId, $s ) ) {
			push( @SR, $s );
		}
	}

	if ( scalar(@SR) ) {
		$self->{"dataMngr"}->SetStencilStep( $SR[0] );
	}
	else {
		$self->{"dataMngr"}->SetStencilStep( $steps[0] );
	}

	$self->{"dataMngr"}->SetHoleSize(5.1);

	$self->{"dataMngr"}->SetHoleDist(15);

}

# Set default data by IS and by Customer notes
sub SetDefaultByIS {
	my $self = shift;
	my $mess = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $result = 1;

	my %stencilInfo = Helper->GetStencilInfo($jobId);
	my $orderInfo   = HegMethods->GetAllByPcbIdOffer($jobId);
	my $pcbInfo     = ( HegMethods->GetAllByPcbId($jobId) )[0];

	# Set drilled number
	# Do not add pcb number if pool, or vrtana sablona or customer source data
	if (    $stencilInfo{"tech"} eq Enums->Technology_DRILL
		 || $self->{"stencilSrc"} eq Enums->StencilSource_CUSTDATA
		 || ( $self->{"stencilSrc"} eq Enums->StencilSource_JOB && $self->{"isPool"} ) )
	{

		$self->{"dataMngr"}->SetAddPcbNumber(0);
	}

	# Set stencil type
	unless ( defined $stencilInfo{"type"} ) {

		$$mess .= "Nebyl dohledán typ šablony (top, bot, top+bot) v IS. Bude nastaven defaultní typ: \"TOP\".\n";
		$result = 0;
	}

	$self->{"dataMngr"}->SetStencilType( $stencilInfo{"type"} );

	# Set stencil size
	my $w = $stencilInfo{"width"};
	my $h = $stencilInfo{"height"};

	if ( !defined $w || !defined $h ) {

		$$mess .= "Nebyl dohledán rozměr rozměr šablony v IS. Bude nastaven defaultní rozměr 300x480mm\n";
		$w      = 300;
		$h      = 480;
		$result = 0;
	}

	$self->{"dataMngr"}->SetStencilSizeX($w);
	$self->{"dataMngr"}->SetStencilSizeY($h);

	# if pool, choose apropriate size bz pcb size
	if ( $self->{"stencilSrc"} eq Enums->StencilSource_JOB && $self->{"isPool"} ) {

		$self->{"dataMngr"}->SetStencilSizeX(300);
		$self->{"dataMngr"}->SetStencilSizeY(300);

	}

	$self->{"dataMngr"}->DefaultHoleDist();    # Compute default vertical distance according size

	# 4) Schema type
	my $schemaType = Enums->Schema_STANDARD;
	if ( $orderInfo->{"Poznamka_deska"} =~ /vlepe|rám/i ) {

		$schemaType = Enums->Schema_FRAME;
	}

	if ( $self->{"stencilSrc"} eq Enums->StencilSource_JOB && $self->{"isPool"} ) {

		$schemaType = Enums->Schema_INCLUDED;
	}

	$self->{"dataMngr"}->SetSchemaType($schemaType);

	if ( $schemaType eq Enums->Schema_STANDARD ) {

		# 5) Hole size
		$self->{"dataMngr"}->SetHoleSize(5.1);

		$self->{"dataMngr"}->SetHoleDist(15);    # default 15 mm

	}

	if ( $stencilInfo{"type"} eq Enums->StencilType_TOPBOT ) {

		# 7) Spacing type
		$self->{"dataMngr"}->SetSpacingType( Enums->Spacing_PROF2PROF );

		# 8) Set distance between profiles
		$self->{"dataMngr"}->SetSpacing(0);

	}

	$self->{"dataMngr"}->DefaultHoleDist();
	$self->{"dataMngr"}->DefaultSpacingType();
	$self->{"dataMngr"}->DefaultSpacing( $self->{"stencilMngr"} );

	return $result;

}

# Set default data by IS and by Customer notes
sub SetDefaultByCustomer {
	my $self = shift;

	my $mess = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $result = 1;

	my $schemaType = $self->{"dataMngr"}->GetSchemaType();

	if ( $schemaType eq Enums->Schema_STANDARD ) {

		# 5) Hole size

		# 6) Hole distance x
		if ( defined $self->{"customerNote"}->HoleDistX() ) {
			$self->{"dataMngr"}->SetHoleDist( $self->{"customerNote"}->HoleDistX() );
		}

		if ( defined $self->{"customerNote"}->HoleDistY() ) {
			$self->{"dataMngr"}->SetHoleDist2( $self->{"customerNote"}->HoleDistY() );
			$self->{"dataMngr"}->DefaultSpacing( $self->{"stencilMngr"} );
		}

	}

	#  Center stencil data
	if ( $self->{"customerNote"}->CenterByData() ) {

		$self->{"dataMngr"}->SetCenterType( Enums->Center_BYDATA );
		$self->{"dataMngr"}->DefaultSpacingType();
		$self->{"dataMngr"}->DefaultSpacing( $self->{"stencilMngr"} );
	}

	return $result;

}

sub CheckBeforeOutput {
	my $self = shift;
	my $mess = shift;

	my $result = 1;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# Check according customer notes

	# Check center by data
	if ( $self->{"customerNote"}->CenterByData() && $self->{"dataMngr"}->GetCenterType() ne Enums->Center_BYDATA ) {

		$result = 0;
		$$mess .= "Zákazník si přeje vycentrovat data na střed podle skutečných dat a ne podle profilu.";
	}

	# Check distance paste-holes in standard frame
	if ( defined $self->{"customerNote"}->MinHoleDataDist() ) {

		my $minDist = $self->{"customerNote"}->MinHoleDataDist();
		my $sType   = $self->{"dataMngr"}->GetStencilType();

		my $distOk    = 1;
		my $wrongDist = "";

		my %area = $self->{"stencilMngr"}->GetStencilActiveArea();

		my $areaBot = ( $self->{"stencilMngr"}->GetHeight() - $area{"h"} ) / 2;
		my $areaTop = $areaBot + $area{"h"};

		if ( $sType eq Enums->StencilType_TOP || $sType eq Enums->StencilType_TOPBOT ) {

			my $tp          = $self->{"stencilMngr"}->GetTopProfile();
			my $topPasteLim = $self->{"stencilMngr"}->GetTopDataPos()->{"y"} + $tp->GetPasteData()->GetHeight();

			if ( abs( $topPasteLim - $areaTop ) < $minDist ) {
				$distOk = 0;
				$wrongDist .= "- Vzdálenost data/horní otvory = " . abs( $topPasteLim - $areaTop ) . "mm\n";
			}
		}

		if ( $sType eq Enums->StencilType_BOT || $sType eq Enums->StencilType_TOPBOT ) {

			my $botPasteLim = $self->{"stencilMngr"}->GetBotDataPos()->{"y"};

			if ( abs( $botPasteLim - $areaBot ) < $minDist ) {
				$distOk = 0;
				$wrongDist .= "- Vzdálenost data/dolní otvory = " . abs( $botPasteLim - $areaBot ) . "mm\n";
			}
		}

		unless ($distOk) {

			$result = 0;
			$$mess .= "Zákazník si přeje aby minimální vzdálenost plošky na šabloně byla alespoň " . $minDist . "mm\n$wrongDist";
		}
	}

	# Y hole distance
	my $holeDistY = $self->{"customerNote"}->HoleDistY();
	if ( defined $holeDistY && $self->{"dataMngr"}->GetSchemaType() eq Enums->Schema_STANDARD ) {

		my @holesY = map { $_->{"y"} } $self->{"stencilMngr"}->GetSchema()->GetHolePositions();

		if ( abs( min(@holesY) - max(@holesY) ) != $holeDistY ) {

			$result = 0;
			$$mess .=
			    "Zákazník si přeje aby vertikální vzdálenost mezi upínacími otvory byla "
			  . $holeDistY
			  . "mm (aktuální je "
			  . abs( min(@holesY) - max(@holesY) ) . "mm)";
		}

	}

	# X hole distance
	my $holeDistX = $self->{"customerNote"}->HoleDistX();
	if ( defined $holeDistX && $self->{"dataMngr"}->GetSchemaType() eq Enums->Schema_STANDARD ) {

		my @holesX = sort { $a <=> $b } uniq( map { $_->{"x"} } $self->{"stencilMngr"}->GetSchema()->GetHolePositions() );

		# take fist two holes, if sitance is as costomer request

		if ( abs( $holesX[0] - $holesX[1] ) != $holeDistX ) {
			$result = 0;
			$$mess .=
			    "Zákazník si přeje aby horizontální vzdálenost mezi upínacími otvory byla "
			  . $holeDistX
			  . "mm (aktuální je "
			  . abs( $holesX[0] - $holesX[1] ) . "mm)";
		}

	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::StencilCreator::StencilCreator';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f13609";

	my $creator = StencilCreator->new( $inCAM, $jobId );
	$creator->Run();

}

1;

