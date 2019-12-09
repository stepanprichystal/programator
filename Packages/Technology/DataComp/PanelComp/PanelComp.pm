#-------------------------------------------------------------------------------------------#
# Description: Return information about material stability
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Technology::DataComp::PanelComp::PanelComp;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Technology::DataComp::MatStability::MatStability';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Stackup::Stackup::Stackup';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $self = shift;
	$self = {};
	bless $self;

	my $inCAM   = shift;
	my $jobId   = shift;
	my $stackup = shift;

	# PROPERTY

	$self->{"inCAM"}   = $inCAM;
	$self->{"jobId"}   = $jobId;
	$self->{"stackup"} = $stackup; # only for multilayer pcb
	                               #$self->{"delayCuAreaCalc"} = $delayCuArea;    # if 1, cu area at 2v pcb is calculated during call "MatComp" method

	# Load helper property based on job type
	$self->{"pcbType"} = CamHelper->GetPcbType( $inCAM, $jobId );
	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $inCAM, $jobId );
	my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId );
	$self->{"pnlW"} = $lim{"xMax"} - $lim{"xMin"};
	$self->{"pnlH"} = $lim{"yMax"} - $lim{"yMin"};

	my @matKinds = ();

	if ( $self->{"layerCnt"} <= 2 ) {

		# Load Copper usaege at 1v+2v PCB
		#unless ( $self->{"delayCuAreaCalc"} ) {

		$self->{"2VcuUsage"}  = $self->__Get2vCuUsage();
		$self->{"2VmatThick"} = HegMethods->GetOuterCuThick($jobId) * 1000;
		$self->{"2VCuThick"}  = HegMethods->GetPcbMaterialThick($jobId) * 1000;

		#}

		# Get material kind
		@matKinds = ( HegMethods->GetMaterialKind($jobId) );

	}
	else {

		# Load stackup if not defined
		$self->{"stackup"} = Stackup->new( $inCAM, $jobId ) unless ( defined $self->{"stackup"} );

		# Get material kind
		@matKinds = split( "+", $self->{"stackup"}->GetStackupType() );

	}

	$self->{"matKinds"} = \@matKinds;

	# Load material stability tables
	$self->{"matStability"} = MatStability->new( \@matKinds );

	return $self;
}

sub GetCoreMatComp {
	my $self    = shift;
	my $coreNum = shift;
	my $matKind = shift;

	die "Only multilayer PCB" if ( $self->{"layerCnt"} <= 2 );

	# Load property from stackup
	my $core     = $self->{"stackup"}->GetCore($coreNum);
	my $matThick = $core->GetThick();
	my $cuThick  = $core->GetTopCopperLayer()->GetThick();
	my $cuUsage  = $core->GetTopCopperLayer()->GetUssage();

	my @comp = $self->__GetPanelXYScale( $matKind, $matThick, $cuThick, $cuUsage );

	return { "x" => $comp[0], "y" => $comp[1] };

}

sub GetBaseMatComp {
	my $self = shift;

	my $matKind  = $self->{"matKinds"}->[0];
	my $matThick = self->{"2VmatThick"};
	my $cuThick  = $self->{"2VCuThick"};
	my $cuUsage  = $self->{"2VcuUsage"};

	die "Only single and double sided layer PCB" if ( $self->{"layerCnt"} > 2 );

	my @comp = $self->__GetPanelXYScale( $matKind, $matThick, $cuThick, $cuUsage );

	return { "x" => $comp[0], "y" => $comp[1] };
}

# Return
sub __GetPanelXYScale {
	my $self     = shift;
	my $matKind  = shift;
	my $matThick = shift;
	my $cuThick  = shift;
	my $cuUsage  = shift;

	my ( $xPer, $Yper ) = ( 100, 100 );

	# Decide which material and PCB type compensate
	if (    $self->{"pcbType"} eq EnumsGeneral->PcbType_1VFLEX
		 || $self->{"pcbType"} eq EnumsGeneral->PcbType_2VFLEX
		 || $self->{"pcbType"} eq EnumsGeneral->PcbType_MULTIFLEX
		 || $self->{"pcbType"} eq EnumsGeneral->PcbType_RIGIDFLEXO
		 || $self->{"pcbType"} eq EnumsGeneral->PcbType_RIGIDFLEXI )
	{

		( $xPer, $Yper ) = $self->{"matStability"}->GetMatStability( $matKind, $matThick, $cuThick, $cuUsage );

	}
	    
	return ( $xPer, $Yper );
}

sub __Get2vCuUsage {
	my $self = shift;

	my $botL = "s" if ( CamHelper->LayerExists( $inCAM, $jobId, "s" ) );
	my %usage = CamCopperArea->GetCuArea( 0, 0, $inCAM, $jobId, "panel", "c", $botL );

	my $cuUsage = = $usage{"percentage"};

	return $cuUsage;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Technology::DataComp::MatStability';

	my $t = MatStability->new("PYRALUX");
	die $t;

}

1;
