
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Traveler::ProcessStackupTmpl::StackupMngr::StackupMngrBase;

#3th party library
use strict;
use warnings;
use List::Util qw(first min);

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamDrilling';
use aliased 'Helpers::JobHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::NifFile::NifFile';
use aliased 'Helpers::ValueConvertor';
use aliased 'Packages::CAMJob::Technology::LayerSettings';
use aliased 'CamHelpers::CamAttributes';
use aliased 'Packages::CAMJob::Traveler::ProcessStackupTmpl::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	#require rows in nif section
	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
	$self->{"step"}  = shift;

	$self->{"pcbInfoIS"} = ( HegMethods->GetAllByPcbId( $self->{"jobId"} ) )[0];

	# Get order info of active orders (take order with smaller reference)

	$self->{"nifFile"} = NifFile->new( $self->{"jobId"} );

	$self->{"layerSett"} = LayerSettings->new( $self->{"jobId"}, $self->{"step"} );
	$self->{"layerSett"}->Init( $self->{"inCAM"} );

	$self->{"boardBaseLayers"} = [ CamJob->GetBoardBaseLayers( $self->{"inCAM"}, $self->{"jobId"} ) ];

	my @NCLayers = CamJob->GetNCLayers( $self->{"inCAM"}, $self->{"jobId"} );
	CamDrilling->AddNCLayerType( \@NCLayers );
	CamDrilling->AddLayerStartStop( $self->{"inCAM"}, $self->{"jobId"}, \@NCLayers );
	$self->{"NCLayers"} = \@NCLayers;

	$self->{"pcbType"}    = JobHelper->GetPcbType( $self->{"jobId"} );
	$self->{"isFlex"}     = JobHelper->GetIsFlex( $self->{"jobId"} );
	$self->{"isMatKinds"} = { HegMethods->GetAllMatKinds() };

	return $self;
}

sub GetOrderId {
	my $self = shift;

	my $orderName = $self->{"jobId"} . "-" . Enums->KEYORDERNUM;

	return $orderName;

}

sub GetPCBName {
	my $self = shift;

	return $self->{"pcbInfoIS"}->{"board_name"};

}

sub GetCustomerName {
	my $self = shift;

	return HegMethods->GetCustomerInfo( $self->{"jobId"} )->{"customer"};

}

sub GetPCBEmployeeInfo {
	my $self = shift;

	my $name = CamAttributes->GetJobAttrByName( $self->{"inCAM"}, $self->{"jobId"}, "user_name" );

	my %employyInf = ();

	if ( defined $name && $name ne "" ) {

		%employyInf = %{ HegMethods->GetEmployyInfo($name) }

	}

	return %employyInf;
}

sub GetOrderTerm {
	my $self = shift;

	my $dateTerm = Enums->KEYORDERTERM;

	#	if ( defined $self->{"orderInfoIS"} ) {
	#
	#		my $pattern = DateTime::Format::Strptime->new( pattern => '%Y-%m-%d %H:%M:%S', );
	#
	#		$dateTerm = $pattern->parse_datetime( $self->{"orderInfoIS"}->{"termin"} )->dmy('.');    # order term
	#
	#	}

	return $dateTerm;
}

sub GetOrderDate {
	my $self = shift;

	my $dateStart = Enums->KEYORDERDATE;

	#	if ( defined $self->{"orderInfoIS"} ) {
	#
	#		my $pattern = DateTime::Format::Strptime->new( pattern => '%Y-%m-%d %H:%M:%S', );
	#		$dateStart = $pattern->parse_datetime( $self->{"orderInfoIS"}->{"datum_zahajeni"} )->dmy('.');    # start order date
	#
	#	}

	return $dateStart;
}

sub GetPanelSize {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $step );

	my $w = abs( $lim{"xMax"} - $lim{"xMin"} );
	my $h = abs( $lim{"yMax"} - $lim{"yMin"} );

	return ( $w, $h );
}

#sub GetExistSM {
#	my $self = shift;
#	my $side = shift;    # top/bot
#	my $info = shift;    # reference to store additional information
#
#	my $l = $side eq"top"?"mc":"ms";
#
#	my $smExist = defined( first { $_->{"gROWname"} eq $l } @{ $self->{"boardBaseLayers"} } ) ? 1 : 0;
#
#	if ( $smExist && defined $info ) {
#
#		my %mask = $self->__GetMaskColor();
#		$info->{"color"} = ValueConvertor->GetMaskCodeToColor( $mask{$side} );
#		$info->{"thick"} = 20;
#
#	}
#
#	return $smExist;
#}
#
#sub GetExistSMFlex {
#	my $self = shift;
#	my $side = shift;    # top/bot
#	my $info = shift;    # reference to store additional information
#
#	my $l = $side eq"top"?"mcflex":"msflex";
#
#	my $smExist = defined( first { $_->{"gROWname"} eq $l } @{ $self->{"boardBaseLayers"} } ) ? 1 : 0;
#
#	if ( $smExist && defined $info ) {
#
#		$info->{"text"}  ="UV Green";
#		$info->{"thick"} = 25;
#
#	}
#
#	return $smExist;
#
#}
#
sub GetPcbType {
	my $self = shift;

	return $self->{"pcbType"};
}

sub GetISPcbType {
	my $self = shift;

	return HegMethods->GetTypeOfPcb( $self->{"jobId"} );
}

sub GetExistStiff {
	my $self     = shift;
	my $side     = shift;    # top/bot
	my $stifInfo = shift;    # reference for storing info

	my $l = $side eq "top" ? "stiffc" : "stiffs";

	my $exist = defined( first { $_->{"gROWname"} eq $l } @{ $self->{"boardBaseLayers"} } ) ? 1 : 0;

	if ($exist) {

		if ( defined $stifInfo ) {

			my $mInf = HegMethods->GetPcbStiffenerMat( $self->{"jobId"}, $side );
			my $mAdhInf = HegMethods->GetPcbStiffenerAdhMat( $self->{"jobId"}, $side );
			my @nAdh = split( /\s/, $mAdhInf->{"nazev_subjektu"} );

			$stifInfo->{"adhesiveISRef"} = $mAdhInf->{"reference_subjektu"};
			$stifInfo->{"adhesiveKind"}  = "";
			$stifInfo->{"adhesiveText"}  = $mAdhInf->{"nazev_subjektu"};
			$stifInfo->{"adhesiveThick"} = $mAdhInf->{"vyska"} * 1000000;      #
			$stifInfo->{"adhesiveTg"}    = 204;

			my @n = split( /\s/, $mInf->{"nazev_subjektu"} );
			shift(@n) if ( $n[0] =~ /lam/i );

			$_ =~ s/mm//gi foreach (@n);

			$stifInfo->{"stiffISRef"} = $mInf->{"reference_subjektu"};
			$stifInfo->{"stiffKind"}  = $mInf->{"dps_druh"};
			$stifInfo->{"stiffText"}  = $mInf->{"nazev_subjektu"};

			my $t = $n[2];
			$t =~ s/,/\./;
			$t *= 1000;

			$stifInfo->{"stiffThick"} = $t;      # ?m
			$stifInfo->{"stiffTg"}    = undef;

			# Try to get TG of stiffener adhesive
			my $matKey = first { $mInf->{"nazev_subjektu"} =~ /$_/i } keys %{ $self->{"isMatKinds"} };
			if ( defined $matKey ) {
				$stifInfo->{"stiffTg"} = $self->{"isMatKinds"}->{$matKey};
			}

			die "Stiffener adhesive material name was not found at material :" . $mInf->{"nazev_subjektu"}
			  unless ( defined $stifInfo->{"adhesiveText"} );
			die "Stiffener adhesive material thick was not found at material :" . $mInf->{"nazev_subjektu"}
			  unless ( defined $stifInfo->{"adhesiveThick"} );
			die "Stiffener material name was not found at material :" . $mInf->{"nazev_subjektu"} unless ( defined $stifInfo->{"stiffText"} );
			die "Stiffener thickness was not found at material :" . $mInf->{"nazev_subjektu"}     unless ( defined $stifInfo->{"stiffThick"} );
			die "Stiffener TG was not found at material :" . $mInf->{"nazev_subjektu"}            unless ( defined $stifInfo->{"stiffTg"} );
		}
	}

	return $exist;

}

# Tape on flex
sub GetExistTapeFlex {
	my $self = shift;
	my $side = shift;    # top/bot
	my $inf  = shift;    # reference for storing info

	my $l = $side eq "top" ? "tpc" : "tps";

	my $exist = defined( first { $_->{"gROWname"} eq $l } @{ $self->{"boardBaseLayers"} } ) ? 1 : 0;

	if ($exist) {

		if ( defined $inf ) {

			my $matInfo = HegMethods->GetPcbTapeFlexMat( $self->{"jobId"}, $side );

			$inf->{"tpISRef"} = $matInfo->{"reference_subjektu"};

			my $thick = $matInfo->{"vyska"} * 1000000;

			$inf->{"tpText"}  =  $matInfo->{"nazev_subjektu"};    # 
			$inf->{"tpThick"} = $thick;

			die "Tape material name was not found at material:" . $matInfo->{"nazev_subjektu"}
			  unless ( defined $inf->{"tpText"} );
			die "Tape material thick was not found at material:" . $matInfo->{"nazev_subjektu"}
			  unless ( defined $inf->{"tpThick"} );

		}
	}

	return $exist;
}

# Tape on stiffener
sub GetExistTapeStiff {
	my $self = shift;
	my $side = shift;    # top/bot
	my $inf  = shift;    # reference for storing info

	my $l = $side eq "top" ? "tpstiffc" : "tpstiffs";

	my $exist = defined( first { $_->{"gROWname"} eq $l } @{ $self->{"boardBaseLayers"} } ) ? 1 : 0;

	if ($exist) {

		if ( defined $inf ) {

			my $matInfo = HegMethods->GetPcbTapeStiffMat( $self->{"jobId"}, $side );

			$inf->{"tpISRef"} = $matInfo->{"reference_subjektu"};

			my $thick = $matInfo->{"vyska"} * 1000000;

			$inf->{"tpText"}  =  $matInfo->{"nazev_subjektu"};    #  
			$inf->{"tpThick"} = $thick;

			die "Tape material name was not found at material:" . $matInfo->{"nazev_subjektu"}
			  unless ( defined $inf->{"tpText"} );
			die "Tape material thick was not found at material:" . $matInfo->{"nazev_subjektu"}
			  unless ( defined $inf->{"tpThick"} );

		}
	}

	return $exist;
}

sub GetSteelPlateInfo {
	my $self = shift;

	my $inf = {};

	$inf->{"ISRef"} = undef;
	$inf->{"text"}  = "Sttel plate";
	$inf->{"thick"} = 1000;            # 1000?m

	return $inf;
}

sub GetAluPlateInfo {
	my $self = shift;

	my $inf = {};

	$inf->{"ISRef"} = "0401000021";
	$inf->{"text"}  = "ALU entry boards A18,";
	$inf->{"thick"} = 200;                       # 1000?m

	return $inf;
}

sub GetPressPad01FGKInfo {
	my $self = shift;

	my $isId = "0318000010";
	my $inf  = $self->__GetPresspadInfo($isId);

	return $inf;
}

sub GetPressPadTB317KInfo {
	my $self = shift;

	my $isId = "0318000021";
	my $inf  = $self->__GetPresspadInfo($isId);

	return $inf;
}

sub GetPressPadFF10NInfo {
	my $self = shift;

	my $isId = "0318000020";
	my $inf  = $self->__GetPresspadInfo($isId);

	return $inf;
}

sub GetPressPadYOMFLEX200Info {
	my $self = shift;

	my $isId = "0318000023";
	my $inf  = $self->__GetPresspadInfo($isId);

	return $inf;
}

sub GetPresspad5500Info {
	my $self = shift;

	my $isId = "0319000064";
	my $inf  = $self->__GetPresspadInfo($isId);

	return $inf;
}

sub GetReleaseFilm1500HTInfo {
	my $self = shift;

	my $isId = "0319000031";
	my $inf  = $self->__GetPresspadInfo($isId);

	return $inf;
}

sub GetReleaseFilmPacoViaInfo {
	my $self = shift;

	my $isId = "0319000041";
	my $inf  = $self->__GetPresspadInfo($isId);

	return $inf;
}

sub GetFilmPacoflexUltraInfo {
	my $self = shift;

	my $isId = "0319000032";
	my $inf  = $self->__GetPresspadInfo($isId);

	return $inf;
}

sub GetFilmPacoplus4500Info {
	my $self = shift;

	my $isId = "0319000030";
	my $inf  = $self->__GetPresspadInfo($isId);

	return $inf;
}

sub __GetPresspadInfo {
	my $self   = shift;
	my $matRef = shift;

	my $inf = {};

	my $isInf = HegMethods->GetMatInfo($matRef);

	$inf->{"ISRef"} = $isInf->{"reference_subjektu"};
	$inf->{"text"}  = $isInf->{"nazev_subjektu"};

	# Remove dimensions
	$inf->{"text"} =~ s/\d+(\,\d+)?\s*[m]*\s*x\s*\d+(\,\d+)?\s*[m]*\s*//;

	my $t = $isInf->{"vyska"};
	$t =~ s/,/\./;
	$t *= 1000000;

	$inf->{"thick"} = $t;

	die "Pad material name was not found  for material IS reference :" . $matRef unless ( defined $inf->{"text"} );
	die "Pad material thick was not found for material IS reference :" . $matRef unless ( defined $inf->{"thick"} );

	return $inf;
}

#
## Decide of get mask color ftom NIF/Helios
#sub __GetMaskColor {
#	my $self       = shift;
#	my $secondMask = shift;
#
#	my $jobId   = $self->{"jobId"};
#	my $nifFile = NifFile->new($jobId);
#
#	my %mask = ();
#
#	if ( $nifFile->Exist() ) {
#
#		# use nif file
#		%mask = $nifFile->GetSolderMaskColor();
#
#		# check if exist second mask in IS
#		if ($secondMask) {
#
#			%mask = HegMethods->GetSolderMaskColor2($jobId);
#		}
#	}
#	else {
#		# use nif norris
#		%mask = $secondMask ? HegMethods->GetSolderMaskColor2($jobId) : HegMethods->GetSolderMaskColor($jobId);
#
#	}
#
#	return %mask;
#}
#
#sub GetIsPlated {
#	my $self     = shift;
#	my $sigLayer = shift;
#
#	my %sett = $self->{"layerSett"}->GetDefSignalLSett($sigLayer);
#
#	my $isPlated = 0;
#
#	if ( $sett{"technologyType"} eq EnumsGeneral->Technology_GALVANICS ) {
#		$isPlated = 1;
#	}
#	return $isPlated;
#
#}
#
sub GetIsFlex {
	my $self = shift;

	return $self->{"isFlex"};
}

sub GetCuLayerCnt {
	my $self = shift;

	return CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $self->{"jobId"} );
}

#
#
#
#sub GetBoardBaseLayers {
#	my $self = shift;
#
#	return @{ $self->{"boardBaseLayers"} };
#}
#
## Return TG of layer stiffener, adhesive, ...
#sub _GetSpecLayerTg {
#	my $self = shift;
#
#	my @allTg = ();
#
#	my $infStiffTop = {};
#	if ( $self->GetExistStiff("top", $infStiffTop ) ) {
#
#		push( @allTg, $infStiffTop->{"adhesiveTg"} ) if ( defined $infStiffTop->{"adhesiveTg"} );
#		push( @allTg, $infStiffTop->{"stiffTg"} )    if ( defined $infStiffTop->{"stiffTg"} );
#	}
#
#	my $infStiffBot = {};
#	if ( $self->GetExistStiff("bot", $infStiffBot ) ) {
#
#		push( @allTg, $infStiffBot->{"adhesiveTg"} ) if ( defined $infStiffBot->{"adhesiveTg"} );
#		push( @allTg, $infStiffBot->{"stiffTg"} )    if ( defined $infStiffBot->{"stiffTg"} );
#	}
#
#	return min(@allTg);
#}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

