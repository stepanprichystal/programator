
#-------------------------------------------------------------------------------------------#
# Description: Base class for BIF builders. Nif Builder is responsible for
# creation nif file depend on pcb type
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::CustStackup::StackupMngr::StackupMngrBase;

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
	$self->{"nifFile"}   = NifFile->new( $self->{"jobId"} );

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

sub GetExistSM {
	my $self = shift;
	my $side = shift;    # top/bot
	my $info = shift;    # reference to store additional information

	my $l = $side eq "top" ? "mc" : "ms";

	my $smExist = defined( first { $_->{"gROWname"} eq $l } @{ $self->{"boardBaseLayers"} } ) ? 1 : 0;

	if ( $smExist && defined $info ) {

		my %mask = $self->__GetMaskColor();
		$info->{"color"} = ValueConvertor->GetMaskCodeToColor( $mask{$side} );

	}

	return $smExist;
}

sub GetExistSMFlex {
	my $self = shift;
	my $side = shift;    # top/bot
	my $info = shift;    # reference to store additional information

	my $l = $side eq "top" ? "mcflex" : "msflex";

	my $smExist = defined( first { $_->{"gROWname"} eq $l } @{ $self->{"boardBaseLayers"} } ) ? 1 : 0;

	if ( $smExist && defined $info ) {

		$info->{"text"}  = "UV Green";
		$info->{"thick"} = 25;

	}

	return $smExist;

}

sub GetPcbType {
	my $self = shift;

	return $self->{"pcbType"};
}

sub GetPlatedNC {
	my $self = shift;

	my @NC = grep { $_->{"plated"} && !$_->{"technical"} } @{ $self->{"NCLayers"} };

	my $sigLCnt = CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $self->{"jobId"} );

	my @sorted = ();

	# Sorting normal through frilling
	push( @sorted, grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nDrill     && $_->{"NCSigStartOrder"} == 1 } @NC );
	push( @sorted, grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nFillDrill && $_->{"NCSigStartOrder"} == 1 } @NC );
	push( @sorted, grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nDrill     && $_->{"NCSigStartOrder"} > 1 } @NC );
	push( @sorted, grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nFillDrill && $_->{"NCSigStartOrder"} > 1 } @NC );

	# sorting blind drill from top (first drill which start at top layer)
	push( @sorted, grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillTop     && $_->{"NCSigStartOrder"} == 1 } @NC );
	push( @sorted, grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bFillDrillTop && $_->{"NCSigStartOrder"} == 1 } @NC );
	push( @sorted, grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillTop     && $_->{"NCSigStartOrder"} > 1 } @NC );
	push( @sorted, grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bFillDrillTop && $_->{"NCSigStartOrder"} > 1 } @NC );

	push( @sorted, grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillBot     && $_->{"NCSigStartOrder"} == $sigLCnt } @NC );
	push( @sorted, grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bFillDrillBot && $_->{"NCSigStartOrder"} == $sigLCnt } @NC );
	push( @sorted, grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillBot     && $_->{"NCSigStartOrder"} < $sigLCnt } @NC );
	push( @sorted, grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bFillDrillBot && $_->{"NCSigStartOrder"} < $sigLCnt } @NC );

	push( @sorted, grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_cDrill } @NC );
	push( @sorted, grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_cFillDrill } @NC );

	return @sorted;
}

sub GetExistStiff {
	my $self     = shift;
	my $side     = shift;    # top/bot
	my $stifInfo = shift;    # reference for storing info

	my $l = $side eq "top" ? "stiffc" : "stiffs";

	my $exist = defined( first { $_->{"gROWname"} eq $l } @{ $self->{"boardBaseLayers"} } ) ? 1 : 0;

	if ($exist) {

		if ( defined $stifInfo ) {

			my $matInfo = HegMethods->GetPcbStiffenerMat( $self->{"jobId"} );

			$stifInfo->{"adhesiveText"}  = "3M tape";
			$stifInfo->{"adhesiveThick"} = 50;          # ? is not store
			$stifInfo->{"adhesiveTg"}    = undef;

			my @n = split( /\s/, $matInfo->{"nazev_subjektu"} );
			shift(@n) if ( $n[0] =~ /^Lam/i );

			$stifInfo->{"stiffText"} = $n[0];           # ? is not store
			$n[2] =~ s/,/\./;
			$stifInfo->{"stiffThick"} = int( $n[2] * 1000 );    # µm
			$stifInfo->{"stiffTg"}    = undef;

			# Try to get TG of stiffener adhesive
			my $matKey = first { $stifInfo->{"stiffText"} =~ /$_/i } keys %{ $self->{"isMatKinds"} };
			if ( defined $matKey ) {
				$stifInfo->{"stiffTg"} = $self->{"isMatKinds"}->{$matKey};
			}
		}
	}

	return $exist;

}

# Decide of get mask color ftom NIF/Helios
sub __GetMaskColor {
	my $self       = shift;
	my $secondMask = shift;

	my $jobId   = $self->{"jobId"};
	my $nifFile = NifFile->new($jobId);

	my %mask = ();

	if ( $nifFile->Exist() ) {

		# use nif file
		%mask = $nifFile->GetSolderMaskColor();

		# check if exist second mask in IS
		if ($secondMask) {

			%mask = HegMethods->GetSolderMaskColor2($jobId);
		}
	}
	else {
		# use nif norris
		%mask = $secondMask ? HegMethods->GetSolderMaskColor2($jobId) : HegMethods->GetSolderMaskColor($jobId);

	}

	return %mask;
}

sub GetIsPlated {
	my $self     = shift;
	my $sigLayer = shift;

	my %sett = $self->{"layerSett"}->GetDefSignalLSett($sigLayer);

	my $isPlated = 0;

	if ( $sett{"technologyType"} eq EnumsGeneral->Technology_GALVANICS ) {
		$isPlated = 1;
	}
	return $isPlated;

}

sub GetIsFlex {
	my $self = shift;

	return $self->{"isFlex"};
}

sub GetBoardBaseLayers {
	my $self = shift;

	return @{ $self->{"boardBaseLayers"} };
}

# Return TG of layer stiffener, adhesive, ...
sub _GetSpecLayerTg {
	my $self = shift;

	my @allTg = ();

	my $infStiffTop = {};
	if ( $self->GetExistStiff( "top", $infStiffTop ) ) {

		push( @allTg, $infStiffTop->{"adhesiveTg"} ) if ( defined $infStiffTop->{"adhesiveTg"} );
		push( @allTg, $infStiffTop->{"stiffTg"} )    if ( defined $infStiffTop->{"stiffTg"} );
	}

	my $infStiffBot = {};
	if ( $self->GetExistStiff( "bot", $infStiffBot ) ) {

		push( @allTg, $infStiffBot->{"adhesiveTg"} ) if ( defined $infStiffBot->{"adhesiveTg"} );
		push( @allTg, $infStiffBot->{"stiffTg"} )    if ( defined $infStiffBot->{"stiffTg"} );
	}

	return min(@allTg);
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

