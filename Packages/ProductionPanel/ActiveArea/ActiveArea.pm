#-------------------------------------------------------------------------------------------#
# Description:  Contain helper functions for recogniying standard panel and
# operation with standard panels
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::ProductionPanel::ActiveArea::ActiveArea;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::ProductionPanel::ActiveArea::Enums';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStep';
use aliased 'Connectors::HeliosConnector::HegMethods';

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

	$self->{"bl"} = abs( $profLim{"xMin"} - $areaLim{"xMin"} );
	$self->{"br"} = abs( $profLim{"xMax"} - $areaLim{"xMax"} );
	$self->{"bt"} = abs( $profLim{"yMax"} - $areaLim{"yMax"} );
	$self->{"bb"} = abs( $profLim{"yMin"} - $areaLim{"yMin"} );

	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $self->{"jobId"} );

	# Determine pcb type
	$self->{"pcbType"} = undef;

	if ( $self->{"layerCnt"} > 2 ) {
		$self->{"pcbType"} = Enums->PcbType_MULTI;
	}
	else {
		$self->{"pcbType"} = Enums->PcbType_1V2V;
	}

	return $self;
}

# Return if pcb has standard border
sub IsBorderStandard {
	my $self = shift;

	my %s = $self->GetStandardBorder();

	if (    abs( $self->{"bl"} - $s{"bl"} ) < $self->{"accuracy"}
		 && abs( $self->{"br"} - $s{"br"} ) < $self->{"accuracy"}
		 && abs( $self->{"bt"} - $s{"bt"} ) < $self->{"accuracy"}
		 && abs( $self->{"bb"} - $s{"bb"} ) < $self->{"accuracy"} )
	{
		return 1;

	}
	else {

		return 0;
	}

}

sub GetStandardBorder {
	my $self = shift;

	my %s = ();

	if ( $self->{"pcbType"} eq Enums->PcbType_MULTI ) {

		$s{"bl"} = 21;
		$s{"br"} = 21;
		$s{"bt"} = 41.6;
		$s{"bb"} = 41.6;

	}
	elsif ( $self->{"pcbType"} eq Enums->PcbType_1V2V ) {

		$s{"bl"} = 15;
		$s{"br"} = 15;
		$s{"bt"} = 15;
		$s{"bb"} = 15;

	}
	else {

		die "Standard active area dimension was not found for this pcb";
	}

	return %s;

}



#-------------------------------------------------------------------------------------------#
#  GET method for current area
#-------------------------------------------------------------------------------------------#

sub BorderL {
	my $self = shift;

	return $self->{"bl"};
}

sub BorderR {
	my $self = shift;

	return $self->{"br"};
}

sub BorderT {
	my $self = shift;

	return $self->{"bt"};
}

sub BorderB {
	my $self = shift;

	return $self->{"bb"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::ProductionPanel::ActiveArea::ActiveArea';
	use aliased 'Packages::InCAM::InCAM';
	use Data::Dump qw(dump);

	my $inCAM = InCAM->new();
	my $jobId = "f52457";

	my $pnl = ActiveArea->new( $inCAM, $jobId );

	#my @arr = ();

	#print $pnl->IsStandardCandidate(\@arr);

	my $isS = $pnl->IsBorderStandard();

	print "$isS\n\n  ";

}

1;

