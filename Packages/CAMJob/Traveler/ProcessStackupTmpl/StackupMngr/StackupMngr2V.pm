
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Traveler::ProcessStackupTmpl::StackupMngr::StackupMngr2V;
use base('Packages::CAMJob::Traveler::ProcessStackupTmpl::StackupMngr::StackupMngrBase');

#3th party library
use utf8;
use strict;
use warnings;
use List::Util qw(first min max);

#local library
use aliased 'Packages::CAMJob::Traveler::ProcessStackupTmpl::Enums';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';
use aliased 'CamHelpers::CamJob';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAMJob::Traveler::ProcessStackupTmpl::StackupLam::StackupLam';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	return $self;
}

sub GetAllLamination {
	my $self    = shift;
	my $lamType = shift;

	my $cvrlTopExist = $self->GetExistCvrl("top");

	my $cvrlBotExist = $self->GetExistCvrl("bot");

	my $stiffTopExist = $self->GetExistStiff("top");

	my $stiffBotExist = $self->GetExistStiff("bot");

	my $tapeTopExist = $self->GetExistTapeFlex("top");

	my $tapeBotExist = $self->GetExistTapeFlex("bot");

	my $tapeStiffTopExist = $self->GetExistTapeStiff("top");

	my $tapeStiffBotExist = $self->GetExistTapeStiff("bot");

	my @lam = ();

	if ( $cvrlTopExist || $cvrlBotExist ) {
		my $inf = StackupLam->new( scalar(@lam), Enums->LamType_CVRLBASE,  "P" . ( scalar(@lam) + 1 ) );
		push( @lam, $inf );
	}

	if ( $tapeTopExist || $tapeBotExist ) {
		my $inf = StackupLam->new( scalar(@lam), Enums->LamType_TAPEPRODUCT,  "P" . ( scalar(@lam) + 1 ) );
		push( @lam, $inf );
	}

	if ( $stiffTopExist || $stiffBotExist ) {
		my $inf = StackupLam->new( scalar(@lam), Enums->LamType_STIFFPRODUCT,  "P" . ( scalar(@lam)  + 1) );
		push( @lam, $inf );
	}

	if ( $tapeStiffTopExist || $tapeStiffBotExist ) {
		my $inf = StackupLam->new( scalar(@lam), Enums->LamType_TAPESTIFFPRODUCT,  "P" . ( scalar(@lam) + 1 ) );
		push( @lam, $inf );
	}

	# Filter laminations by type
	if ( defined $lamType ) {
		@lam = grep { $_->GetLamType() eq $lamType } @lam;
	}

	return @lam;
}

sub GetThick {
	my $self          = shift;
	my $inclCoverlay  = shift;
	my $inclStiffener = shift;

	my $thick = $self->{"pcbInfoIS"}->{"material_tloustka"} * 1000;

	if ($inclCoverlay) {

		my $cvrlTop = {};
		if ( $self->GetExistCvrl( "top", $cvrlTop ) ) {
			$thick += $cvrlTop->{"cvrlThick"} + $cvrlTop->{"adhesiveThick"};
		}

		my $cvrlBot = {};
		if ( $self->GetExistCvrl( "bot", $cvrlBot ) ) {
			$thick += $cvrlBot->{"cvrlThick"} + $cvrlBot->{"adhesiveThick"};
		}
	}

	if ($inclStiffener) {

		my $stiffTop = {};
		if ( $self->GetExistStiff( "top", $stiffTop ) ) {
			$thick += $stiffTop->{"stiffThick"} + $stiffTop->{"adhesiveThick"};
		}

		my $stiffBot = {};
		if ( $self->GetExistStiff( "bot", $stiffBot ) ) {
			$thick += $stiffBot->{"stiffThick"} + $stiffBot->{"adhesiveThick"};
		}
	}

	return $thick;

}

#sub GetLayerCnt {
#	my $self = shift;
#
#	my $lCnt = CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $self->{"jobId"} );
#
#	if ( $self->GetPcbType() eq EnumsGeneral->PcbType_NOCOPPER ) {
#		$lCnt = 0;
#	}
#	if ( $self->GetPcbType() eq EnumsGeneral->PcbType_1VFLEX ) {
#		$lCnt = 1;
#	}
#
#	return $lCnt;
#
#}
#
#sub GetStackupLayers {
#	my $self = shift;
#
#	my @sigL = grep { $_->{"gROWname"} =~ /^[cs]$/ } @{ $self->{"boardBaseLayers"} };
#
#	if ( $self->GetPcbType() eq EnumsGeneral->PcbType_NOCOPPER ) {
#		@sigL = ();
#	}
#	if ( $self->GetPcbType() eq EnumsGeneral->PcbType_1VFLEX ) {
#		@sigL = grep { $_->{"gROWname"} eq "c" } @sigL;
#	}
#
#	return @sigL;
#}
#
#sub GetBaseMatInfo {
#	my $self = shift;
#
#	my %inf = ();
#
#	my $matInf = HegMethods->GetPcbMat( $self->{"jobId"} );
#
#	my $matName = $matInf->{"nazev_subjektu"};
#
#	# Parse material name
#	my @parsedMat = split( /\s/, $matName );
#	shift @parsedMat if ( $parsedMat[0] =~ /lam/i );
#	$inf{"matText"} = $parsedMat[0];
#
#	# Parse mat thick  + remove Cu thickness if material is type of Laminate (core material thickness not include Cu thickness)
#	$inf{"baseMatThick"} = $matInf->{"vyska"} * 1000000;
#
#	if ( $matInf->{"dps_type"} !~ /core/i ) {
#
#		if ( $matInf->{"nazev_subjektu"} =~ m/(\d+\/\d+)/ ) {
#			my @cu = split( "/", $1 );
#			$inf{"baseMatThick"} -= $cu[0] if ( defined $cu[0] );
#			$inf{"baseMatThick"} -= $cu[1] if ( defined $cu[1] );
#		}
#	}
#
#	# Parse Cu thick
#	$inf{"cuThick"} = undef;
#	if ( $matInf->{"nazev_subjektu"} =~ m/(\d+)\/(\d+)/ ) {
#		$inf{"cuThick"} = max( $1, $2 );
#	}
#
#	# Parse Cu type ED/RA
#	$inf{"cuType"} = undef;
#	if ( $matName =~ m/(ap)|(cg)/i ) {
#		$inf{"cuType"} = $matName =~ m/ap/i ? "RA" : "ED";
#	}
#
#	die "Material text was not found at material: $matName"         unless ( defined $inf{"matText"} );
#	die "Base mat thick was not found at material: $matName"        unless ( defined $inf{"baseMatThick"} );
#	die "Material cu thickness was not found at material: $matName" unless ( defined $inf{"cuThick"} );
#
#	return %inf;
#
#}
#
sub GetExistCvrl {
	my $self = shift;
	my $side = shift;    # top/bot
	my $inf  = shift;    # reference for storing info

	my $l = $side eq "top" ? "cvrlc" : "cvrls";

	my $exist = defined( first { $_->{"gROWname"} eq $l } @{ $self->{"boardBaseLayers"} } ) ? 1 : 0;

	if ($exist) {

		if ( defined $inf ) {

			my $matInfo = HegMethods->GetPcbCoverlayMat( $self->{"jobId"}, $side );

			$inf->{"cvrlISRef"} = $matInfo->{"reference_subjektu"};

			my $thick    = $matInfo->{"vyska"} * 1000000;
			my $thickAdh = $matInfo->{"doplnkovy_rozmer"} * 1000000;

			$inf->{"adhesiveText"}  = "";
			$inf->{"adhesiveThick"} = $thickAdh;
			$inf->{"cvrlText"}      = ( $matInfo->{"nazev_subjektu"} =~ /^(\w+\s*\w+)\s+/ )[0];    # ? is not store
			$inf->{"cvrlThick"}     = $thick - $thickAdh;
			$inf->{"selective"}     = 0;                                                     # Selective coverlay can bz onlz at RigidFLex pcb

			die "Cvrl adhesive material name was not found at material:" . $matInfo->{"nazev_subjektu"}
			  unless ( defined $inf->{"adhesiveText"} );
			die "Coverlay adhesive material thick was not found at material:" . $matInfo->{"nazev_subjektu"}
			  unless ( defined $inf->{"adhesiveThick"} );
			die "Coverlay material name was not found at material:" . $matInfo->{"nazev_subjektu"} unless ( defined $inf->{"cvrlText"} );
			die "Coverlay thickness was not found at material:" . $matInfo->{"nazev_subjektu"}     unless ( defined $inf->{"cvrlThick"} );
			die "Coverlay type (selective or not)was not found at material:" . $matInfo->{"nazev_subjektu"}
			  unless ( defined $inf->{"selective"} );

		}
	}

	return $exist;
}
#
#sub GetCuThickness {
#	my $self = shift;
#
#	return HegMethods->GetOuterCuThick( $self->{"jobId"} );
#}
#

# Return info about material kind and material TG
sub GetBaseMaterialInfo {
	my $self = shift;

	my @mats = ();

	# 1) Get min TG of PCB
	my $matKind = $self->{"pcbInfoIS"}->{"material_druh"};

	my $minTG = undef;

	if ( $matKind =~ /tg\s*(\d+)/i ) {

		# single kinf of stackup materials

		$minTG = $1;
	}

	push( @mats, { "kind" => $matKind, "tg" => $minTG } );

	return @mats;
}

sub GetPressProgramInfo {
	my $self    = shift;
	my $lamType = shift;

	my ( $w, $h ) = $self->GetPanelSize();
	my @mats = $self->GetBaseMaterialInfo();

	my %pInfo = ( "name" => undef, "dimX" => undef, "dimY" => undef );

	# 1) Program name

	if ( $lamType eq Enums->LamType_STIFFPRODUCT ) {

		$pInfo{"name"} = "Stiffener_tape";

	}
	elsif ( $lamType eq Enums->LamType_TAPEPRODUCT || $lamType eq Enums->LamType_TAPESTIFFPRODUCT ) {

		$pInfo{"name"} = "Tape";

	}
	elsif ( $lamType eq Enums->LamType_CVRLBASE ) {

		$pInfo{"name"} = "Flex_coverlay";

	}

	$pInfo{"name"} .= "_$h";

	# 2) Program dim

	if ( $h < 410 && $self->GetIsFlex() ) {

		$pInfo{"dimX"} = "400";
		$pInfo{"dimY"} = "400";
	}
	else {

		$pInfo{"dimX"} = $w;
		$pInfo{"dimY"} = $h;
	}

	die "Press program name was found for lamination type: $lamType" unless ( defined $pInfo{"name"} );

	return %pInfo;
}

#
#sub GetThicknessStiffener {
#	my $self = shift;
#	my $t    = $self->GetThickness();
#
#	my $topStiff = {};
#	if ( $self->GetExistStiff( "top", $topStiff ) ) {
#
#		$t += $topStiff->{"adhesiveThick"} * $self->{"adhReduction"};
#		$t += $topStiff->{"stiffThick"};
#	}
#
#	my $botStiff = {};
#	if ( $self->GetExistStiff( "bot", $botStiff ) ) {
#
#		$t += $botStiff->{"adhesiveThick"} * $self->{"adhReduction"};
#		$t += $botStiff->{"stiffThick"};
#	}
#
#	return $t;
#
#}
#
## Real PCB thickness
#sub GetThickness {
#	my $self = shift;
#
#	my $matInfo = HegMethods->GetPcbMat( $self->{"jobId"} );
#	my $m       = $matInfo->{"vyska"};
#
#	die "Material thickness (specifikace/vyska) is not defined for material: " . $self->{"pcbInfoIS"}->{"material_nazev"} unless ( defined $m );
#
#	my $t = $m;
#
#	$t =~ s/,/\./;
#	$t *= 1000000;
#
#	# Remove cu from base material thickness
#	if ( $matInfo->{"dps_type"} !~ /core/i ) {
#
#		if ( $matInfo->{"nazev_subjektu"} =~ m/(\d+\/\d+)/ ) {
#			my @cu = split( "/", $1 );
#			$t -= $cu[0] if ( defined $cu[0] );
#			$t -= $cu[1] if ( defined $cu[1] );
#		}
#	}
#
#	# Add cu by real pcb type
#	my $cu = $self->GetCuThickness();
#
#	if (    $self->GetPcbType() eq EnumsGeneral->PcbType_1VFLEX
#		 || $self->GetPcbType() eq EnumsGeneral->PcbType_1V )
#	{
#		# note 1V flex is prepared from double sided material
#
#		$t += $cu;
#	}
#	elsif (    $self->GetPcbType() eq EnumsGeneral->PcbType_2VFLEX
#			|| $self->GetPcbType() eq EnumsGeneral->PcbType_2V )
#	{
#		$t += 2 * $cu;
#	}
#
#	if ( $self->{"layerSett"}->GetDefaultTechType() eq EnumsGeneral->Technology_GALVANICS ) {
#		$t += 2 * 25;
#	}
#
#	# consider solder mask
#	my $topSM = {};
#	if ( $self->GetExistSM( "top", $topSM ) ) {
#
#		$t += $topSM->{"thick"} * $self->{"SMReduction"};
#	}
#
#	my $botSM = {};
#	if ( $self->GetExistSM( "bot", $botSM ) ) {
#
#		$t += $botSM->{"thick"} * $self->{"SMReduction"};
#	}
#
#	# Consider coverlay
#	my $adhReduction = 0.75;    # Adhesives are reduced by 25% after pressing (copper gaps are filled with adhesive)
#	my $topCvrl      = {};
#	if ( $self->GetExistCvrl( "top", $topCvrl ) ) {
#
#		$t += $topCvrl->{"adhesiveThick"} * $adhReduction;
#		$t += $topCvrl->{"cvrlThick"};
#	}
#
#	my $botCvrl = {};
#	if ( $self->GetExistCvrl( "bot", $botCvrl ) ) {
#
#		$t += $botCvrl->{"adhesiveThick"} * $adhReduction;
#		$t += $botCvrl->{"cvrlThick"};
#	}
#
#	return $t;
#
#}
#
## Thickness requested by customer
#sub GetNominalThickness {
#	my $self = shift;
#
#	my $t = $self->{"pcbInfoIS"}->{"material_tloustka"};
#	if ( defined $t && $t ne "" ) {
#
#		$t =~ s/,/\./;
#		$t *= 1000;
#	}
#
#	return $t;
#
#}
#
#sub GetFlexPCBCode {
#	my $self = shift;
#
#	my $pcbType = $self->GetPcbType();
#	my $code    = undef;
#	if ( $pcbType eq EnumsGeneral->PcbType_1VFLEX ) {
#		$code = "1F";
#	}
#	elsif ( $pcbType eq EnumsGeneral->PcbType_2VFLEX ) {
#		$code = "2F";
#	}
#	elsif ( $pcbType eq EnumsGeneral->PcbType_MULTIFLEX ) {
#		$code = $self->GetLayerCnt() . "F";
#	}
#
#	return $code;
#}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

