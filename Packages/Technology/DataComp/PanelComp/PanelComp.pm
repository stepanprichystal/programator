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
use aliased 'Helpers::JobHelper';
use aliased 'Packages::Technology::DataComp::MatStability::MatStability';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamCopperArea';
use aliased 'CamHelpers::CamDrilling';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $self = shift;
	$self = {};
	bless $self;

	my $inCAM   = shift;
	my $jobId   = shift;
	my $step    = shift;
	my $stackup = shift;

	# PROPERTY

	$self->{"inCAM"}   = $inCAM;
	$self->{"jobId"}   = $jobId;
	$self->{"step"}    = $step;
	$self->{"stackup"} = $stackup; # only for multilayer pcb
	                               #$self->{"delayCuAreaCalc"} = $delayCuArea;    # if 1, cu area at 2v pcb is calculated during call "MatComp" method

	# Load helper property based on job type
	$self->{"pcbType"} = JobHelper->GetPcbType($jobId);
	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $inCAM, $jobId );
	my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $step );
	$self->{"pnlW"} = $lim{"xMax"} - $lim{"xMin"};
	$self->{"pnlH"} = $lim{"yMax"} - $lim{"yMin"};

	my @matKinds = ();

	if ( $self->{"layerCnt"} <= 2 ) {

		# Load Copper usaege at 1v+2v PCB
		#unless ( $self->{"delayCuAreaCalc"} ) {

		$self->{"2VcuUsage"}  = $self->__Get2vCuUsage();
		$self->{"2VmatThick"} = HegMethods->GetPcbMaterialThick($jobId) * 1000;
		$self->{"2VCuThick"}  = HegMethods->GetOuterCuThick($jobId);

		#}

		# Get material kind
		@matKinds = ( HegMethods->GetMaterialKind($jobId) );

	}
	else {

		# Load stackup if not defined
		$self->{"stackup"} = Stackup->new( $inCAM, $jobId ) unless ( defined $self->{"stackup"} );

		# Get material kind
		my @matKindsTxt = split( /\+/, $self->{"stackup"}->GetStackupType() );

		foreach my $mTxt (@matKindsTxt) {

			push( @matKinds, $self->__GetCoreMaterialKind($mTxt) );
		}

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

	$matKind = $self->__GetCoreMaterialKind($matKind);

	# Load property from stackup
	my $core     = $self->{"stackup"}->GetCore($coreNum);
	my $matThick = $core->GetThick();
	my $cuThick  = $core->GetTopCopperLayer()->GetThick();
	my $cuUsage  = ( $core->GetTopCopperLayer()->GetUssage() + $core->GetBotCopperLayer()->GetUssage() ) / 2 * 100;

	my @comp = $self->__GetPanelXYScale( $matKind, $matThick, $cuThick, $cuUsage );

	# Stretch/shrink Exceptions

	# 1) if one side top/bot has ussage 100% (outer cores in stackup), do not consider this side and devide stretch by 2
	# We assume, core with one side full covered with copper is shrinked less, because copper prevent shrink
	# TODO - add condition if core do not contain inner coverlay (pressing)
	if ( $core->GetTopCopperLayer()->GetUssage() == 1 || $core->GetBotCopperLayer()->GetUssage() == 1 ) {

		use constant EXTRA_OUTERCORE => 0.5;    # reduce stretch 50 % percent
		$comp[0] *= EXTRA_OUTERCORE;
		$comp[1] *= EXTRA_OUTERCORE;
	}

	return ( "x" => $comp[0], "y" => $comp[1] );

}

sub GetBaseMatComp {
	my $self = shift;

	my $matKind  = $self->{"matKinds"}->[0];
	my $matThick = $self->{"2VmatThick"};
	my $cuThick  = $self->{"2VCuThick"};
	my $cuUsage  = $self->{"2VcuUsage"};

	die "Only single and double sided layer PCB" if ( $self->{"layerCnt"} > 2 );

	my @comp = $self->__GetPanelXYScale( $matKind, $matThick, $cuThick, $cuUsage );

	# Stretch/shrink Exceptions

	# 1) If pcb is flexible and PCB contain TOP + BOT soldermask without any coverlay
	# add extra stretch, beasuce PCB are empirically more shrinked

	if ( JobHelper->GetIsFlex( $self->{"jobId"} ) ) {

		my @board = CamJob->GetBoardBaseLayers( $self->{"inCAM"}, $self->{"jobId"} );

		my $cvrl = scalar( grep { $_->{"gROWlayer_type"} eq "coverlay" } @board );
		my $sm   = scalar( grep { $_->{"gROWlayer_type"} eq "solder_mask" } @board );

		if ( !$cvrl && $sm >= 2 ) {

			use constant EXTRA_SM_STRETCH => 1.2;    # 1.35%
			$comp[0] *= EXTRA_SM_STRETCH;
			$comp[1] *= EXTRA_SM_STRETCH;
		}
	}

	# 2) If pcb is flexible 1-2V + coverlay and without plating
	# add extra shrink, beasuce PCB are empirically same at the begining of production as in the end
	# ( maybe even little stretched during production, but it is not proven)

	if ( JobHelper->GetIsFlex( $self->{"jobId"} ) && $self->{"layerCnt"} <= 2 ) {

		my @pltNC = grep { !$_->{"technical"} } CamDrilling->GetPltNCLayers( $self->{"inCAM"}, $self->{"jobId"} );

		my @board = CamJob->GetBoardBaseLayers( $self->{"inCAM"}, $self->{"jobId"} );

		my $cvrl = scalar( grep { $_->{"gROWlayer_type"} eq "coverlay" } @board );
		my $sm   = scalar( grep { $_->{"gROWlayer_type"} eq "solder_mask" } @board );

		if ( $cvrl > 0 && $sm == 0 && scalar(@pltNC) == 0 ) {

			use constant EXTRA_NPLT_CVRL_SHRINK => 0.40;    # Reduce original shrink by 60%
			$comp[0] *= EXTRA_NPLT_CVRL_SHRINK;
			$comp[1] *= EXTRA_NPLT_CVRL_SHRINK;
		}
	}

	return ( "x" => $comp[0], "y" => $comp[1] );
}

# Translate core material text to IS material kind (core material can by diffrent from nmaterial in IS)
sub __GetCoreMaterialKind {
	my $self = shift;
	my $mTxt = shift;

	my $mKind = undef;
	$mKind = "PYRALUX"  if ( $mTxt =~ /pyralux/i );
	$mKind = "THINFLEX" if ( $mTxt =~ /thinflex/i );
	$mKind = "IS400"    if ( $mTxt =~ /IS.*400/i );
	$mKind = "PCL370HR" if ( $mTxt =~ /PCL.*370.*HR/i );

	$mKind = $mTxt if ( !defined $mKind );    #

	return $mKind;
}

# Return how much has to by panel stretch to achieve requested panel dimension
# after production
# Values are percent unit
sub __GetPanelXYScale {
	my $self     = shift;
	my $matKind  = shift;
	my $matThick = shift;
	my $cuThick  = shift;
	my $cuUsage  = shift;

	my ( $xPer, $Yper ) = ( 0, 0 );

	# Decide which material and PCB type compensate
	if ( $self->__ScalingRequired( $matKind, $matThick, $cuThick, $cuUsage ) ) {

		my ( $xPPM, $YPPM ) = $self->{"matStability"}->GetMatStability( $matKind, $matThick, $cuThick, $cuUsage );

		$xPer = 0 + $xPPM / 10000;
		$Yper = 0 + $YPPM / 10000;

	}

	return ( $xPer, $Yper );
}

# Decide if scale
# depands on PCB type, material thicnkess etc..
sub __ScalingRequired {
	my $self     = shift;
	my $matKind  = shift;
	my $matThick = shift;
	my $cuThick  = shift;
	my $cuUsage  = shift;

	my $scale = 0;

	# Decide which material and PCB type compensate

	use constant MINMATTHICK => 150;    # material thickness treshold where stretch is apply

	if (    $self->{"pcbType"} eq EnumsGeneral->PcbType_1VFLEX
		 || $self->{"pcbType"} eq EnumsGeneral->PcbType_2VFLEX
		 || $self->{"pcbType"} eq EnumsGeneral->PcbType_MULTIFLEX
		 || $self->{"pcbType"} eq EnumsGeneral->PcbType_RIGIDFLEXO
		 || $self->{"pcbType"} eq EnumsGeneral->PcbType_RIGIDFLEXI )
	{

		# Always if flex

		$scale = 1;

	}
	elsif ( ( $self->{"pcbType"} eq EnumsGeneral->PcbType_1V || $self->{"pcbType"} eq EnumsGeneral->PcbType_2V )
			&& $matThick <= MINMATTHICK )
	{

		# If thin material and 1 + 2v
		$scale = 1;
	}
	elsif ( $self->{"pcbType"} eq EnumsGeneral->PcbType_MULTI ) {

		# If at least one core in stackup thin is <= MINMATTHICK
		my @core = $self->{"stackup"}->GetAllCores();

		my @thinCore = grep { $_->GetThick() <= MINMATTHICK } @core;

		if ( scalar(@thinCore) ) {
			$scale = 1;
		}
	}

	return $scale;
}

sub __Get2vCuUsage {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	my $u = 0;

	if ( $self->{"layerCnt"} > 0 ) {

		my $botL = "s" if ( CamHelper->LayerExists( $inCAM, $jobId, "s" ) );
		my %usage = CamCopperArea->GetCuArea( 0, 0, $inCAM, $jobId, $step, "c", $botL );
		$u = $usage{"percentage"};
	}

	return $u;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
