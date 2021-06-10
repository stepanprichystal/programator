
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Traveler::ProcessStackupTmpl::StackupMngr::StackupMngrVV;
use base('Packages::CAMJob::Traveler::ProcessStackupTmpl::StackupMngr::StackupMngrBase');

#3th party library
use utf8;
use strict;
use warnings;
use List::Util qw(first min);
use List::MoreUtils qw(uniq);

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Packages::Polygon::Features::Features::Features';
use aliased 'Packages::CAMJob::Traveler::ProcessStackupTmpl::Enums';
use aliased 'Packages::CAMJob::Traveler::ProcessStackupTmpl::StackupLam::StackupLam';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	$self->{"stackup"} = Stackup->new( $self->{"inCAM"}, $self->{"jobId"} );

	return $self;
}

sub GetAllLamination {
	my $self    = shift;
	my $lamType = shift;

	my $stackup = $self->{"stackup"};

	my @inputProduct = $stackup->GetInputProducts();

	my @pressProduct = $stackup->GetPressProducts(1);

	my @lamintaions = ();

	my $lamOrder = 0;

	# Process input product laminations

	# Sordt input products by "core type". Rigid frist, tahn flex

	my @rigid = grep { $_->GetCoreRigidType() eq StackEnums->CoreType_RIGID } @inputProduct;
	my @flex  = grep { $_->GetCoreRigidType() eq StackEnums->CoreType_FLEX } @inputProduct;

	@inputProduct = ();
	push( @inputProduct, @rigid ) if ( scalar(@rigid) );
	push( @inputProduct, @flex )  if ( scalar(@flex) );

	foreach my $inputP (@inputProduct) {

		my @matLayers = $inputP->GetLayers( StackEnums->ProductL_MATERIAL );

		# Process lamination if there are some material layers
		#(which means there is material to press together)
		if ( scalar(@matLayers) ) {

			my $lamType;
			if ( $inputP->GetCoreRigidType() eq StackEnums->CoreType_RIGID ) {

				$lamType = Enums->LamType_RIGIDBASE;
			}
			elsif ( $inputP->GetCoreRigidType() eq StackEnums->CoreType_FLEX ) {

				$lamType = Enums->LamType_FLEXBASE;
			}

			my $lam = StackupLam->new( $lamOrder, $lamType, "P" . $inputP->GetId(), $inputP );
			push( @lamintaions, $lam );

			$lamOrder++;
		}
	}

	# Process press product laminations
	foreach my $pressP (@pressProduct) {

		my @layers = $pressP->GetLayers( StackEnums->ProductL_PRODUCT );

		my $lamType = undef;

		if ( $self->GetPcbType() eq EnumsGeneral->PcbType_MULTI ) {
			$lamType = Enums->LamType_RIGIDFINAL;
		}
		elsif ( $self->GetPcbType() eq EnumsGeneral->PcbType_RIGIDFLEXI || $self->GetPcbType() eq EnumsGeneral->PcbType_MULTIFLEX ) {
			$lamType = Enums->LamType_IRIGIDFLEXFINAL;
		}
		elsif ( $self->GetPcbType() eq EnumsGeneral->PcbType_RIGIDFLEXO ) {
			$lamType = Enums->LamType_ORIGIDFLEXFINAL;
		}

		my $lam = StackupLam->new( $lamOrder, $lamType, "DPS" . $pressP->GetId(), $pressP );
		push( @lamintaions, $lam );

		$lamOrder++;

		# Check if press contain extra lamination
		if ( $pressP->GetExistExtraPress() ) {

			my $lam = StackupLam->new( $lamOrder, Enums->LamType_CVRLPRODUCT, "DPS" . $pressP->GetId(), $pressP );
			push( @lamintaions, $lam );

			$lamOrder++;

		}
	}

	# Filter laminations by type
	if ( defined $lamType ) {
		@lamintaions = grep { $_->GetLamType() eq $lamType } @lamintaions;
	}

	return @lamintaions;
}

sub GetCoreISRef {
	my $self           = shift;
	my $stckpCoreLayer = shift;

	my $topCuLayer = $stckpCoreLayer->GetTopCopperLayer();

	return $self->__GetMatRefByUDA( "core_", $stckpCoreLayer->GetQId(), $stckpCoreLayer->GetId(), $topCuLayer->GetId() );
}

sub GetCuFoilISRef {
	my $self         = shift;
	my $stckpCuLayer = shift;

	return $self->__GetMatRefByUDA( "cu", $stckpCuLayer->GetId() );
}

sub GetPrpgISRef {
	my $self           = shift;
	my $stckpPrpgLayer = shift;

	return $self->__GetMatRefByUDA( "prpg", $stckpPrpgLayer->GetQId(), $stckpPrpgLayer->GetId() );
}

# Return fake IS ref, but unique for each material type
sub __GetMatRefByUDA {
	my $self = shift;
	my $type = shift;
	my $qId  = shift;
	my $id   = shift;
	my $id2  = shift;

	#my $inf = HegMethods->GetMatInfoByUDA( $qId, $id, $id2 );
	my $str = $type;
	$str .= "_" . $qId if ( defined $qId );
	$str .= "_" . $id  if ( defined $id );
	$str .= "_" . $id2 if ( defined $id2 );
	return $str;
}

sub GetBaseMaterialInfo {
	my $self = shift;

	my @mats = ();

	my @mat = uniq( map { $_->GetTextType() } $self->{"stackup"}->GetAllCores() );

	for ( my $i = 0 ; $i < scalar(@mat) ; $i++ ) {

		$mat[$i] =~ s/\s//g;
	}

	foreach my $m (@mat) {

		my $matKey = first { $m =~ /$_/i } keys %{ $self->{"isMatKinds"} };
		next unless ( defined $matKey );

		push( @mats, { "kind" => $matKey, "tg" => $self->{"isMatKinds"}->{$matKey} } );

	}
	return @mats;
}

sub GetPressProgramInfo {
	my $self     = shift;
	my $lamType  = shift;
	my $IProduct = shift;

	my ( $w, $h ) = $self->GetPanelSize();
	my @mats = $self->GetBaseMaterialInfo();

	my %pInfo = ( "name" => undef, "dimX" => undef, "dimY" => undef );

	# 1) Program name

	if ( $lamType eq Enums->LamType_STIFFPRODUCT ) {

		$pInfo{"name"} = "Stiffener_tape";

	}
	elsif ( $lamType eq Enums->LamType_ORIGIDFLEXFINAL
			|| $lamType eq Enums->LamType_IRIGIDFLEXFINAL
	  )
	{

		$pInfo{"name"} = "Flex";

	}
	elsif (    $lamType eq Enums->LamType_CVRLPRODUCT
			|| $lamType eq Enums->LamType_FLEXBASE )
	{

		$pInfo{"name"} = "Flex_coverlay";

	}
	elsif ( $lamType eq Enums->LamType_RIGIDBASE || $lamType eq Enums->LamType_RIGIDFINAL ) {

		# Choose proper program by prepreg material kind
		# $IProduct should by tzpe of Product_INPUT
		my @matLayers = grep { $_->GetType() eq StackEnums->ProductL_MATERIAL } $IProduct->GetLayers();
		my @prpgs = grep { $_->GetType() eq StackEnums->MaterialType_PREPREG } map { $_->GetData() } @matLayers;
		my $matKind = uc( $prpgs[0]->GetTextType() );
		$matKind =~ s/\s//g;

		$pInfo{"name"} = $matKind;

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

#sub GetLayerCnt {
#	my $self = shift;
#
#	return $self->{"stackup"}->GetCuLayerCnt();
#
#}
#
sub GetStackup {
	my $self = shift;

	return $self->{"stackup"};
}
#
## Return stackup layers(exceot top/bottom coverlay)
#sub GetStackupLayers {
#	my $self = shift;
#
#	my @l = $self->{"stackup"}->GetAllLayers();
#
#	shift(@l) if ( $l[0]->GetType() eq StackEnums->MaterialType_COVERLAY );
#	pop(@l)   if ( $l[-1]->GetType() eq StackEnums->MaterialType_COVERLAY );
#
#	return @l;
#
#}
#
sub GetExistCvrl {
	my $self = shift;
	my $side = shift;    # top/bot
	my $info = shift;    # reference for storing info

	my $exist = 0;

	my @l = $self->{"stackup"}->GetAllLayers();

	my $sigName = undef;
	if ( $side eq "top" ) {
		$sigName = "c";
	}
	elsif ( $side eq "bot" ) {
		$sigName = "s";
	}

	@l = reverse(@l) if ( $side eq "bot" );

	for ( my $i = 0 ; $i < scalar(@l) ; $i++ ) {

		if (    $l[$i]->GetType() eq StackEnums->MaterialType_COVERLAY
			 && defined $l[ $i + 1 ]
			 && $l[ $i + 1 ]->GetType() eq StackEnums->MaterialType_COPPER
			 && $l[ $i + 1 ]->GetCopperName() eq $sigName )
		{
			$exist = 1;

			if ( defined $info ) {
				$self->GetCvrlInfo( $l[$i], $info );
			}
			last;
		}
	}

	return $exist;
}

sub GetCvrlInfo {
	my $self   = shift;
	my $stckpL = shift;
	my $inf    = shift // {};

	$inf->{"adhesiveText"}  = "";
	$inf->{"adhesiveThick"} = $stckpL->GetAdhesiveThick();
	$inf->{"cvrlText"}      = $stckpL->GetTextType() . " " . $stckpL->GetText();
	$inf->{"cvrlThick"} =
	  $stckpL->GetThick(0) - $stckpL->GetAdhesiveThick();    # Return real thickness from base class (not consider if covelraz is selective)
	$inf->{"selective"} = $stckpL->GetMethod() eq StackEnums->Coverlay_SELECTIVE ? 1 : 0;

	# Fake is ref
	$inf->{"cvrlISRef"} = $self->__GetMatRefByUDA( "cvrl", $inf->{"adhesiveThick"}, $inf->{"cvrlThick"} );

	die "Cvrl adhesive material name was not found at material:" . $stckpL->GetText()
	  unless ( defined $inf->{"adhesiveText"} );
	die "Coverlay adhesive material thick was not found at material:" . $stckpL->GetText()
	  unless ( defined $inf->{"adhesiveThick"} );
	die "Coverlay material name was not found at material:" . $stckpL->GetText()          unless ( defined $inf->{"cvrlText"} );
	die "Coverlay thickness was not found at material:" . $stckpL->GetText()              unless ( defined $inf->{"cvrlThick"} );
	die "Coverlay type (selective or not)was not found at material:" . $stckpL->GetText() unless ( defined $inf->{"selective"} );

	return $inf;
}

sub GetPrepregTitle {
	my $self  = shift;
	my $l     = shift;
	my $types = shift;

	my $t = $l->GetTextType();
	$t =~ s/\s//g;
	my %childPCnt = ();

	foreach my $childP ( $l->GetAllPrepregs() ) {

		my $type = $childP->GetText();
		$type =~ s/\s//g;
		if ( $type !~ m/^(\d+)\s*(\[.*\])*/i ) {
			die "Prepreg text:" . $l->GetText() . " doesn't have valid format";
		}

		add gap if there is bracket $type =~ s/\[/ [/;

		if ( defined $childPCnt{$type} ) {
			$childPCnt{$type}++;
		}
		else {
			$childPCnt{$type} = 1;
		}
	}

	if ( scalar( keys %childPCnt ) == 1 ) {
		$t .= join( "+", map { $childPCnt{$_} . "x" . $_ } keys %childPCnt );
	}

	push( @{$types}, map { $childPCnt{$_} . "x" . $_ } keys %childPCnt );

	return $t;

}
#
#sub GetTG {
#	my $self = shift;
#
#	my $matKind = HegMethods->GetMaterialKind( $self->{"jobId"}, 1 );
#
#	my $minTG = undef;
#
#	# 1) Get min TG of PCB
#	if ( $matKind =~ /tg\s*(\d+)/i ) {
#
#		# single kinf of stackup materials
#
#		$minTG = $1;
#	}
#	elsif ( $matKind =~ /.*-.*/ ) {
#
#		# hybrid material stackups
#
#		my @mat = uniq( map { $_->GetTextType() } $self->{"stackup"}->GetAllCores() );
#
#		for ( my $i = 0 ; $i < scalar(@mat) ; $i++ ) {
#
#			$mat[$i] =~ s/\s//g;
#		}
#
#		foreach my $m (@mat) {
#
#			my $matKey = first { $m =~ /$_/i } keys %{ $self->{"isMatKinds"} };
#			next unless ( defined $matKey );
#
#			if ( !defined $minTG || $self->{"isMatKinds"}->{$matKey} < $minTG ) {
#				$minTG = $self->{"isMatKinds"}->{$matKey};
#			}
#		}
#	}
#
#	# 2) Get min TG of estra layers (stiffeners/double coated tapes etc..)
#	my $specTg = $self->_GetSpecLayerTg();
#
#	if ( defined $minTG && defined $specTg ) {
#		$minTG = min( ( $minTG, $specTg ) );
#	}
#
#	return $minTG;
#}
#
#sub GetIsInnerLayerEmpty {
#	my $self  = shift;
#	my $lName = shift;
#
#	return $self->{"inLayerEmpty"}->{$lName};
#
#}
#
#sub __SetIsInnerLayerEmpty {
#	my $self = shift;
#
#	my @steps = ();
#
#	my $inCAM = $self->{"inCAM"};
#	my $jobId = $self->{"jobId"};
#
#	if ( CamStepRepeat->ExistStepAndRepeats( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"} ) ) {
#
#		@steps = CamStepRepeat->GetUniqueDeepestSR( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"} );
#		CamStepRepeat->RemoveCouponSteps( \@steps );
#		@steps = map { $_->{"stepName"} } @steps;
#	}
#	else {
#		@steps = ("o+1");
#	}
#
#	my %inLayers = ();
#	my @layers   = $self->GetStackupLayers();
#
#	for ( my $i = 0 ; $i < scalar(@layers) ; $i++ ) {
#
#		my $l = $layers[$i];
#
#		if ( $l->GetType() eq StackEnums->MaterialType_COPPER ) {
#
#			my $isEmpty = 1;
#			my $f       = Features->new();
#			foreach my $step (@steps) {
#
#				$f->Parse( $inCAM, $jobId, $step, $l->GetCopperName(), 0, 0 );
#
#				if ( defined first { !defined $_->{"attr"}->{".string"} } grep { $_->{"polarity"} eq "P" } $f->GetFeatures() ) {
#					$isEmpty = 0;
#					last;
#				}
#			}
#
#			$inLayers{ $l->GetCopperName() } = $isEmpty;
#
#		}
#	}
#
#	return %inLayers;
#}
#
## Real PCB thickness
#sub GetThickness {
#	my $self = shift;
#
#	my $t = $self->{"stackup"}->GetFinalThick();
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
#	return $t;
#
#}
#
#sub GetNominalThickness {
#	my $self = shift;
#
#	return $self->{"stackup"}->GetNominalThickness();
#
#}
#
#sub GetThicknessStiffener {
#	my $self = shift;
#
#	my $t = $self->GetThicknessFlex();
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
#}
#
#sub GetThicknessFlex {
#	my $self = shift;
#
#	my $t = 0;
#
#	my @layers = $self->{"stackup"}->GetAllLayers();
#
#	for ( my $i = 0 ; $i < scalar(@layers) ; $i++ ) {
#
#		my $l = $layers[$i];
#
#		if ( $l->GetType() eq StackEnums->MaterialType_COPPER ) {
#
#			next if ( $self->GetIsInnerLayerEmpty( $l->GetCopperName() ) );
#
#			my $isFlex = 0;
#			my $c = !$l->GetIsFoil() ? $self->{"stackup"}->GetCoreByCuLayer( $l->GetCopperName ) : undef;
#			if ( defined $c && $c->GetCoreRigidType() eq StackEnums->CoreType_FLEX ) {
#				$isFlex = 1;
#			}
#
#			my $lInfo = first { $_->{"gROWname"} eq $l->GetCopperName() } $self->GetBoardBaseLayers();
#
#			$t += $l->GetThick();
#			$t += 25 if ( $self->GetIsPlated($lInfo) );
#
#		}
#		elsif ( $l->GetType() eq StackEnums->MaterialType_PREPREG ) {
#
#			# Do distinguish between Noflow Prepreg 1 which insluding coverlay and others prepregs
#			if ( $l->GetIsNoFlow() && $l->GetNoFlowType() eq StackEnums->NoFlowPrepreg_P1 ) {
#
#				$t += $l->GetThick();
#			}
#
#		}
#		elsif ( $l->GetType() eq StackEnums->MaterialType_CORE ) {
#
#			$t += $l->GetThick() if ( $l->GetCoreRigidType() eq StackEnums->CoreType_FLEX );
#
#		}
#	}
#
#	return $t;
#}
#
#sub GetFlexPCBCode {
#	my $self = shift;
#
#	my $pcbType = $self->GetPcbType();
#	my $code    = undef;
#	if (    $pcbType eq EnumsGeneral->PcbType_RIGIDFLEXO
#		 || $pcbType eq EnumsGeneral->PcbType_RIGIDFLEXI )
#	{
#
#		my @layers    = $self->GetStackupLayers();
#		my @codeParts = ();
#		my $curPart   = undef;
#		my $cuPartCnt = 0;
#		for ( my $i = 0 ; $i < scalar(@layers) ; $i++ ) {
#
#			my $l = $layers[$i];
#
#			if ( $l->GetType() eq StackEnums->MaterialType_COPPER && !$self->GetIsInnerLayerEmpty( $l->GetCopperName ) ) {
#
#				my $c = !$l->GetIsFoil() ? $self->GetStackup()->GetCoreByCuLayer( $l->GetCopperName ) : undef;
#				my $isFlex = ( defined $c && $c->GetCoreRigidType() eq StackEnums->CoreType_FLEX ) ? 1 : 0;
#				my $newPart = $isFlex ? "F" : "Ri";
#
#				if ( !defined $curPart ) {
#					$curPart = $newPart;
#				}
#				elsif ( defined $curPart && $curPart ne $newPart ) {
#
#					push( @codeParts, $cuPartCnt . $curPart );
#
#					$curPart   = $newPart;
#					$cuPartCnt = 0;
#				}
#
#				$cuPartCnt++;
#			}
#		}
#
#		push( @codeParts, $cuPartCnt . $curPart );
#
#		$code = join( "-", @codeParts );
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

