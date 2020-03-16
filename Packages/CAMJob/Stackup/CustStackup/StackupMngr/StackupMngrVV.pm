
#-------------------------------------------------------------------------------------------#
# Description: Nif Builder is responsible for creation nif file depend on pcb type
# Builder for pcb no copper
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::CustStackup::StackupMngr::StackupMngrVV;
use base('Packages::CAMJob::Stackup::CustStackup::StackupMngr::StackupMngrBase');

#3th party library
use strict;
use warnings;
use List::Util qw(first min);
use List::MoreUtils qw(uniq);

#local library

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

	return $self;
}

sub GetLayerCnt {
	my $self = shift;

	return $self->{"stackup"}->GetCuLayerCnt();

}

sub GetStackup {
	my $self = shift;

	return $self->{"stackup"};
}

# Return stackup layers(exceot top/bottom coverlay)
sub GetStackupLayers {
	my $self = shift;

	my @l = $self->{"stackup"}->GetAllLayers();

	shift(@l) if ( $l[0]->GetType() eq StackEnums->MaterialType_COVERLAY );
	pop(@l)   if ( $l[-1]->GetType() eq StackEnums->MaterialType_COVERLAY );

	return @l;

}

sub GetExistCvrl {
	my $self   = shift;
	my $side   = shift;    # top/bot
	my $info   = shift;    # reference for storing info
	my $stckpL = shift;

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
	my $info   = shift // {};

	$info->{"adhesiveText"}  = "";
	$info->{"adhesiveThick"} = $stckpL->GetAdhesiveThick();
	$info->{"cvrlText"}      = $stckpL->GetTextType() . " " . $stckpL->GetText();
	$info->{"cvrlThick"} =
	  $stckpL->GetThick(0) - $stckpL->GetAdhesiveThick();    # Return real thickness from base class (not consider if covelraz is selective)
	$info->{"selective"} = $stckpL->GetMethod() eq StackEnums->Coverlay_SELECTIVE ? 1 : 0;

	return $info;
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

		# add gap if there is bracket
		$type =~ s/\[/ [/;

		if ( defined $childPCnt{$type} ) {
			$childPCnt{$type}++;
		}
		else {
			$childPCnt{$type} = 1;
		}
	}

	#	if ( scalar( keys %childPCnt ) == 1 ) {
	#		$t .= join( "+", map { $childPCnt{$_} . "x" . $_ } keys %childPCnt );
	#	}

	push( @{$types}, map { $childPCnt{$_} . "x" . $_ } keys %childPCnt );

	return $t;

}

sub GetTG {
	my $self = shift;

	my $matKind = HegMethods->GetMaterialKind( $self->{"jobId"}, 1 );

	my $minTG = undef;

	# 1) Get min TG of PCB
	if ( $matKind =~ /tg\s*(\d+)/i ) {

		# single kinf of stackup materials

		$minTG = $1;
	}
	elsif ( $matKind =~ /.*-.*/ ) {

		# hybrid material stackups

		my @mat = uniq( map { $_->GetTextType() } $self->{"stackup"}->GetAllCores() );

		for ( my $i = 0 ; $i < scalar(@mat) ; $i++ ) {

			$mat[$i] =~ s/\s//;
		}

		foreach my $m (@mat) {

			my $matKey = first { $m =~ /$_/i } keys %{ $self->{"isMatKinds"} };
			next unless ( defined $matKey );

			if ( !defined $minTG || $self->{"isMatKinds"}->{$matKey} < $minTG ) {
				$minTG = $self->{"isMatKinds"}->{$matKey};
			}
		}
	}

	# 2) Get min TG of estra layers (stiffeners/double coated tapes etc..)
	my $specTg = $self->_GetSpecLayerTg();

	if ( defined $minTG && defined $specTg ) {
		$minTG = min( ( $minTG, $specTg ) );
	}

	return $minTG;
}

sub GetIsInnerLayerEmpty {
	my $self  = shift;
	my $lName = shift;

	my @steps = ();
	
	my $inCAM  = $self->{"inCAM"};
	my $jobId  = $self->{"jobId"};

	if ( CamStepRepeat->ExistStepAndRepeats( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"} ) ) {

		@steps = CamStepRepeat->GetUniqueDeepestSR( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"} );
		CamStepRepeat->RemoveCouponSteps( \@steps );
		@steps = map { $_->{"stepName"} } @steps;
	}
	else {
		@steps = ("o+1");
	}

	my $isEmpty = 1;
	my $f       = Features->new();
	foreach my $step (@steps) {
		
		$f->Parse( $inCAM, $jobId, $step, $lName, 0, 0 );

		if( first {!defined $_->{"attr"}->{".string"}} grep { $_->{"polarity"} eq "P" } $f->GetFeatures()){
			$isEmpty = 0;
			last;
		}
	}
	
	return $isEmpty;
}

	#-------------------------------------------------------------------------------------------#
	#  Place for testing..
	#-------------------------------------------------------------------------------------------#
	my ( $package, $filename, $line ) = caller;
	if ( $filename =~ /DEBUG_FILE.pl/ ) {

	}

	1;

