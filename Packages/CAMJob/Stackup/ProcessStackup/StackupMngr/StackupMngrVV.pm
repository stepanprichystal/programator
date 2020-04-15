
#-------------------------------------------------------------------------------------------#
# Description:  
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::ProcessStackup::StackupMngr::StackupMngrVV;
use base('Packages::CAMJob::Stackup::CustStackup::StackupMngr::StackupMngrBase');

#3th party library
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

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	$self->{"stackup"} = Stackup->new( $self->{"inCAM"}, $self->{"jobId"} );
	$self->{"inLayerEmpty"} = { $self->__SetIsInnerLayerEmpty() };

	return $self;
}

#sub GetLayerCnt {
#	my $self = shift;
#
#	return $self->{"stackup"}->GetCuLayerCnt();
#
#}
#
#sub GetStackup {
#	my $self = shift;
#
#	return $self->{"stackup"};
#}
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
#sub GetExistCvrl {
#	my $self   = shift;
#	my $side   = shift;    # top/bot
#	my $info   = shift;    # reference for storing info
#	my $stckpL = shift;
#
#	my $exist = 0;
#
#	my @l = $self->{"stackup"}->GetAllLayers();
#
#	my $sigName = undef;
#	if ( $side eq "top" ) {
#		$sigName = "c";
#	}
#	elsif ( $side eq "bot" ) {
#		$sigName = "s";
#	}
#
#	@l = reverse(@l) if ( $side eq "bot" );
#
#	for ( my $i = 0 ; $i < scalar(@l) ; $i++ ) {
#
#		if (    $l[$i]->GetType() eq StackEnums->MaterialType_COVERLAY
#			 && defined $l[ $i + 1 ]
#			 && $l[ $i + 1 ]->GetType() eq StackEnums->MaterialType_COPPER
#			 && $l[ $i + 1 ]->GetCopperName() eq $sigName )
#		{
#			$exist = 1;
#
#			if ( defined $info ) {
#				$self->GetCvrlInfo( $l[$i], $info );
#			}
#			last;
#		}
#	}
#
#	return $exist;
#}
#
#sub GetCvrlInfo {
#	my $self   = shift;
#	my $stckpL = shift;
#	my $inf    = shift // {};
#
#	$inf->{"adhesiveText"}  = "";
#	$inf->{"adhesiveThick"} = $stckpL->GetAdhesiveThick();
#	$inf->{"cvrlText"}      = $stckpL->GetTextType() . " " . $stckpL->GetText();
#	$inf->{"cvrlThick"} =
#	  $stckpL->GetThick(0) - $stckpL->GetAdhesiveThick();    # Return real thickness from base class (not consider if covelraz is selective)
#	$inf->{"selective"} = $stckpL->GetMethod() eq StackEnums->Coverlay_SELECTIVE ? 1 : 0;
#
#	die "Cvrl adhesive material name was not found at material:" . $stckpL->GetText()
#	  unless ( defined $inf->{"adhesiveText"} );
#	die "Coverlay adhesive material thick was not found at material:" . $stckpL->GetText()
#	  unless ( defined $inf->{"adhesiveThick"} );
#	die "Coverlay material name was not found at material:" . $stckpL->GetText()          unless ( defined $inf->{"cvrlText"} );
#	die "Coverlay thickness was not found at material:" . $stckpL->GetText()              unless ( defined $inf->{"cvrlThick"} );
#	die "Coverlay type (selective or not)was not found at material:" . $stckpL->GetText() unless ( defined $inf->{"selective"} );
#
#	return $inf;
#}
#
#sub GetPrepregTitle {
#	my $self  = shift;
#	my $l     = shift;
#	my $types = shift;
#
#	my $t = $l->GetTextType();
#	$t =~ s/\s//g;
#	my %childPCnt = ();
#
#	foreach my $childP ( $l->GetAllPrepregs() ) {
#
#		my $type = $childP->GetText();
#		$type =~ s/\s//g;
#		if ( $type !~ m/^(\d+)\s*(\[.*\])*/i ) {
#			die "Prepreg text:" . $l->GetText() . " doesn't have valid format";
#		}
#
#		# add gap if there is bracket
#		$type =~ s/\[/ [/;
#
#		if ( defined $childPCnt{$type} ) {
#			$childPCnt{$type}++;
#		}
#		else {
#			$childPCnt{$type} = 1;
#		}
#	}
#
#	#	if ( scalar( keys %childPCnt ) == 1 ) {
#	#		$t .= join( "+", map { $childPCnt{$_} . "x" . $_ } keys %childPCnt );
#	#	}
#
#	push( @{$types}, map { $childPCnt{$_} . "x" . $_ } keys %childPCnt );
#
#	return $t;
#
#}
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

