
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::ProcessStackup::StackupMngr::StackupMngrBase;

#3th party library
use strict;
use warnings;
use List::Util qw(first min);
use DateTime::Format::Strptime;
use DateTime;

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
use aliased 'Packages::CAMJob::Stackup::ProcessStackup::Enums';
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
	my @orders = HegMethods->GetPcbOrderNumbers( $self->{"jobId"} );
	@orders = grep { $_->{"stav"} !~ /^[57]$/ } @orders;    # not ukoncena and stornovana
	if ( scalar(@orders) ) {

		@orders = sort { int( $a->{"reference_subjektu"} ) <=> int( $b->{"reference_subjektu"} ) } @orders;
		my $orderId = $orders[0]{"reference_subjektu"};
		$self->{"orderId"} = $orderId;
		$self->{"orderInfoIS"} = {HegMethods->GetAllByOrderId($orderId)};
	}

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

	my $orderName = $self->{"jobId"}."-(no active order)";
	
	if(defined $self->{"orderId"}){
		$orderName = $self->{"orderId"};
	}

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

	my $dateTerm = " (no active order)";

	if ( defined $self->{"orderInfoIS"} ) {

		my $pattern = DateTime::Format::Strptime->new( pattern => '%Y-%m-%d %H:%M:%S', );

		$dateTerm = $pattern->parse_datetime( $self->{"orderInfoIS"}->{"termin"} )->dmy('.');    # order term

	}

	return $dateTerm;
}

sub GetOrderDate {
	my $self = shift;

	my $dateStart = " (no active order)";

	if ( defined $self->{"orderInfoIS"} ) {

		my $pattern = DateTime::Format::Strptime->new( pattern => '%Y-%m-%d %H:%M:%S', );
		$dateStart = $pattern->parse_datetime( $self->{"orderInfoIS"}->{"datum_zahajeni"} )->dmy('.');    # start order date

	}

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
#	my $l = $side eq "top" ? "mc" : "ms";
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
#	my $l = $side eq "top" ? "mcflex" : "msflex";
#
#	my $smExist = defined( first { $_->{"gROWname"} eq $l } @{ $self->{"boardBaseLayers"} } ) ? 1 : 0;
#
#	if ( $smExist && defined $info ) {
#
#		$info->{"text"}  = "UV Green";
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
#
#sub GetPlatedNC {
#	my $self = shift;
#
#	my @NC = grep { $_->{"plated"} && !$_->{"technical"} } @{ $self->{"NCLayers"} };
#
#	my $sigLCnt = CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $self->{"jobId"} );
#
#	my @sorted = ();
#
#	# Sorting normal through frilling
#	push( @sorted, grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nDrill     && $_->{"NCSigStartOrder"} == 1 } @NC );
#	push( @sorted, grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nFillDrill && $_->{"NCSigStartOrder"} == 1 } @NC );
#	push( @sorted, grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nDrill     && $_->{"NCSigStartOrder"} > 1 } @NC );
#	push( @sorted, grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nFillDrill && $_->{"NCSigStartOrder"} > 1 } @NC );
#
#	# sorting blind drill from top (first drill which start at top layer)
#	push( @sorted, grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillTop     && $_->{"NCSigStartOrder"} == 1 } @NC );
#	push( @sorted, grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bFillDrillTop && $_->{"NCSigStartOrder"} == 1 } @NC );
#	push( @sorted, grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillTop     && $_->{"NCSigStartOrder"} > 1 } @NC );
#	push( @sorted, grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bFillDrillTop && $_->{"NCSigStartOrder"} > 1 } @NC );
#
#	push( @sorted, grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillBot     && $_->{"NCSigStartOrder"} == $sigLCnt } @NC );
#	push( @sorted, grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bFillDrillBot && $_->{"NCSigStartOrder"} == $sigLCnt } @NC );
#	push( @sorted, grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillBot     && $_->{"NCSigStartOrder"} < $sigLCnt } @NC );
#	push( @sorted, grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bFillDrillBot && $_->{"NCSigStartOrder"} < $sigLCnt } @NC );
#
#	push( @sorted, grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_cDrill } @NC );
#	push( @sorted, grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_cFillDrill } @NC );
#
#	return @sorted;
#}
#
sub GetExistStiff {
	my $self     = shift;
	my $side     = shift;    # top/bot
	my $stifInfo = shift;    # reference for storing info

	my $l = $side eq "top" ? "stiffc" : "stiffs";

	my $exist = defined( first { $_->{"gROWname"} eq $l } @{ $self->{"boardBaseLayers"} } ) ? 1 : 0;

	if ($exist) {

		if ( defined $stifInfo ) {

			my $mInf = HegMethods->GetPcbStiffenerMat( $self->{"jobId"} );
			$stifInfo->{"adhesiveISRef"} = "0319000045";
			$stifInfo->{"adhesiveKind"}  = "";
			$stifInfo->{"adhesiveText"}  = "3M 467MP tape";
			$stifInfo->{"adhesiveThick"} = 50;                # ? is not store
			$stifInfo->{"adhesiveTg"}    = 204;

			my @n = split( /\s/, $mInf->{"nazev_subjektu"} );
			shift(@n) if ( $n[0] =~ /lam/i );
			
			$_ =~ s/mm//gi foreach (@n);
			

			$stifInfo->{"stiffISRef"} = $mInf->{"reference_subjektu"};
			$stifInfo->{"stiffKind"}  = $n[0];
			$stifInfo->{"stiffText"}  = $n[2] . "mm " . $n[1];
			my $t = $n[2];
			$t =~ s/,/\./;
			$t *= 1000;

			$stifInfo->{"stiffThick"} = $t;      # µm
			$stifInfo->{"stiffTg"}    = undef;

			# Try to get TG of stiffener adhesive
			my $matKey = first { $mInf->{"nazev_subjektu"} =~ /$_/i } keys %{ $self->{"isMatKinds"} };
			if ( defined $matKey ) {
				$stifInfo->{"stiffTg"} = $self->{"isMatKinds"}->{$matKey};
			}

			die "Stiffener adhesive material name was not found at material:" . $mInf->{"nazev_subjektu"}
			  unless ( defined $stifInfo->{"adhesiveText"} );
			die "Stiffener adhesive material thick was not found at material:" . $mInf->{"nazev_subjektu"}
			  unless ( defined $stifInfo->{"adhesiveThick"} );
			die "Stiffener material name was not found at material:" . $mInf->{"nazev_subjektu"} unless ( defined $stifInfo->{"stiffText"} );
			die "Stiffener thickness was not found at material:" . $mInf->{"nazev_subjektu"}     unless ( defined $stifInfo->{"stiffThick"} );
			die "Stiffener TG was not found at material:" . $mInf->{"nazev_subjektu"}            unless ( defined $stifInfo->{"stiffTg"} );
		}
	}

	return $exist;

}
 
sub GetSteelPlateInfo {
	my $self = shift;

	my $inf = {};

	$inf->{"ISRef"} = undef;
	$inf->{"text"}  = "Sttel plate";
	$inf->{"thick"} = 1000;            # 1000µm

	return $inf;
}

sub GetAluPlateInfo {
	my $self = shift;

	my $inf = {};

	$inf->{"ISRef"} = "0401000021";
	$inf->{"text"}  = "ALU entry  boards A18,";
	$inf->{"thick"} = 200;            # 1000µm

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

	my $isId = "0318000019";
	my $inf  = $self->__GetPresspadInfo($isId);

	return $inf;
}

sub GetPressPadFF10NInfo {
	my $self = shift;

	my $isId = "0318000018";
	my $inf  = $self->__GetPresspadInfo($isId);

	return $inf;
}

sub GetPresspad5500Info {
	my $self = shift;

	my $isId = "0319000029";
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

	die "Pad material name was not found for material IS reference:" . $matRef  unless ( defined $inf->{"text"} );
	die "Pad material thick was not found for material IS reference:" . $matRef unless ( defined $inf->{"thick"} );

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

sub GetCuLayerCnt{
	my $self = shift;
	
	return CamJob->GetSignalLayerCnt($self->{"inCAM"}, $self->{"jobId"});
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
#	if ( $self->GetExistStiff( "top", $infStiffTop ) ) {
#
#		push( @allTg, $infStiffTop->{"adhesiveTg"} ) if ( defined $infStiffTop->{"adhesiveTg"} );
#		push( @allTg, $infStiffTop->{"stiffTg"} )    if ( defined $infStiffTop->{"stiffTg"} );
#	}
#
#	my $infStiffBot = {};
#	if ( $self->GetExistStiff( "bot", $infStiffBot ) ) {
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

