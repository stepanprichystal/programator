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
use aliased 'Packages::ProductionPanel::StandardPanel::StandardDef';

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
	$self->{"accuracy"} = shift || 0.1;       # accoracy during dimension comparing, default +-100µ

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

	if ( $mat =~ /FR4/i ) {

		$self->{"pcbMat"} = Enums->PcbMat_FR4;
	}
	elsif ( $mat =~ /ALU/i ) {

		$self->{"pcbMat"} = Enums->PcbMat_ALU;
	}
	else {

		$self->{"pcbMat"} = Enums->PcbMat_SPEC;
	}

	# List of all standards
	my @list   = StandardDef->GetStandards();
	my @active = StandardDef->GetStandards(1);

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

	my @s = grep { $_->{"pcbType"} eq $self->{"pcbType"} && $_->{"pcbMat"} eq $self->{"pcbMat"} } @{ $self->{"active"} };

	if ( defined $arr ) {
		@($arr ) = @s;
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
	  my $self     = shift;
	  my $standard = shift;    # ref on standar type

	  my @candidates = ();

	  unless ( $self->IsStandardCandidate( \@candidates ) ) {
		  die "Unable to find standard panels by dimensions, when current pcb is not \"standard candidate\".";
	  }

	  my $result = Enums->Type_NONSTANDARD;

	  foreach $s (@candidates) {

		  if (    abs( $s->{"w"} - $self->{"w"} ) <= $self->{"accuracy"}
			   && abs( $s->{"h"} - $self->{"h"} ) <= $self->{"accuracy"} )
		  {

			  $standard = $s;
			  $result   = Enums->Type_STANDARDNOAREA;

			  # test if area dim (no position) is standard too
			  if (
				   abs( $s->{"wArea"} - $self->{"wArea"} ) <= $self->{"accuracy"}
				   && abs( $s->{"hArea"} - $self->{"hArea"} ) <= $self->{"accuracy"}
				)
			  {
				  $result = Enums->Type_STANDARD;
			  }

			  last;
		  }
	  }

	  return $result;
}

# Return standard if exist, otherwise undef
sub GetStandard {
	  my $self = shift;

	  my $standard = undef;
	  $self->IsStandardDim($standard);

	  return $standard;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	  use aliased 'Packages::ProductionPanel::StandardPanel';
	  use aliased 'Packages::InCAM::InCAM';

	  my $inCAM = InCAM->new();
	  my $jobId = "f52456";

	  print "fff";

}

1;

