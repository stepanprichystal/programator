#-------------------------------------------------------------------------------------------#
# Description:  Return universal code of pcb in format \dRi-\dF-\dRi
# Determine if inner stackup layes are empty
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::StackupCode;

#loading of locale modules

#3th party library
use English;
use strict;
use warnings;
use XML::Simple;
use POSIX;
use File::Copy;

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::Stackup::Enums' => "StackEnums";
use aliased 'Helpers::JobHelper';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::Polygon::Features::Features::Features';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"}   = shift;
	$self->{"jobId"}   = shift;
	$self->{"step"}    = shift // "panel";
	$self->{"stackup"} = shift;

	# Properties

	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $self->{"jobId"} );
	$self->{"pcbType"}  = JobHelper->GetPcbType( $self->{"jobId"} );
	$self->{"isFlex"}   = JobHelper->GetIsFlex( $self->{"jobId"} );

	if ( $self->{"layerCnt"} > 2 && !defined $self->{"stackup"} ) {

		$self->{"stackup"} = Stackup->new( $self->{"inCAM"}, $self->{"jobId"} );

	}

	$self->{"layerEmpty"} = { $self->__SetIsLayerEmpty() };

	return $self;
}

# Return if inner layer contain no customer data
sub GetIsLayerEmpty {
	my $self  = shift;
	my $lName = shift;

	return $self->{"layerEmpty"}->{$lName};

}

sub GetStackupCode {
	my $self     = shift;
	my $extended = shift;    # after code is placed number of stiffener, coverlay, UV flex mask, tape

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $code = undef;

	if ( $self->{"layerCnt"} <= 2 ) {

		$code = $self->__Get2VCode();
	}
	else {

		$code = $self->__GetVVCode();

	}

	if ($extended) {

		my @boardL = CamJob->GetBoardBaseLayers( $inCAM, $jobId );

		my $cvrlCnt   = scalar( grep { $_->{"gROWlayer_type"} eq "cvrl" } @boardL );
		my $stiffCnt  = scalar( grep { $_->{"gROWlayer_type"} eq "stiffener" } @boardL );
		my $tapeCnt   = scalar( grep { $_->{"gROWlayer_type"} eq "psa" } @boardL );
		my $uvFlexCnt = scalar( grep { $_->{"gROWlayer_type"} eq "solder_mask" && $_->{"gROWname"} =~ /^m[cs]flex$/ } @boardL );

		$code .= " + $cvrlCnt" . "x coverlay"       if ($cvrlCnt);
		$code .= " + $stiffCnt" . "x stiffener"     if ($stiffCnt);
		$code .= " + $tapeCnt" . "x adhesive tape"  if ($tapeCnt);
		$code .= " + $uvFlexCnt" . "x UV flex mask" if ($uvFlexCnt);

	}

	return $code;
}

# Return hash with stackup code.
# Hash contains three keys:
#	xRi
#	yF
#	zRi

sub GetStackupCodeParsed {
	my $self = shift;

	my %c = ( "xRi" => undef, "yF" => undef, "zRi" => undef );

	my $code = $self->GetStackupCode();

	if ( $code =~ /^(\d+)Ri$/i ) {
		$c{"xRi"} = $1;
	}
	elsif ( $code =~ /^(\d+)F$/i ) {
		$c{"yF"} = $1;
	}
	elsif ( $code =~ /^(\d+)Ri-(\d+)F$/i ) {
		$c{"xRi"} = $1;
		$c{"yF"}  = $2;
	}
	elsif ( $code =~ /^(\d+)Ri-(\d+)F-(\d+)Ri$/i ) {
		$c{"xRi"} = $1;
		$c{"yF"}  = $2;
		$c{"zRi"} = $3;
	}
	else {

		die "Unexpected code value $code";
	}

	return %c;
}

# Return number of used (not empty) rigid layer
sub GetUsedRigidLayerCnt {
	my $self  = shift;
	my $outer = shift // 1;
	my $inner = shift // 1;

	my $code = $self->GetStackupCode();

	my ( $xRi, $yRi, $zRi ) = 0;

	my $cnt = 0;

	if ( $code =~ /^(\d+)Ri-\d+F$/i ) {

		$cnt += 1 if ($outer);
		$cnt += $1 - 1 if ($inner);
	}
	elsif ( $code =~ /^(\d+)Ri-\d+F-(\d+)Ri$/i ) {

		# Top Ri
		$cnt += 1 if ($outer);
		$cnt += $1 - 1 if ($inner);

		# Bot Ri
		$cnt += 1 if ($outer);
		$cnt += $2 - 1 if ($inner);
	}

	return $cnt;
}

# Return number of used (not empty) flex layer
sub GetUsedFlexLayerCnt {
	my $self  = shift;
	my $outer = shift // 1;
	my $inner = shift // 1;

	my $code = $self->GetStackupCode();

	my ( $xRi, $yRi, $zRi ) = 0;

	my $cnt = 0;

	if ( $code =~ /^\d+Ri-(\d+)F$/i ) {

		$cnt += 1 if ($outer);
		$cnt += $1 - 1 if ($inner);
	}
	elsif ( $code =~ /^\d+Ri-(\d+)F-\d+Ri$/i ) {

		$cnt += $1 if ($inner);
	}

	return $cnt;
}

sub __Get2VCode {
	my $self = shift;

	my $pcbType = $self->{"pcbType"};

	my $code = undef;
	if ( $pcbType eq EnumsGeneral->PcbType_STENCIL ) {

		$code = "stencil";
	}
	else {

		if ( $self->{"layerCnt"} <= 1 ) {

			# No copper
			# 1v

			$code = $self->{"layerCnt"} . ( $self->{"isFlex"} ? "F" : "Ri" );

		}
		elsif ( $self->{"layerCnt"} == 2 ) {

			# Check if both layer are not empty
			my $lCnt = 1;
			if ( !$self->{"layerEmpty"}->{"c"} && !$self->{"layerEmpty"}->{"s"} ) {
				$lCnt = 2;
			}
			$code = $lCnt . ( $self->{"isFlex"} ? "F" : "Ri" );
		}

	}

	return $code;
}

sub __GetVVCode {
	my $self = shift;

	my $pcbType = $self->{"pcbType"};
	my $code    = undef;

	if ( $self->{"isFlex"} ) {

		# Inner RigidFlex
		# Outer RigidFlex

		my @layers    = $self->__GetStackupLayers();
		my @codeParts = ();
		my $curPart   = undef;
		my $cuPartCnt = 0;
		for ( my $i = 0 ; $i < scalar(@layers) ; $i++ ) {

			my $l = $layers[$i];

			if ( $l->GetType() eq StackEnums->MaterialType_COPPER && !$self->GetIsLayerEmpty( $l->GetCopperName ) ) {

				my $c = !$l->GetIsFoil() ? $self->{"stackup"}->GetCoreByCuLayer( $l->GetCopperName ) : undef;
				my $isFlex = ( defined $c && $c->GetCoreRigidType() eq StackEnums->CoreType_FLEX ) ? 1 : 0;
				my $newPart = $isFlex ? "F" : "Ri";

				if ( !defined $curPart ) {
					$curPart = $newPart;
				}
				elsif ( defined $curPart && $curPart ne $newPart ) {

					push( @codeParts, $cuPartCnt . $curPart );

					$curPart   = $newPart;
					$cuPartCnt = 0;
				}

				$cuPartCnt++;
			}
		}

		push( @codeParts, $cuPartCnt . $curPart );

		$code = join( "-", @codeParts );
	}

	else {

		# VV pcb

		$code = $self->{"layerCnt"} . "Ri";

	}
	return $code;
}

sub __SetIsLayerEmpty {
	my $self = shift;

	my @steps = ();

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	if ( CamStepRepeat->ExistStepAndRepeats( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"} ) ) {

		@steps = CamStepRepeat->GetUniqueDeepestSR( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"} );
		CamStepRepeat->RemoveCouponSteps( \@steps );
		@steps = map { $_->{"stepName"} } @steps;
	}
	else {
		@steps = ("o+1");
	}

	my %emptLayers = ();

	my @layers = ();

	if ( $self->{"layerCnt"} <= 2 ) {

		my @allL = ( "c", "s" );

		foreach my $l (@allL) {

			if ( CamHelper->LayerExists( $inCAM, $jobId, $l ) ) {

				my $isEmpty = $self->__IsLayerEmpty( $l, \@steps );
				$emptLayers{$l} = $isEmpty;
			}

		}
	}
	else {

		my @layers = $self->__GetStackupLayers();

		for ( my $i = 0 ; $i < scalar(@layers) ; $i++ ) {

			my $l = $layers[$i];

			if ( $l->GetType() eq StackEnums->MaterialType_COPPER ) {

				my $isEmpty = $self->__IsLayerEmpty( $l->GetCopperName(), \@steps );

				$emptLayers{ $l->GetCopperName() } = $isEmpty;
			}
		}
	}

	return %emptLayers;
}

sub __IsLayerEmpty {
	my $self  = shift;
	my $lName = shift;
	my @steps = @{ shift(@_) };

	my $isEmpty = 1;
	my $f       = Features->new();
	foreach my $step (@steps) {

		$f->Parse( $self->{"inCAM"}, $self->{"jobId"}, $step, $lName, 0, 0 );

		my @allFeats = $f->GetFeatures();
		my @stringFeats = grep { defined $_->{"att"}->{".string"} } @allFeats;

		# Features with attribute .string should be helper features, not customer data
		if (  scalar(@allFeats) && scalar(@allFeats) > scalar(@stringFeats) )   {
			$isEmpty = 0;
			last;
		}
	}

	return $isEmpty;

}

sub __GetStackupLayers {
	my $self = shift;

	my @l = $self->{"stackup"}->GetAllLayers();

	shift(@l) if ( $l[0]->GetType() eq StackEnums->MaterialType_COVERLAY );
	pop(@l)   if ( $l[-1]->GetType() eq StackEnums->MaterialType_COVERLAY );

	return @l;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;

if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAMJob::Stackup::StackupCode';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d325160";

	my $stckpCode = StackupCode->new( $inCAM, $jobId );

	die;

}

1;

