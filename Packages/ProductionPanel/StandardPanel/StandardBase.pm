#-------------------------------------------------------------------------------------------#
# Description:  Contain helper functions for recogniying standard panel and
# operation with standard panels
# Work with existing panel or with passed dimension only
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::ProductionPanel::StandardPanel::StandardBase;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::ProductionPanel::StandardPanel::Enums';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamHelper';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::ProductionPanel::StandardPanel::Standard::StandardList';
use aliased 'Packages::ProductionPanel::StandardPanel::Standard::Standard';
use aliased 'Packages::Polygon::PolygonFeatures';
use aliased 'Packages::Polygon::Features::Features::Features';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $step      = shift // "panel";
	my $accuracy  = shift // 0.2;                          # accoracy during dimension comparing, default +-200µ
	my $stepExist = shift // 1;                            # If step doesnt exist, profile limits + active area limits has to be past
	my %profLim   = %{ shift(@_) } unless ($stepExist);    # Step profile limits if step doesnt exist yet
	my %areaLim   = %{ shift(@_) } unless ($stepExist);    # Step active area limits if step doesnt exist yet

	$self = {};
	bless $self;

	# PROPERTIES

	$self->{"accuracy"} = $accuracy;                       # accoracy during dimension comparing, default +-200µ

	# COMPUTED PROPERTIES

	if ($stepExist) {

		# Determine panel limits from existing panel
		die "Step: $step doesn't exist" if ( !CamHelper->StepExists( $inCAM, $jobId, $step ) );
		%profLim = CamJob->GetProfileLimits2( $inCAM, $jobId, $step );
		%areaLim = CamStep->GetActiveAreaLim( $inCAM, $jobId, $step );
	}
	else {

		# Determine panel limits from existing panel
		die "Profile limits are not defined"     if ( scalar( keys %profLim ) == 0 );
		die "Active area limits are not defined" if ( scalar( keys %areaLim ) == 0 );

	}

	$self->{"profLim"} = \%profLim;
	$self->{"w"}       = abs( $profLim{"xMax"} - $profLim{"xMin"} );
	$self->{"h"}       = abs( $profLim{"yMax"} - $profLim{"yMin"} );

	$self->{"areaLim"}  = \%areaLim;
	$self->{"wArea"}    = abs( $areaLim{"xMax"} - $areaLim{"xMin"} );
	$self->{"hArea"}    = abs( $areaLim{"yMax"} - $areaLim{"yMin"} );
	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $inCAM, $jobId );

	$self->{"wFr"} = undef;
	$self->{"hFr"} = undef;

	if ($stepExist) {
		if ( $self->{"layerCnt"} > 2 ) {

			if ( CamHelper->LayerExists( $inCAM, $jobId, "fr" ) ) {
				my $route = Features->new();
				$route->Parse( $inCAM, $jobId, $step, "fr" );
				my %frLim = PolygonFeatures->GetLimByRectangle( [ $route->GetFeatures() ] );

				$self->{"wFr"} = abs( $frLim{"xMax"} - $frLim{"xMin"} );
				$self->{"hFr"} = abs( $frLim{"yMax"} - $frLim{"yMin"} );
			}
		}
	}

	# Determine pcb type
	$self->{"pcbType"} = undef;

	if ( $self->{"layerCnt"} > 2 ) {
		$self->{"pcbType"} = Enums->PcbType_MULTI;
	}
	else {
		$self->{"pcbType"} = Enums->PcbType_1V2V;
	}

	# Determine pcb material
	my $mat    = HegMethods->GetMaterialKind($jobId);
	my $isFlex = JobHelper->GetIsFlex($jobId);
	$self->{"pcbMat"} = undef;

	if ( $mat =~ /^AL|^CU/i ) {

		$self->{"pcbMat"} = Enums->PcbMat_ALU;
	}
	elsif ($isFlex) {

		$self->{"pcbMat"} = Enums->PcbMat_FLEX;
	}
	elsif ( $mat =~ /^HYBRID|^RO/i ) {

		$self->{"pcbMat"} = Enums->PcbMat_SPEC;
	}
	else {

		$self->{"pcbMat"} = Enums->PcbMat_STDLAM;
	}

	# List of all standards
	my @list   = StandardList->GetStandards();
	my @active = StandardList->GetStandards(1);

	$self->{"list"}   = \@list;
	$self->{"active"} = \@active;

	return $self;

}

# Return if there are active standards with same "pcbType" and "pcbMat" as this pcb
# It means, pcb can be standard
# Return if is standard candidate
sub IsStandardCandidate {
	my $self = shift;
	my $arr  = shift;    # ref to list of standard candidates

	my @s = grep { $_->PcbType() eq $self->PcbType() && $_->PcbMat() eq $self->PcbMat() } @{ $self->{"active"} };

	if ( defined $arr ) {
		@{$arr} = @s;
	}

	return scalar(@s) ? 1 : 0;
}

# Return if pcb is "standard candidate" and if there is active standard with:
# same dimension as this pcb or smaller or bigger dimension
# Return:
# Type_NONSTANDARD
# Type_STANDARD
# Type_STANDARDNOAREA - standard but area is different
sub GetStandardType {
	my $self = shift;

	my $s = $self->GetStandard();

	my $result = Enums->Type_NONSTANDARD;

	if ( defined $s ) {
		$result = Enums->Type_STANDARDNOAREA;

		if (    abs( $s->WArea() - $self->WArea() ) <= $self->{"accuracy"}
			 && abs( $s->HArea() - $self->HArea() ) <= $self->{"accuracy"} )
		{
			$result = Enums->Type_STANDARD;
		}
	}

	return $result;
}

# Return 1 if pcb is type Enums->Type_STANDARD, ale 0
sub IsStandard {
	my $self = shift;

	if ( $self->GetStandardType() eq Enums->Type_STANDARD ) {

		return 1;
	}
	else {

		return 0;
	}
}

# Return standard if exist, otherwise undef
sub GetStandard {
	my $self = shift;

	my $standard   = undef;
	my @candidates = ();

	unless ( $self->IsStandardCandidate( \@candidates ) ) {
		die "Unable to find standard panels by dimensions, when current pcb is not \"standard candidate\".";
	}

	foreach my $s (@candidates) {

		if (    abs( $s->W() - $self->W() ) <= $self->{"accuracy"}
			 && abs( $s->H() - $self->H() ) <= $self->{"accuracy"} )
		{

			$standard = $s;

			last;
		}
	}

	return $standard;
}

#-------------------------------------------------------------------------------------------#
#  GET method for current panel
#-------------------------------------------------------------------------------------------#

sub PcbType {
	my $self = shift;

	return $self->{"pcbType"};
}

sub PcbMat {
	my $self = shift;

	return $self->{"pcbMat"};
}

sub W {
	my $self = shift;

	return $self->{"w"};
}

sub H {
	my $self = shift;

	return $self->{"h"};
}

sub WArea {
	my $self = shift;

	return $self->{"wArea"};
}

sub HArea {
	my $self = shift;

	return $self->{"hArea"};
}

sub WFr {
	my $self = shift;

	die "Fr limits are not defined" if ( !defiend $self->{"wFr"} );

	return $self->{"wFr"};
}

sub HFr {
	my $self = shift;

	die "Fr limits are not defined" if ( !defiend $self->{"hFr"} );
	return $self->{"hFr"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::ProductionPanel::StandardPanel::StandardBase';
	use aliased 'Packages::InCAM::InCAM';
	use Data::Dump qw(dump);

	my $inCAM = InCAM->new();
	my $jobId = "d200996";

	my $pnl = StandardBase->new( $inCAM, $jobId );

	#my @arr = ();

	#print $pnl->IsStandardCandidate(\@arr);

	my $isS = $pnl->IsStandard();

	print "$isS\n\n  ";

	die "test";

}

1;

