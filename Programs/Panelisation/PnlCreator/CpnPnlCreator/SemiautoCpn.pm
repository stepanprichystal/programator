
#-------------------------------------------------------------------------------------------#
# Description: Class is responsible for coupon step placement to panel
# Import/Export settings method are meant for using class in bacground
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlCreator::CpnPnlCreator::SemiautoCpn;
use base('Programs::Panelisation::PnlCreator::PnlCreatorBase');

use Class::Interface;
&implements('Programs::Panelisation::PnlCreator::CpnPnlCreator::ICpn');

#3th party library
use strict;
use warnings;
use List::Util qw[max min first];
use Try::Tiny;

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::Panelisation::PnlCreator::Enums';
use aliased 'CamHelpers::CamStepRepeatPnl';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::CAMJob::Panelization::SRStep';
use aliased 'Helpers::JobHelper';
use aliased 'Programs::Panelisation::PnlCreator::Helpers::PnlToJSON';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class   = shift;
	my $jobId   = shift;
	my $pnlType = shift;
	my $key     = Enums->CpnPnlCreator_SEMIAUTO;

	my $self = $class->SUPER::new( $jobId, $pnlType, $key );
	bless $self;

	# Setting values necessary for procesing panelisation

	$self->{"settings"}->{"impCpnRequired"} = 0;
	$self->{"settings"}->{"impCpnSett"}     = {};

	$self->{"settings"}->{"IPC3CpnRequired"} = 0;
	$self->{"settings"}->{"IPC3CpnSett"}     = {};

	$self->{"settings"}->{"zAxisCpnRequired"} = 0;
	$self->{"settings"}->{"zAxisCpnSett"}     = {};

	$self->{"settings"}->{"placementType"}         = Enums->CpnPlacementMode_AUTO;
	$self->{"settings"}->{"manualPlacementJSON"}   = undef;
	$self->{"settings"}->{"manualPlacementStatus"} = EnumsGeneral->ResultType_NA;

	return $self;    #
}

#-------------------------------------------------------------------------------------------#
# Interface method
#-------------------------------------------------------------------------------------------#

# Init creator class in order process panelisation
# (instead of Init method is possible init by import JSON settings)
# Return 1 if succes 0 if fail
sub Init {
	my $self     = shift;
	my $inCAM    = shift;
	my $stepName = shift;

	my $result = 1;

	my $jobId = $self->{'jobId'};

	$self->SetStep($stepName);

	my @step = CamStep->GetAllStepNames( $inCAM, $jobId );

	# Impedance coupon default settings
	my $impCpnBaseName = EnumsGeneral->Coupon_IMPEDANCE;
	my @impSteps = grep { $_ =~ /$impCpnBaseName/i } @step;

	$self->SetImpCpnRequired( scalar(@impSteps) ? 1 : 0 );
	if ( $self->GetImpCpnRequired() ) {
		my %sett = ();
		$sett{"cpnPlacementType"} = Enums->ImpCpnType_1;
		$sett{"cpn2StepDist"}     = 4.5;                   # 4.5mm cpn step from panel steps

		$self->SetImpCpnSett( \%sett );
	}

	# IPC3 coupon default settings
	my $ipc3CpnBaseName = EnumsGeneral->Coupon_IPC3MAIN;
	my @ipc3Steps = grep { $_ =~ /$ipc3CpnBaseName/i } @step;

	$self->SetIPC3CpnRequired( scalar(@ipc3Steps) ? 1 : 0 );
	if ( $self->GetIPC3CpnRequired() ) {
		my %sett = ();
		$sett{"cpnPlacementType"} = Enums->IPC3CpnType_1;
		$sett{"cpn2StepDist"}     = 10;                     # 10mm cpn step from panel steps

		$self->SetIPC3CpnSett( \%sett );
	}

	# ZAxis coupon default settings
	my $zAxisCpnBaseName = EnumsGeneral->Coupon_ZAXIS;
	my @zAxisSteps = grep { $_ =~ /$zAxisCpnBaseName/i } @step;

	$self->SetZAxisCpnRequired( scalar(@zAxisSteps) ? 1 : 0 );
	if ( $self->GetZAxisCpnRequired() ) {
		my %sett = ();
		$sett{"cpnPlacementType"} = Enums->ZAxisCpnType_1;
		$sett{"cpn2StepDist"}     = 10;                      # 10mm cpn step from panel steps
		$self->SetZAxisCpnSett( \%sett );
	}

	# Default placement is automatic
	$self->SetPlacementType( Enums->CpnPlacementMode_AUTO );
	$self->SetManualPlacementJSON(undef);
	$self->SetManualPlacementStatus( EnumsGeneral->ResultType_NA );

	return $result;

}

# Do necessary check before processing panelisation
# This method is called always before Process method
# Return 1 if succes 0 if fail
sub Check {
	my $self    = shift;
	my $inCAM   = shift;
	my $errMess = shift;    # reference to err message

	my $result = 1;

	my $jobId = $self->{"jobId"};
	my $step  = $self->GetStep();

	if ( $self->GetImpCpnRequired() ) {

		my $sett = $self->GetImpCpnSett();

		if ( !defined $sett->{"cpnPlacementType"} || $sett->{"cpnPlacementType"} eq "" ) {
			$result = 0;
			$$errMess .= "Impedance coupon placement type is not defined";
		}

		if ( !defined $sett->{"cpn2StepDist"} || $sett->{"cpn2StepDist"} eq "" || $sett->{"cpn2StepDist"} < 0 ) {
			$result = 0;
			$$errMess .= "Impedance coupon to panel step distance is not valid";
		}
	}

	if ( $self->GetIPC3CpnRequired() ) {

		my $sett = $self->GetIPC3CpnSett();

		if ( !defined $sett->{"cpnPlacementType"} || $sett->{"cpnPlacementType"} eq "" ) {
			$result = 0;
			$$errMess .= "IPC3 coupon placement type is not defined";
		}

		if ( !defined $sett->{"cpn2StepDist"} || $sett->{"cpn2StepDist"} eq "" || $sett->{"cpn2StepDist"} < 0 ) {
			$result = 0;
			$$errMess .= "IPC3 coupon to panel step distance is not valid";
		}
	}

	if ( $self->GetZAxisCpnRequired() ) {

		my $sett = $self->GetZAxisCpnSett();

		if ( !defined $sett->{"cpnPlacementType"} || $sett->{"cpnPlacementType"} eq "" ) {
			$result = 0;
			$$errMess .= "ZAxis coupon placement type is not defined";
		}

		if ( !defined $sett->{"cpn2StepDist"} || $sett->{"cpn2StepDist"} eq "" || $sett->{"cpn2StepDist"} < 0 ) {
			$result = 0;
			$$errMess .= "ZAxis coupon to panel step distance is not valid";
		}
	}

	if ( $self->GetPlacementType() eq Enums->CpnPlacementMode_MANUAL ) {

		if ( $self->GetManualPlacementStatus() eq EnumsGeneral->ResultType_NA ) {

			# OK, coupon steps are placed automaticaly by setitngs (and wait for user adjustment)

		}
		elsif ( $self->GetManualPlacementStatus() eq EnumsGeneral->ResultType_FAIL ) {

			$result = 0;
			$$errMess .= "Manual coupon steps palcement is not set";

		}
		elsif ( $self->GetManualPlacementStatus() eq EnumsGeneral->ResultType_OK ) {

			unless ( defined $self->GetManualPlacementJSON() ) {

				# JSON placement is not defined
				$result = 0;
				$$errMess .= "Manual coupon steps palcement error. Missing JSON panel placement.";
			}

		}

	}

	return $result;

}

# Return 1 if succes 0 if fail
sub Process {
	my $self    = shift;
	my $inCAM   = shift;
	my $errMess = shift;    # reference to err message

	my $result = 1;

	my $jobId = $self->{"jobId"};
	my $step  = $self->GetStep();

	# Process by auto/manual choice
	CamHelper->SetStep( $inCAM, $self->GetStep() );

	if ( $self->GetPlacementType() eq Enums->CpnPlacementMode_AUTO ) {

		$self->__PlaceCoupons($inCAM);
	}
	elsif ( $self->GetPlacementType() eq Enums->CpnPlacementMode_MANUAL ) {

		# Check if manual placement already exist
		if ( $self->GetManualPlacementStatus() eq EnumsGeneral->ResultType_OK ) {

			my $pnlToJSON = PnlToJSON->new( $inCAM, $jobId, $step );
			$pnlToJSON->CreatePnlByJSON( $self->GetManualPlacementJSON(), 0, 0, 1 );

		}
		elsif ( $self->GetManualPlacementStatus() eq EnumsGeneral->ResultType_NA ) {

			$self->__PlaceCoupons($inCAM);

			#

		}
	}
	else {

		die "Unknow placement type: " . $self->GetPlacementType();
	}

	return $result;
}

sub __PlaceCoupons {
	my $self  = shift;
	my $inCAM = shift;

	my $jobId = $self->{'jobId'};
	my $step  = $self->GetStep();

	# Step limits

	my %limSR = CamStepRepeatPnl->GetStepAndRepeatLim( $inCAM, $jobId );
	my %limAA = CamStep->GetActiveAreaLim( $inCAM, $jobId, $step );

	my @allSteps = CamStep->GetAllStepNames( $inCAM, $jobId );
	my @cpnPos = ();

	# 1) Generate coupon positions based on placement type

	if ( $self->GetImpCpnRequired() ) {

		# Impedance coupon default settings
		my $cpnBaseName = EnumsGeneral->Coupon_IMPEDANCE;
		my @cpnSteps = grep { $_ =~ /$cpnBaseName/i } @allSteps;

		my %stepLim = CamJob->GetProfileLimits2( $inCAM, $jobId, $cpnSteps[0] );

		my $sett         = $self->GetImpCpnSett();
		my $type         = $sett->{"cpnPlacementType"};
		my $cpn2stepDist = $sett->{"cpn2StepDist"};

		if ( $type eq Enums->ImpCpnType_1 ) {

			# Placement
			#   -
			# |   |
			#   -
			# |   |
			#   -
			push( @cpnPos, $self->__GetSRByPanelSegment( "a", \%stepLim, 1, \%limAA, \%limSR, $cpn2stepDist, \@cpnSteps ) );
			push( @cpnPos, $self->__GetSRByPanelSegment( "b", \%stepLim, 2, \%limAA, \%limSR, $cpn2stepDist, \@cpnSteps ) );
			push( @cpnPos, $self->__GetSRByPanelSegment( "c", \%stepLim, 1, \%limAA, \%limSR, $cpn2stepDist, \@cpnSteps ) );
			push( @cpnPos, $self->__GetSRByPanelSegment( "d", \%stepLim, 2, \%limAA, \%limSR, $cpn2stepDist, \@cpnSteps ) );
			push( @cpnPos, $self->__GetSRByPanelSegment( "e", \%stepLim, 1, \%limAA, \%limSR, $cpn2stepDist, \@cpnSteps ) );

		}
		elsif ( $type eq Enums->ImpCpnType_2 ) {

			# Placement
			#
			# |   |
			#   -
			# |   |
			#

			push( @cpnPos, $self->__GetSRByPanelSegment( "b", \%stepLim, 2, \%limAA, \%limSR, $cpn2stepDist, \@cpnSteps ) );
			push( @cpnPos, $self->__GetSRByPanelSegment( "d", \%stepLim, 2, \%limAA, \%limSR, $cpn2stepDist, \@cpnSteps ) );
			push( @cpnPos, $self->__GetSRByPanelSegment( "e", \%stepLim, 1, \%limAA, \%limSR, $cpn2stepDist, \@cpnSteps ) );

		}
		elsif ( $type eq Enums->ImpCpnType_3 ) {

			# Placement
			#   -
			#
			#   -
			#
			#   -
			push( @cpnPos, $self->__GetSRByPanelSegment( "a", \%stepLim, 1, \%limAA, \%limSR, $cpn2stepDist, \@cpnSteps ) );
			push( @cpnPos, $self->__GetSRByPanelSegment( "c", \%stepLim, 1, \%limAA, \%limSR, $cpn2stepDist, \@cpnSteps ) );
			push( @cpnPos, $self->__GetSRByPanelSegment( "e", \%stepLim, 1, \%limAA, \%limSR, $cpn2stepDist, \@cpnSteps ) );

		}
		elsif ( $type eq Enums->ImpCpnType_4 ) {

			# Placement
			#   -
			# |   |
			#
			# |   |
			#   -
			push( @cpnPos, $self->__GetSRByPanelSegment( "a", \%stepLim, 1, \%limAA, \%limSR, $cpn2stepDist, \@cpnSteps ) );
			push( @cpnPos, $self->__GetSRByPanelSegment( "b", \%stepLim, 2, \%limAA, \%limSR, $cpn2stepDist, \@cpnSteps ) );
			push( @cpnPos, $self->__GetSRByPanelSegment( "c", \%stepLim, 1, \%limAA, \%limSR, $cpn2stepDist, \@cpnSteps ) );
			push( @cpnPos, $self->__GetSRByPanelSegment( "d", \%stepLim, 2, \%limAA, \%limSR, $cpn2stepDist, \@cpnSteps ) );

		}
		elsif ( $type eq Enums->ImpCpnType_5 ) {

			# Placement
			#
			# |   |
			#
			# |   |
			#
			push( @cpnPos, $self->__GetSRByPanelSegment( "b", \%stepLim, 2, \%limAA, \%limSR, $cpn2stepDist, \@cpnSteps ) );
			push( @cpnPos, $self->__GetSRByPanelSegment( "d", \%stepLim, 2, \%limAA, \%limSR, $cpn2stepDist, \@cpnSteps ) );

		}
		elsif ( $type eq Enums->ImpCpnType_6 ) {

			# Placement
			#   -
			#
			#
			#
			#   -
			push( @cpnPos, $self->__GetSRByPanelSegment( "a", \%stepLim, 1, \%limAA, \%limSR, $cpn2stepDist, \@cpnSteps ) );
			push( @cpnPos, $self->__GetSRByPanelSegment( "c", \%stepLim, 1, \%limAA, \%limSR, $cpn2stepDist, \@cpnSteps ) );
		}
		else {

			die "Type: $type is not implemented";
		}

	}

	if ( $self->GetIPC3CpnRequired() ) {

		my $cpnBaseName = EnumsGeneral->Coupon_IPC3MAIN;
		my @cpnSteps = grep { $_ =~ /$cpnBaseName/i } @allSteps;

		my %stepLim = CamJob->GetProfileLimits2( $inCAM, $jobId, $cpnSteps[0] );

		my $sett         = $self->GetIPC3CpnSett();
		my $type         = $sett->{"cpnPlacementType"};
		my $cpn2stepDist = $sett->{"cpn2StepDist"};

		if ( $type eq Enums->IPC3CpnType_1 ) {

			# Placement
			#
			# |   |
			#  - -
			# |   |
			#
			push( @cpnPos, $self->__GetSRByPanelSegment( "b", \%stepLim, 2, \%limAA, \%limSR, $cpn2stepDist, \@cpnSteps ) );
			push( @cpnPos, $self->__GetSRByPanelSegment( "d", \%stepLim, 2, \%limAA, \%limSR, $cpn2stepDist, \@cpnSteps ) );
			push( @cpnPos, $self->__GetSRByPanelSegment( "e", \%stepLim, 2, \%limAA, \%limSR, $cpn2stepDist, \@cpnSteps ) );

		}
		elsif ( $type eq Enums->IPC3CpnType_2 ) {

			# Placement
			#  - -
			#
			#  - -
			#
			#  - -
			push( @cpnPos, $self->__GetSRByPanelSegment( "a", \%stepLim, 2, \%limAA, \%limSR, $cpn2stepDist, \@cpnSteps ) );
			push( @cpnPos, $self->__GetSRByPanelSegment( "c", \%stepLim, 2, \%limAA, \%limSR, $cpn2stepDist, \@cpnSteps ) );
			push( @cpnPos, $self->__GetSRByPanelSegment( "e", \%stepLim, 2, \%limAA, \%limSR, $cpn2stepDist, \@cpnSteps ) );

		}
		elsif ( $type eq Enums->IPC3CpnType_3 ) {

			# Placement
			#
			#
			#  - - -
			#
			#
			push( @cpnPos, $self->__GetSRByPanelSegment( "e", \%stepLim, 3, \%limAA, \%limSR, $cpn2stepDist, \@cpnSteps ) );

		}
		elsif ( $type eq Enums->IPC3CpnType_4 ) {

			# Placement
			#  - -
			#
			#
			#
			#  - -
			push( @cpnPos, $self->__GetSRByPanelSegment( "a", \%stepLim, 2, \%limAA, \%limSR, $cpn2stepDist, \@cpnSteps ) );
			push( @cpnPos, $self->__GetSRByPanelSegment( "c", \%stepLim, 2, \%limAA, \%limSR, $cpn2stepDist, \@cpnSteps ) );

		}
		elsif ( $type eq Enums->IPC3CpnType_5 ) {

			# Placement
			#
			# |   |
			#
			# |   |
			#
			push( @cpnPos, $self->__GetSRByPanelSegment( "b", \%stepLim, 2, \%limAA, \%limSR, $cpn2stepDist, \@cpnSteps ) );
			push( @cpnPos, $self->__GetSRByPanelSegment( "d", \%stepLim, 2, \%limAA, \%limSR, $cpn2stepDist, \@cpnSteps ) );
		}
		else {

			die "Type: $type is not implemented";
		}
	}

	if ( $self->GetZAxisCpnRequired() ) {

		my $cpnBaseName = EnumsGeneral->Coupon_ZAXIS;
		my @cpnSteps = grep { $_ =~ /$cpnBaseName/i } @allSteps;

		my %stepLim = CamJob->GetProfileLimits2( $inCAM, $jobId, $cpnSteps[0] );

		my $sett         = $self->GetZAxisCpnSett();
		my $type         = $sett->{"cpnPlacementType"};
		my $cpn2stepDist = $sett->{"cpn2StepDist"};

		if ( $type eq Enums->ZAxisCpnType_1 ) {

			# Placement
			# |||||
			#
			# |||||
			#
			# |||||

			push( @cpnPos, $self->__GetSRByPanelSegment( "a", \%stepLim, scalar(@cpnSteps), \%limAA, \%limSR, $cpn2stepDist, \@cpnSteps ) );
			push( @cpnPos, $self->__GetSRByPanelSegment( "c", \%stepLim, scalar(@cpnSteps), \%limAA, \%limSR, $cpn2stepDist, \@cpnSteps ) );
			push( @cpnPos, $self->__GetSRByPanelSegment( "e", \%stepLim, scalar(@cpnSteps), \%limAA, \%limSR, $cpn2stepDist, \@cpnSteps ) );

		}
		elsif ( $type eq Enums->ZAxisCpnType_2 ) {

			# Placement
			#  |||||
			#
			#
			#
			#  |||||

			push( @cpnPos, $self->__GetSRByPanelSegment( "a", \%stepLim, scalar(@cpnSteps), \%limAA, \%limSR, $cpn2stepDist, \@cpnSteps ) );
			push( @cpnPos, $self->__GetSRByPanelSegment( "c", \%stepLim, scalar(@cpnSteps), \%limAA, \%limSR, $cpn2stepDist, \@cpnSteps ) );

		}
		elsif ( $type eq Enums->ZAxisCpnType_3 ) {

			# Placement
			#  |   |
			#  |   |
			#  |   |
			#  |   |
			#  |   |
			push( @cpnPos, $self->__GetSRByPanelSegment( "b", \%stepLim, scalar(@cpnSteps), \%limAA, \%limSR, $cpn2stepDist, \@cpnSteps ) );
			push( @cpnPos, $self->__GetSRByPanelSegment( "d", \%stepLim, scalar(@cpnSteps), \%limAA, \%limSR, $cpn2stepDist, \@cpnSteps ) );

		}
		elsif ( $type eq Enums->ZAxisCpnType_4 ) {

			# Placement
			#
			#
			# |||||
			#
			#

			push( @cpnPos, $self->__GetSRByPanelSegment( "e", \%stepLim, scalar(@cpnSteps), \%limAA, \%limSR, $cpn2stepDist, \@cpnSteps ) );

		}
		elsif ( $type eq Enums->ZAxisCpnType_5 ) {

			# Placement
			# |||||
			#
			#
			#
			#
			push( @cpnPos, $self->__GetSRByPanelSegment( "a", \%stepLim, scalar(@cpnSteps), \%limAA, \%limSR, $cpn2stepDist, \@cpnSteps ) );

		}
		elsif ( $type eq Enums->ZAxisCpnType_6 ) {

			# Placement
			#      |
			#      |
			#      |
			#      |
			#      |

			push( @cpnPos, $self->__GetSRByPanelSegment( "b", \%stepLim, scalar(@cpnSteps), \%limAA, \%limSR, $cpn2stepDist, \@cpnSteps ) );
		}
		else {

			die "Type: $type is not implemented";
		}

	}

	# 2) Place coupons to panel

	# Remove old coupns
	foreach my $s ( CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobId, $step ) ) {

		CamStepRepeat->DeleteStepAndRepeat( $inCAM, $jobId, $step, $s->{"stepName"} )
		  if ( JobHelper->GetStepIsCoupon( $s->{"stepName"} ) );
	}
	
	if (@cpnPos) {

		my $SRStep = SRStep->new( $inCAM, $jobId, $step );

		CamHelper->SetStep( $inCAM, $step );

		foreach my $pos (@cpnPos) {

			$SRStep->AddSRStep( $pos->{"cpnName"}, $pos->{"x"}, $pos->{"y"}, $pos->{"angle"}, 1, 1 );

		}

	}

}

# Return SR for requested coupon steps by given segment
# Steps will be placed along segment, parallel to segment
#
# Panel segments
#
#   Active area
#  ---------------
# |       a       |
# |  /\------>/\  |
# |  |    e    |  |
# |d | ------> | b|
# |  |    c    |  |
# |  | ------> |  |
# |               |
#  ---------------
# This is simple automatic coupon segment, need to be improved to future
sub __GetSRByPanelSegment {
	my $self         = shift;
	my $segment      = shift;    # a/b/c/d/e
	my $stepLim      = shift;
	my $stepCnt      = shift;
	my $areaLim      = shift;
	my $pnlStepLim   = shift;
	my $distCpn2Step = shift;
	my $cpnNames     = shift;    # Assign cpn namesto coupon position If there is less name names than stepCnt, names are used again form first

	die "Panel step distance from coupon is not defined" unless ( defined $distCpn2Step );

	# Step size
	my $cpnW = abs( $stepLim->{"xMax"} - $stepLim->{"xMin"} );
	my $cpnH = abs( $stepLim->{"yMax"} - $stepLim->{"yMin"} );

	# Area size
	my $areaX = abs( $areaLim->{"xMax"} - $areaLim->{"xMin"} );
	my $areaY = abs( $areaLim->{"yMax"} - $areaLim->{"yMin"} );

	my %segOrient = ();
	$segOrient{"a"} = "h";
	$segOrient{"b"} = "v";
	$segOrient{"c"} = "h";
	$segOrient{"d"} = "v";
	$segOrient{"e"} = "h";

	my %segLen = ();
	$segLen{"a"} = $areaX;
	$segLen{"b"} = $areaY;
	$segLen{"c"} = $areaX;
	$segLen{"d"} = $areaY;
	$segLen{"e"} = $areaX;

	# 1) Compute cpn distance
	my $distCpn2Cpn = ( $segLen{$segment} - ( $stepCnt * $cpnW ) ) / ( $stepCnt + 1 );

	# 2) Rotate step cnt to be parallel with segment

	my $cpnOri = "h";
	$cpnOri = "v" if ( $cpnH > $cpnW );
	my $angle = 0;
	if ( $segOrient{$segment} ne $cpnOri ) {
		$angle = 1;
		my $tmp = $cpnW;
		$cpnW = $cpnH;
		$cpnH = $tmp;

	}

	my @cpnStepPos = ();

	# Segment start point
	my %segStart = ();
	$segStart{"a"} = { "x" => $areaLim->{"xMin"}, "y" => $pnlStepLim->{"yMax"} + $distCpn2Step };
	$segStart{"b"} = { "x" => $pnlStepLim->{"xMax"} + $distCpn2Step, "y" => $areaLim->{"yMin"} };
	$segStart{"c"} = { "x" => $areaLim->{"xMin"}, "y" => $pnlStepLim->{"yMin"} - $distCpn2Step };
	$segStart{"d"} = { "x" => $pnlStepLim->{"xMin"} - $distCpn2Step, "y" => $areaLim->{"yMin"} };
	$segStart{"e"} = { "x" => $areaLim->{"xMin"}, "y" => $pnlStepLim->{"yMin"} + ( $pnlStepLim->{"yMax"} - $pnlStepLim->{"yMin"} ) / 2 };

	my @tmpNames = ();
	if ( $segment eq "a" || $segment eq "c" || $segment eq "e" ) {

		for ( my $i = 0 ; $i < $stepCnt ; $i++ ) {

			my %inf = ();
			$inf{"x"} = ( $i + 1 ) * $distCpn2Cpn + $segStart{$segment}->{"x"} + $i * $cpnW;
			$inf{"y"} = $segStart{$segment}->{"y"};

			$inf{"y"} += -$cpnH if ( $segment eq "c" );
			$inf{"y"} += -$cpnH / 2 if ( $segment eq "e" );

			$inf{"angle"} = $angle ? 90 : 0;

			@tmpNames = @{$cpnNames} if ( scalar(@tmpNames) == 0 );
			$inf{"cpnName"} = shift @tmpNames;

			push( @cpnStepPos, \%inf );
		}

	}
	elsif ( $segment eq "b" || $segment eq "d" ) {

		for ( my $i = 0 ; $i < $stepCnt ; $i++ ) {

			my %inf = ();
			$inf{"x"} = $segStart{$segment}->{"x"};
			$inf{"x"} += $cpnW if ( $segment eq "b" );
			$inf{"y"} = ( $i + 1 ) * $distCpn2Cpn + $segStart{$segment}->{"y"} + $i * $cpnH;
			$inf{"angle"} = $angle ? 90 : 0;
			@tmpNames = @{$cpnNames} if ( scalar(@tmpNames) == 0 );
			$inf{"cpnName"} = shift @tmpNames;

			push( @cpnStepPos, \%inf );
		}
	}

	return @cpnStepPos;

}

#-------------------------------------------------------------------------------------------#
# Get/Set method for adjusting settings after Init/ImportSetting
#-------------------------------------------------------------------------------------------#

# Imp coupon

sub SetImpCpnRequired {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"impCpnRequired"} = $val;
}

sub GetImpCpnRequired {
	my $self = shift;

	return $self->{"settings"}->{"impCpnRequired"};
}

sub SetImpCpnSett {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"impCpnSett"} = $val;
}

sub GetImpCpnSett {
	my $self = shift;

	return $self->{"settings"}->{"impCpnSett"};
}

# IPC3 coupon

sub SetIPC3CpnRequired {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"IPC3CpnRequired"} = $val;
}

sub GetIPC3CpnRequired {
	my $self = shift;

	return $self->{"settings"}->{"IPC3CpnRequired"};
}

sub SetIPC3CpnSett {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"IPC3CpnSett"} = $val;
}

sub GetIPC3CpnSett {
	my $self = shift;

	return $self->{"settings"}->{"IPC3CpnSett"};
}

# zAxis coupon

sub SetZAxisCpnRequired {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"zAxisCpnRequired"} = $val;
}

sub GetZAxisCpnRequired {
	my $self = shift;

	return $self->{"settings"}->{"zAxisCpnRequired"};
}

sub SetZAxisCpnSett {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"zAxisCpnSett"} = $val;
}

sub GetZAxisCpnSett {
	my $self = shift;

	return $self->{"settings"}->{"zAxisCpnSett"};
}

# Panelisation

sub SetPlacementType {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"placementType"} = $val;

}

sub GetPlacementType {
	my $self = shift;

	return $self->{"settings"}->{"placementType"};

}

sub SetManualPlacementJSON {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"manualPlacementJSON"} = $val;

}

sub GetManualPlacementJSON {
	my $self = shift;

	return $self->{"settings"}->{"manualPlacementJSON"};

}

sub SetManualPlacementStatus {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"manualPlacementStatus"} = $val;

}

sub GetManualPlacementStatus {
	my $self = shift;

	return $self->{"settings"}->{"manualPlacementStatus"};

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::Panelisation::PnlCreator::CpnPnlCreator::SemiautoCpn';
	use aliased 'Programs::Panelisation::PnlCreator::Enums';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "d304342";
	my $creator = SemiautoCpn->new( $jobId, Enums->PnlType_PRODUCTIONPNL );
	$creator->Init( $inCAM, "panel" );

	my $err = "";
	$creator->Process( $inCAM, \$err );

	die;
}

1;

