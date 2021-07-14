
#-------------------------------------------------------------------------------------------#
# Description: Class is responsible for step placement to panel
# Import/Export settings method are meant for using class in bacground
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlCreator::StepsPnlCreator::ClassCreatorBase;
use base('Programs::Panelisation::PnlCreator::PnlCreatorBase');
 
#3th party library
use strict;
use warnings;
use List::Util qw[max min first];
use Try::Tiny;

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::Panelisation::PnlCreator::Enums';
use aliased 'Packages::CAM::PanelClass::Enums' => "PnlClassEnums";
use aliased 'Programs::Panelisation::PnlCreator::Helpers::PnlClassParser';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Packages::CAMJob::Panelization::AutoPart';
use aliased 'Programs::Panelisation::PnlCreator::Helpers::PnlToJSON';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class   = shift;
	my $jobId   = shift;
	my $pnlType = shift;
	my $key     = shift;

	my $self = $class->SUPER::new( $jobId, $pnlType, $key );
	bless $self;

	$self->{"settings"}->{"pnlClasses"}            = [];
	$self->{"settings"}->{"defPnlClass"}           = undef;
	$self->{"settings"}->{"defPnlSpacing"}         = undef;
	$self->{"settings"}->{"pcbStepsList"}          = [];
	$self->{"settings"}->{"pcbStep"}               = undef;
	$self->{"settings"}->{"placementType"}         = PnlClassEnums->PnlClassTransform_ROTATION;
	$self->{"settings"}->{"rotationType"}          = undef;
	$self->{"settings"}->{"patternType"}           = undef;
	$self->{"settings"}->{"interlockType"}         = undef;
	$self->{"settings"}->{"spaceX"}                = 0;
	$self->{"settings"}->{"spaceY"}                = 0;
	$self->{"settings"}->{"alignType"}             = undef;
	$self->{"settings"}->{"amountType"}            = Enums->StepAmount_EXACT;
	$self->{"settings"}->{"exactQuantity"}         = 0;
	$self->{"settings"}->{"maxQuantity"}           = 0;
	$self->{"settings"}->{"autoQuantity"}          = undef;
	$self->{"settings"}->{"actionType"}            = Enums->StepPlacementMode_AUTO;
	$self->{"settings"}->{"manualPlacementJSON"}   = undef;
	$self->{"settings"}->{"manualPlacementStatus"} = EnumsGeneral->ResultType_NA;
	$self->{"settings"}->{"minUtilization"}        = 1;

	#	$self->{"settings"}->{"width"}       = undef;
	#	$self->{"settings"}->{"height"}      = undef;
	#	$self->{"settings"}->{"borderLeft"}  = undef;
	#	$self->{"settings"}->{"borderRight"} = undef;
	#	$self->{"settings"}->{"borderTop"}   = undef;
	#	$self->{"settings"}->{"borderBot"}   = undef;

	return $self;    #
}

#-------------------------------------------------------------------------------------------#
# Interface method
#-------------------------------------------------------------------------------------------#

# Init creator class in order process panelisation
# (instead of Init method is possible init by import JSON settings)
# Return 1 if succes 0 if fail
sub _Init {
	my $self     = shift;
	my $inCAM    = shift;
	my $stepName = shift;

	my $result = 1;

	my $jobId = $self->{'jobId'};

	$self->{"settings"}->{"step"} = $stepName;

	my @childs = grep { $_ =~ /^\w+\+1$/ } CamStep->GetAllStepNames( $inCAM, $jobId );
	@childs = grep { $_ ne $stepName } @childs;
	$self->SetPCBStepsList( \@childs );

	if ( $self->GetPnlType() eq Enums->PnlType_CUSTOMERPNL ) {

		# Create step list choice

		$self->SetPCBStep( $childs[0] );
	}
	elsif ( $self->GetPnlType() eq Enums->PnlType_PRODUCTIONPNL ) {

		my $mpanel = first { $_ eq "mpanel" } @childs;

		if ( defined $mpanel ) {
			$self->SetPCBStep("mpanel");
		}
		else {
			$self->SetPCBStep( $childs[0] );
		}

	}

	# Load Pnl class

	my $parser = PnlClassParser->new( $inCAM, $jobId );
	$parser->Parse();

	my @classes = ();
	if ( $self->GetPnlType() eq Enums->PnlType_CUSTOMERPNL ) {

		@classes = $parser->GetCustomerPnlClasses();
	}
	elsif ( $self->GetPnlType() eq Enums->PnlType_PRODUCTIONPNL ) {

		@classes = $parser->GetProductionPnlClasses(1);

	}

	my $defClass   = undef;
	my $defSpacing = undef;

	$self->{"settings"}->{"pnlClasses"} = \@classes;

	# 1)Set default class (should be only one for specific pcb type)
	$defClass = $classes[0];
	if ( defined $defClass ) {

		$self->{"settings"}->{"defPnlClass"} = $defClass->GetName();

		# Set placement settings

		$self->SetPlacementType( $defClass->GetTransformation() );
		$self->SetRotationType( $defClass->GetRotation() );
		$self->SetPatternType( $defClass->GetPattern() );
		$self->SetInterlockType( $defClass->GetInterlock() );

		# Set space settings
		$self->SetAlignType( $defClass->GetSpacingAlign() );
		my @spacings = $classes[0]->GetAllClassSpacings();
		$defSpacing = $spacings[0];

		if ( defined $defSpacing ) {

			$self->{"settings"}->{"defPnlSpacing"} = $defSpacing->GetName();

			$self->SetSpaceX( $defSpacing->GetSpaceX() );
			$self->SetSpaceY( $defSpacing->GetSpaceY() );

		}

	}

	# Set min utilization 5%

	$self->SetMinUtilization(5);

	# Set amount settings
	$self->SetAmountType( Enums->StepAmount_AUTO );

	# Set action type

	$self->SetActionType( Enums->StepPlacementMode_AUTO );

	return $result;

}

# Do necessary check before processing panelisation
# This method is called always before Process method
# Return 1 if succes 0 if fail
sub _Check {
	my $self    = shift;
	my $inCAM   = shift;
	my $errMess = shift;    # reference to err message

	my $jobId = $self->{"jobId"};
	my $step  = $self->GetStep();

	my $result = 1;

	# Check if panel step exist
	if ( !CamHelper->StepExists( $inCAM, $jobId, $step ) ) {
		$result = 0;
		$$errMess .= "Panel step: $step doesn't exist in job.";
	}
	else {

		# Check if panel profile exist
		my %profLim = CamJob->GetProfileLimits2( $inCAM, $jobId, $step );
		if (    abs( $profLim{"xMax"} - $profLim{"xMin"} ) <= 0
			 || abs( $profLim{"yMax"} - $profLim{"yMin"} ) <= 0 )
		{
			$result = 0;
			$$errMess .= "Panel step ($step) profile has invalid dimension";

		}

		# 1) Check if nested step exists
		my $nestStep = $self->GetPCBStep();
		if ( !defined $nestStep || $nestStep eq "" ) {
			$result = 0;
			$$errMess .= "Nested step name is not defined";

		}

		# Check if nested step exist in job
		if ( defined $nestStep && $nestStep ne "" ) {

			if ( !CamHelper->StepExists( $inCAM, $jobId, $nestStep ) ) {
				$result = 0;
				$$errMess .= "Nested step: $nestStep doesn't exist in job.";
			}
		}

		if ( $self->GetActionType() eq Enums->StepPlacementMode_AUTO ) {

			my $minUtil = $self->GetMinUtilization();

			# Check if nested step exist in job
			if ( !defined $minUtil || $minUtil eq "" || $minUtil < 0 || $minUtil > 100 ) {
				$result = 0;
				$$errMess .= "Wrong value of Minimal utilization: $minUtil";
			}

			# Space X
			my $spaceX = $self->GetSpaceX();

			if ( !defined $spaceX || $spaceX eq "" || $spaceX < 0 ) {
				$result = 0;
				$$errMess .= "Wrong value of Space X: $spaceX";
			}

			# Space Y
			my $spaceY = $self->GetSpaceY();

			if ( !defined $spaceY || $spaceY eq "" || $spaceY < 0 ) {
				$result = 0;
				$$errMess .= "Wrong value of Space Y: $spaceY";
			}

			# Units per panel check
			my $unitPerPanel = 0;
			my $numMaxSteps  = "no_limit";

			if ( $self->GetAmountType() eq Enums->StepAmount_AUTO ) {

				$unitPerPanel = "automatic";
				$numMaxSteps  = "no_limit";

			}
			elsif ( $self->GetAmountType() eq Enums->StepAmount_EXACT ) {

				$unitPerPanel = $self->GetExactQuantity();
				$numMaxSteps  = "no_limit";

			}
			elsif ( $self->GetAmountType() eq Enums->StepAmount_MAX ) {

				$unitPerPanel = "automatic";
				$numMaxSteps  = $self->GetMaxQuantity();
			}

			if ( !defined $unitPerPanel || ( $unitPerPanel ne "automatic" && $unitPerPanel <= 0 ) ) {
				$result = 0;
				$$errMess .= "Wrong value ($unitPerPanel) of step amount amount";
			}

			if ( !defined $numMaxSteps || ( $numMaxSteps ne "no_limit" && $numMaxSteps <= 0 ) ) {
				$result = 0;
				$$errMess .= "Wrong value ($numMaxSteps) of step max step amount";
			}

		}
		elsif ( $self->GetActionType() eq Enums->StepPlacementMode_MANUAL ) {

			if ( $self->GetManualPlacementStatus() eq EnumsGeneral->ResultType_NA ) {

				# OK, Auto part placement will return panel resutls

			}
			elsif ( $self->GetManualPlacementStatus() eq EnumsGeneral->ResultType_FAIL ) {

				$result = 0;
				$$errMess .= "Manual panel step palcement is not set";

			}
			elsif ( $self->GetManualPlacementStatus() eq EnumsGeneral->ResultType_OK ) {

				unless ( defined $self->GetManualPlacementJSON() ) {

					# JSON placement is not defined
					$result = 0;
					$$errMess .= "Manual panel step palcement error. Missing JSON panel placement.";
				}

			}

		}
	}
	return $result;

}

# Return 1 if succes 0 if fail
sub _Process {
	my $self    = shift;
	my $inCAM   = shift;
	my $errMess = shift;    # reference to err message

	my $result = 1;

	my $jobId = $self->{"jobId"};
	my $step  = $self->GetStep();

	# Process by auto/manual choice
	CamHelper->SetStep( $inCAM, $self->GetStep() );

	# Add size (get from step profile)
	my %profLim = CamJob->GetProfileLimits2( $inCAM, $jobId, $step );
	my $w       = abs( $profLim{"xMax"} - $profLim{"xMin"} );
	my $h       = abs( $profLim{"yMax"} - $profLim{"yMin"} );

	# Add border (get from step profile) + spacing
	my %areaLim = CamStep->GetActiveAreaLim( $inCAM, $jobId, $step );
	my $areaW   = abs( $areaLim{"xMax"} - $areaLim{"xMin"} );
	my $areaH   = abs( $areaLim{"yMax"} - $areaLim{"yMin"} );

	my $bL = abs( $profLim{"xMin"} - $areaLim{"xMin"} );
	my $bR = abs( $profLim{"xMax"} - $areaLim{"xMax"} );
	my $bT = abs( $profLim{"yMax"} - $areaLim{"yMax"} );
	my $bB = abs( $profLim{"yMin"} - $areaLim{"yMin"} );

	#  border width has to be smaller than total panel dimension
	if ( ( $bL + $bR ) >= $w ) {

		$result = 0;
		$$errMess .= "Border width left (${bL}mm) + right (${bR}mm) is larger than panel width: ${w}mm.\n";
		$self->__ClearSteps($inCAM);

		return $result;
	}

	if ( ( $bT + $bB ) >= $h ) {

		$result = 0;
		$$errMess .= "Border width left (${bT}mm) + right (${bB}mm) is larger than panel width: ${h}mm.\n";
		$self->__ClearSteps($inCAM);

		return $result;
	}

	# Active area has to be larger than step
	my $nestStep    = $self->GetPCBStep();
	my %nestStepLim = CamJob->GetProfileLimits2( $inCAM, $jobId, $nestStep );
	my $nestStepW   = abs( $nestStepLim{"xMax"} - $nestStepLim{"xMin"} );
	my $nestStepH   = abs( $nestStepLim{"yMax"} - $nestStepLim{"yMin"} );

	if ( !( max( $nestStepW, $nestStepH ) < max( $areaW, $areaH ) && min( $nestStepW, $nestStepH ) < min( $areaW, $areaH ) ) ) {

		$result = 0;
		$$errMess .=
		  "Nested step: $nestStep profile dimensions ( ${nestStepW} x ${nestStepH}mm) are larger than panel active area ( ${areaW} x ${areaH}mm)\n";
		$self->__ClearSteps($inCAM);
		return $result;
	}

	# Create panel (best utilization)

	my $unitPerPanel = 0;
	my $numMaxSteps  = "no_limit";

	if ( $self->GetAmountType() eq Enums->StepAmount_AUTO ) {

		$unitPerPanel = "automatic";
		$numMaxSteps  = "no_limit";

	}
	elsif ( $self->GetAmountType() eq Enums->StepAmount_EXACT ) {

		#$unitPerPanel = $self->GetExactQuantity();
		$unitPerPanel = "automatic";
		$numMaxSteps  = $self->GetExactQuantity()

	}
	elsif ( $self->GetAmountType() eq Enums->StepAmount_MAX ) {

		$unitPerPanel = "automatic";
		$numMaxSteps  = $self->GetMaxQuantity();
	}

	# Raise error if nested steps are greater thjan active area
	# Raise error alwas if there is no solution of panelisation (nested step == 0)

	my $autoPart = AutoPart->new( $inCAM, $jobId, $step );

	if ( $self->GetActionType() eq Enums->StepPlacementMode_AUTO ) {

		$inCAM->COM( "show_component", "component" => "Result_Viewer", "show" => "no" );

		my %autoRes = ();
		try {

			%autoRes = $autoPart->SRAutoPartPanelise(
				$w, $h, $bT, $bB, $bL, $bR, $self->GetSpaceX(), $self->GetSpaceY(),

				$self->GetPCBStep(),
				$unitPerPanel,
				$self->GetMinUtilization(),
				1,
				undef,
				1,
				undef,
				undef,
				$self->GetAlignType(),
				$numMaxSteps,
				$self->GetPlacementType(),
				$self->GetRotationType(),
				$self->GetPatternType(),
				undef,
				$self->GetInterlockType(),
				0, 0, 0
			);

		}
		catch {

			my $e = $_;
			$autoRes{"result"} = 0;
		};

		if ( !$autoRes{"result"} ) {

			$$errMess .= " \"Auto part algorithm\" is not able to panelise steps (result is 0 nested steps in panel)";
			$$errMess .= " \nChange panelise settings";
			$result = 0;
			$self->__ClearSteps($inCAM);
		}

		if ( $autoRes{"result"} ) {

			my $clearSteps = 0;

			if ( $autoRes{"stepCnt"} == 0 ) {
				$$errMess .= " \"Auto part algorithm\" is not able to panelise steps (result is 0 nested steps in panel)";
				$$errMess .= " \nChange panelise settings";
				$result = 0;
				$self->__ClearSteps($inCAM);
			}

			if ( $self->GetAmountType() eq Enums->StepAmount_EXACT && $self->GetExactQuantity() != $autoRes{"stepCnt"} ) {
				$$errMess .= " \"Auto part algorithm\" is not able to panelise required exact step amount: " . $self->GetExactQuantity();
				$$errMess .= " \nMax possible step amount with current settings is: " . $autoRes{"stepCnt"};
				$result = 0;
				$self->__ClearSteps($inCAM);
			}

			if ( $self->GetMinUtilization() > $autoRes{"utilization"} ) {
				$$errMess .= " \"Auto part algorithm\" is not able to panelise with minimal utilization: " . $self->GetMinUtilization() . "%";
				$$errMess .= " \nMax possible panel utilization with current settings is: " . $autoRes{"utilization"} . "%";
				$result = 0;
				$self->__ClearSteps($inCAM);
			}

		}

	}
	elsif ( $self->GetActionType() eq Enums->StepPlacementMode_MANUAL ) {

		# Check if manual placement already exist
		if ( $self->GetManualPlacementStatus() eq EnumsGeneral->ResultType_OK ) {

			my $pnlToJSON = PnlToJSON->new( $inCAM, $jobId, $step );
			$pnlToJSON->CreatePnlByJSON( $self->GetManualPlacementJSON(), 1, 1, 0 );

		}
		elsif ( $self->GetManualPlacementStatus() eq EnumsGeneral->ResultType_NA ) {

			$self->__ClearSteps($inCAM);

			$inCAM->COM( "set_subsystem", "name" => "Panel-Design" );
			CamHelper->SetStep( $inCAM, $self->GetStep() );

			# Add specific width + height
			$autoPart->AutoPartAddPnlSize( $w, $h );

			# Add specific border
			$autoPart->AutoPartAddPnlBorderSpacing( $bT, $bB, $bL, $bR, $self->GetSpaceX(), $self->GetSpaceY() );

			$autoPart->AutoPartPanelise(

										$self->GetPCBStep(),
										$unitPerPanel,
										$self->GetMinUtilization(),
										1,
										undef,
										0,
										undef,
										undef,
										$self->GetAlignType(),
										$numMaxSteps,
										$self->GetPlacementType(),
										$self->GetRotationType(),
										$self->GetPatternType(),
										undef,
										$self->GetInterlockType(),
										0, 0, 0
			);

			$inCAM->COM( "top_tab", "tab" => "AutoPartPlaceResults" );
		}
	}

	return $result;
}

sub __ClearSteps {
	my $self  = shift;
	my $inCAM = shift;

	my $jobId = $self->{"jobId"};

	foreach my $step ( CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobId, $self->GetStep() ) ) {
		CamStepRepeat->DeleteStepAndRepeat( $inCAM, $jobId, $self->GetStep(), $step->{"stepName"} );
	}
}

#-------------------------------------------------------------------------------------------#
# Get/Set method for adjusting settings after Init/ImportSetting
#-------------------------------------------------------------------------------------------#

sub GetPnlClasses {
	my $self = shift;

	return $self->{"settings"}->{"pnlClasses"};
}

sub SetPnlClasses {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"pnlClasses"} = $val;
}

sub GetDefPnlClass {
	my $self = shift;

	return $self->{"settings"}->{"defPnlClass"};
}

sub SetDefPnlClass {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"defPnlClass"} = $val;
}

sub GetDefPnlSpacing {
	my $self = shift;

	return $self->{"settings"}->{"defPnlSpacing"};
}

sub SetDefPnlSpacing {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"defPnlSpacing"} = $val;
}

sub SetPCBStepsList {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"pcbStepsList"} = $val;

}

sub GetPCBStepsList {
	my $self = shift;

	return $self->{"settings"}->{"pcbStepsList"};

}

sub SetPCBStep {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"pcbStep"} = $val;

}

sub GetPCBStep {
	my $self = shift;

	return $self->{"settings"}->{"pcbStep"};

}

# Placement settings

sub SetPlacementType {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"placementType"} = $val;

}

sub GetPlacementType {
	my $self = shift;

	return $self->{"settings"}->{"placementType"};

}

sub SetRotationType {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"rotationType"} = $val;
}

sub GetRotationType {
	my $self = shift;

	return $self->{"settings"}->{"rotationType"};
}

sub SetPatternType {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"patternType"} = $val;
}

sub GetPatternType {
	my $self = shift;

	return $self->{"settings"}->{"patternType"};
}

sub SetInterlockType {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"interlockType"} = $val;
}

sub GetInterlockType {
	my $self = shift;

	return $self->{"settings"}->{"interlockType"};
}

# Space settings

sub SetSpaceX {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"spaceX"} = $val;

}

sub GetSpaceX {
	my $self = shift;

	return $self->{"settings"}->{"spaceX"};

}

sub SetSpaceY {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"spaceY"} = $val;

}

sub GetSpaceY {
	my $self = shift;

	return $self->{"settings"}->{"spaceY"};

}

sub SetAlignType {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"alignType"} = $val;

}

sub GetAlignType {
	my $self = shift;

	return $self->{"settings"}->{"alignType"};

}

# Amount settings

sub SetAmountType {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"amountType"} = $val;

}

sub GetAmountType {
	my $self = shift;

	return $self->{"settings"}->{"amountType"};

}

sub SetExactQuantity {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"exactQuantity"} = $val;

}

sub GetExactQuantity {
	my $self = shift;

	return $self->{"settings"}->{"exactQuantity"};

}

sub SetMaxQuantity {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"maxQuantity"} = $val;

}

sub GetMaxQuantity {
	my $self = shift;

	return $self->{"settings"}->{"maxQuantity"};

}

# Panelisation

sub SetActionType {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"actionType"} = $val;

}

sub GetActionType {
	my $self = shift;

	return $self->{"settings"}->{"actionType"};

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

sub SetMinUtilization {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"minUtilization"} = $val;

}

sub GetMinUtilization {
	my $self = shift;

	return $self->{"settings"}->{"minUtilization"};

}

# Step dimenson
#
#sub SetWidth {
#	my $self = shift;
#	my $val  = shift;
#
#	$self->{"settings"}->{"width"} = $val;
#}
#
#sub GetWidth {
#	my $self = shift;
#
#	return $self->{"settings"}->{"width"};
#}
#
#sub SetHeight {
#	my $self = shift;
#	my $val  = shift;
#
#	$self->{"settings"}->{"height"} = $val;
#}
#
#sub GetHeight {
#	my $self = shift;
#
#	return $self->{"settings"}->{"height"};
#}
#
#sub SetBorderLeft {
#	my $self = shift;
#	my $val  = shift;
#
#	$self->{"settings"}->{"borderLeft"} = $val;
#}
#
#sub GetBorderLeft {
#	my $self = shift;
#
#	return $self->{"settings"}->{"borderLeft"};
#}
#
#sub SetBorderRight {
#	my $self = shift;
#	my $val  = shift;
#
#	$self->{"settings"}->{"borderRight"} = $val;
#}
#
#sub GetBorderRight {
#	my $self = shift;
#
#	return $self->{"settings"}->{"borderRight"};
#}
#
#sub SetBorderTop {
#	my $self = shift;
#	my $val  = shift;
#
#	$self->{"settings"}->{"borderTop"} = $val;
#}
#
#sub GetBorderTop {
#	my $self = shift;
#
#	return $self->{"settings"}->{"borderTop"};
#}
#
#sub SetBorderBot {
#	my $self = shift;
#	my $val  = shift;
#
#	$self->{"settings"}->{"borderBot"} = $val;
#}
#
#sub GetBorderBot {
#	my $self = shift;
#
#	return $self->{"settings"}->{"borderBot"};
#}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

