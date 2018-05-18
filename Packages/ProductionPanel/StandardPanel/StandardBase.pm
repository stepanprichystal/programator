#-------------------------------------------------------------------------------------------#
# Description:  Contain helper functions for recogniying standard panel and
# operation with standard panels
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::ProductionPanel::StandardPanel::StandardBase;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::ProductionPanel::StandardPanel::Enums';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStep';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::ProductionPanel::StandardPanel::Standard::StandardList';
use aliased 'Packages::ProductionPanel::StandardPanel::Standard::Standard';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}    = shift;
	$self->{"jobId"}    = shift;
	$self->{"step"}     = shift || "panel";
	$self->{"accuracy"} = shift || 0.2;       # accoracy during dimension comparing, default +-200µ

 
	# Determine panel limits
	my %profLim = CamJob->GetProfileLimits2( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"} );
	my %areaLim = CamStep->GetActiveAreaLim( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"} );

	$self->{"profLim"} = \%profLim;
	$self->{"w"}       = abs( $profLim{"xMax"} - $profLim{"xMin"} );
	$self->{"h"}       = abs( $profLim{"yMax"} - $profLim{"yMin"} );

	$self->{"areaLim"} = \%areaLim;
	$self->{"wArea"}   = abs( $areaLim{"xMax"} - $areaLim{"xMin"} );
	$self->{"hArea"}   = abs( $areaLim{"yMax"} - $areaLim{"yMin"} );

	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $self->{"jobId"} );

	# Determine pcb type
	$self->{"pcbType"} = undef;

	if ( $self->{"layerCnt"} > 2 ) {
		$self->{"pcbType"} = Enums->PcbType_MULTI;
	}
	else {
		$self->{"pcbType"} = Enums->PcbType_1V2V;
	}

	# Determine pcb material
	my $mat = HegMethods->GetMaterialKind( $self->{"jobId"} );
	$self->{"pcbMat"} = undef;

	if ( $mat =~ /FR4|IS4\d{2}|PCL370HR/i ) {

		$self->{"pcbMat"} = Enums->PcbMat_FR4;
	}
	elsif ( $mat =~ /AL|PCL/i ) {

		$self->{"pcbMat"} = Enums->PcbMat_ALU;
	}
	else {

		$self->{"pcbMat"} = Enums->PcbMat_SPEC;
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
sub IsStandard {
	my $self = shift;

	my $s = $self->GetStandard();

	my $result = Enums->Type_NONSTANDARD;

	if ( defined $s ) {
		$result = Enums->Type_STANDARDNOAREA;
	}

	if (    abs( $s->WArea() - $self->WArea() ) <= $self->{"accuracy"}
		 && abs( $s->HArea() - $self->HArea() ) <= $self->{"accuracy"} )
	{
		$result = Enums->Type_STANDARD;
	}

	return $result;
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

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::ProductionPanel::StandardPanel::StandardBase';
	use aliased 'Packages::InCAM::InCAM';
	use Data::Dump qw(dump);

	my $inCAM = InCAM->new();
	my $jobId = "d214271";

	my $pnl = StandardBase->new( $inCAM, $jobId );

	#my @arr = ();

	#print $pnl->IsStandardCandidate(\@arr);

	 
	my $isS = $pnl->IsStandard(   );

	print "$isS\n\n  ";
	
	my $s = $pnl->GetStandard(   );

	#print $s;

	dump($s);

}

1;

