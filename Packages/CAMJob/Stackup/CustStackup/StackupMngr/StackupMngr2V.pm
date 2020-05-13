
#-------------------------------------------------------------------------------------------#
# Description: Nif Builder is responsible for creation nif file depend on pcb type
# Builder for pcb no copper
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::CustStackup::StackupMngr::StackupMngr2V;
use base('Packages::CAMJob::Stackup::CustStackup::StackupMngr::StackupMngrBase');

#3th party library
use strict;
use warnings;
use List::Util qw(first min max);

#local library

use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';
use aliased 'CamHelpers::CamJob';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Enums::EnumsGeneral';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	return $self;
}

sub GetLayerCnt {
	my $self = shift;

	my $lCnt = CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $self->{"jobId"} );

	if ( $self->GetPcbType() eq EnumsGeneral->PcbType_NOCOPPER ) {
		$lCnt = 0;
	}
	if ( $self->GetPcbType() eq EnumsGeneral->PcbType_1VFLEX ) {
		$lCnt = 1;
	}

	return $lCnt;

}

sub GetStackupLayers {
	my $self = shift;

	my @sigL = grep { $_->{"gROWname"} =~ /^[cs]$/ } @{ $self->{"boardBaseLayers"} };

	if ( $self->GetPcbType() eq EnumsGeneral->PcbType_NOCOPPER ) {
		@sigL = ();
	}
	if ( $self->GetPcbType() eq EnumsGeneral->PcbType_1VFLEX ) {
		@sigL = grep { $_->{"gROWname"} eq "c" } @sigL;
	}

	return @sigL;
}

sub GetBaseMatInfo {
	my $self = shift;

	my %inf = ();

	my $matInf = HegMethods->GetPcbMat( $self->{"jobId"} );

	my $matName = $matInf->{"nazev_subjektu"};

	# Parse material name
	my @parsedMat = split( /\s/, $matName );
	shift @parsedMat if ( $parsedMat[0] =~ /lam/i );
	$inf{"matText"} = $parsedMat[0];

	# Parse mat thick  + remove Cu thickness if material is type of Laminate (core material thickness not include Cu thickness)
	$inf{"baseMatThick"} = $matInf->{"vyska"} * 1000000;

	if ( $matInf->{"dps_type"} !~ /core/i ) {

		if ( $matInf->{"nazev_subjektu"} =~ m/(\d+\/\d+)/ ) {
			my @cu = split( "/", $1 );
			$inf{"baseMatThick"} -= $cu[0] if ( defined $cu[0] );
			$inf{"baseMatThick"} -= $cu[1] if ( defined $cu[1] );
		}
	}

	# Parse Cu thick
	$inf{"cuThick"} = undef;
	if ( $matInf->{"nazev_subjektu"} =~ m/(\d+)\/(\d+)/ ) {
		$inf{"cuThick"} = max( $1, $2 );
	}

	# Parse Cu type ED/RA
	$inf{"cuType"} = undef;
	if ( $matName =~ m/(ap)|(cg)/i ) {
		$inf{"cuType"} = $matName =~ m/ap/i ? "RA" : "ED";
	}

	die "Material text was not found at material: $matName"         unless ( defined $inf{"matText"} );
	die "Base mat thick was not found at material: $matName"        unless ( defined $inf{"baseMatThick"} );
	die "Material cu thickness was not found at material: $matName" unless ( defined $inf{"cuThick"} );

	return %inf;

}

sub GetExistCvrl {
	my $self = shift;
	my $side = shift;    # top/bot
	my $inf  = shift;    # reference for storing info

	my $l = $side eq "top" ? "coverlayc" : "coverlays";

	my $exist = defined( first { $_->{"gROWname"} eq $l } @{ $self->{"boardBaseLayers"} } ) ? 1 : 0;

	if ($exist) {

		if ( defined $inf ) {

			my $matInfo = HegMethods->GetPcbCoverlayMat( $self->{"jobId"} );

			my $thick    = $matInfo->{"vyska"} * 1000000;
			my $thickAdh = $matInfo->{"doplnkovy_rozmer"} * 1000000;

			$inf->{"adhesiveText"}  = "";
			$inf->{"adhesiveThick"} = $thickAdh;
			$inf->{"cvrlText"}      = ( $matInfo->{"nazev_subjektu"} =~ /(LF\s\d+)/ )[0];    # ? is not store
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

sub GetCuThickness {
	my $self = shift;

	return HegMethods->GetOuterCuThick( $self->{"jobId"} );
}

sub GetTG {
	my $self = shift;

	# 1) Get min TG of PCB
	my $matKind = HegMethods->GetMaterialKind( $self->{"jobId"}, 1 );

	my $minTG = undef;

	if ( $matKind =~ /tg\s*(\d+)/i ) {

		# single kinf of stackup materials

		$minTG = $1;
	}

	# 2) Get min TG of estra layers (stiffeners/double coated tapes etc..)
	my $specTg = $self->_GetSpecLayerTg();

	if ( defined $minTG && defined $specTg ) {
		$minTG = min( ( $minTG, $specTg ) );
	}

	return $minTG;
}

sub GetThicknessStiffener {
	my $self      = shift;
	my $stiffSide = shift;

	my $t = $self->GetThickness();

	my $stiff = {};
	if ( $self->GetExistStiff( $stiffSide, $stiff ) ) {

		$t += $stiff->{"adhesiveThick"} * $self->{"adhReduction"};
		$t += $stiff->{"stiffThick"};
	}

	return $t;
}

# Real PCB thickness
sub GetThickness {
	my $self = shift;

	my $matInfo = HegMethods->GetPcbMat( $self->{"jobId"} );
	my $m       = $matInfo->{"vyska"};

	die "Material thickness (specifikace/vyska) is not defined for material: " . $self->{"pcbInfoIS"}->{"material_nazev"} unless ( defined $m );

	my $t = $m;

	$t =~ s/,/\./;
	$t *= 1000000;

	# Remove cu from base material thickness
	if ( $matInfo->{"dps_type"} !~ /core/i ) {

		if ( $matInfo->{"nazev_subjektu"} =~ m/(\d+\/\d+)/ ) {
			my @cu = split( "/", $1 );
			$t -= $cu[0] if ( defined $cu[0] );
			$t -= $cu[1] if ( defined $cu[1] );
		}
	}

	# Add cu by real pcb type
	my $cu = $self->GetCuThickness();

	if (    $self->GetPcbType() eq EnumsGeneral->PcbType_1VFLEX
		 || $self->GetPcbType() eq EnumsGeneral->PcbType_1V )
	{
		# note 1V flex is prepared from double sided material

		$t += $cu;
	}
	elsif (    $self->GetPcbType() eq EnumsGeneral->PcbType_2VFLEX
			|| $self->GetPcbType() eq EnumsGeneral->PcbType_2V )
	{
		$t += 2 * $cu;
	}

	if ( $self->{"layerSett"}->GetDefaultTechType() eq EnumsGeneral->Technology_GALVANICS ) {
		$t += 2 * 25;
	}

	# consider solder mask
	my $topSM = {};
	if ( $self->GetExistSM( "top", $topSM ) ) {

		$t += $topSM->{"thick"} * $self->{"SMReduction"};
	}

	my $botSM = {};
	if ( $self->GetExistSM( "bot", $botSM ) ) {

		$t += $botSM->{"thick"} * $self->{"SMReduction"};
	}

	# Consider coverlay
	my $adhReduction = 0.75;    # Adhesives are reduced by 25% after pressing (copper gaps are filled with adhesive)
	my $topCvrl      = {};
	if ( $self->GetExistCvrl( "top", $topCvrl ) ) {

		$t += $topCvrl->{"adhesiveThick"} * $adhReduction;
		$t += $topCvrl->{"cvrlThick"};
	}

	my $botCvrl = {};
	if ( $self->GetExistCvrl( "bot", $botCvrl ) ) {

		$t += $botCvrl->{"adhesiveThick"} * $adhReduction;
		$t += $botCvrl->{"cvrlThick"};
	}

	return $t;

}

# Thickness requested by customer
sub GetNominalThickness {
	my $self = shift;

	my $t = $self->{"pcbInfoIS"}->{"material_tloustka"};
	if ( defined $t && $t ne "" ) {

		$t =~ s/,/\./;
		$t *= 1000;
	}

	return $t;

}

sub GetFlexPCBCode {
	my $self = shift;

	my $pcbType = $self->GetPcbType();
	my $code    = undef;
	if ( $pcbType eq EnumsGeneral->PcbType_1VFLEX ) {
		$code = "1F";
	}
	elsif ( $pcbType eq EnumsGeneral->PcbType_2VFLEX ) {
		$code = "2F";
	}
	elsif ( $pcbType eq EnumsGeneral->PcbType_MULTIFLEX ) {
		$code = $self->GetLayerCnt() . "F";
	}

	return $code;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

