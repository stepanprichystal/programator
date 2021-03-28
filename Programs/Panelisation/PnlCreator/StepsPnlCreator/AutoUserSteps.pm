
#-------------------------------------------------------------------------------------------#
# Description: Class is responsible for step placement to panel
# Import/Export settings method are meant for using class in bacground
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlCreator::StepsPnlCreator::AutoUserSteps;
use base('Programs::Panelisation::PnlCreator::PnlCreatorBase');

use Class::Interface;
&implements('Programs::Panelisation::PnlCreator::StepsPnlCreator::ISteps');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Panelisation::PnlCreator::Enums';
use aliased 'Packages::CAM::PanelClass::Enums' => "PnlClassEnums";
use aliased 'Programs::Panelisation::PnlCreator::Helpers::PnlClassParser';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStep';
use aliased 'Packages::CAMJob::Panelization::AutoPart';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class   = shift;
	my $jobId   = shift;
	my $pnlType = shift;
	my $key     = Enums->StepPnlCreator_AUTOUSER;

	my $self = $class->SUPER::new( $jobId, $pnlType, $key );
	bless $self;

	$self->{"settings"}->{"pnlClasses"}        = undef;
	$self->{"settings"}->{"defPnlClass"}       = undef;
	$self->{"settings"}->{"defPnlSpacing"}     = undef;
	$self->{"settings"}->{"pcbStep"}           = undef;
	$self->{"settings"}->{"placementType"}     = PnlClassEnums->PnlClassTransform_ROTATION;
	$self->{"settings"}->{"rotationType"}      = undef;
	$self->{"settings"}->{"patternType"}       = undef;
	$self->{"settings"}->{"interlockType"}     = undef;
	$self->{"settings"}->{"spaceX"}            = undef;
	$self->{"settings"}->{"spaceY"}            = undef;
	$self->{"settings"}->{"alignType"}         = undef;
	$self->{"settings"}->{"amountType"}        = Enums->StepAmount_EXACT;
	$self->{"settings"}->{"exactQuantity"}     = undef;
	$self->{"settings"}->{"maxQuantity"}       = undef;
	$self->{"settings"}->{"autoQuantity"}      = undef;
	$self->{"settings"}->{"actionType"}        = Enums->StepPlacementMode_AUTO;
	$self->{"settings"}->{"JSONStepPlacement"} = undef;
	$self->{"settings"}->{"minUtilization"}    = undef;

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
sub Init {
	my $self     = shift;
	my $inCAM    = shift;
	my $stepName = shift;

	my $result = 1;

	my $jobId = $self->{'jobId'};

	$self->{"settings"}->{"step"} = $stepName;

	if ( $self->GetPnlType() eq Enums->PnlType_CUSTOMERPNL ) {

		$self->SetPCBStep("o+1");
	}
	elsif ( $self->GetPnlType() eq Enums->PnlType_PRODUCTIONPNL ) {

		if ( CamHelper->StepExists( $inCAM, $jobId, "mpanel" ) ) {
			$self->SetPCBStep("mpanel");
		}
		else {
			$self->SetPCBStep("o+1");
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

	# Set amount settings
	$self->SetAmountType( Enums->StepAmount_AUTO );

	# Set action type

	$self->SetActionType( Enums->StepPlacementMode_AUTO );

	return $result;

}

# Do necessary check before processing panelisation
# This method is called always before Process method
# Return 1 if succes 0 if fail
sub Check {
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
	if ( CamHelper->StepExists( $inCAM, $jobId, $nestStep ) ) {
		$result = 0;
		$$errMess .= "Nested step: $nestStep doesn't exist in job.";
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

	if ( $self->GetActionType() eq Enums->StepPlacementMode_AUTO ) {

		my $autoPart = AutoPart->new( $inCAM, $jobId, $step );

		# Add size (get from step profile)
		my %profLim = CamJob->GetProfileLimits2( $inCAM, $jobId, $step );
		my $w       = abs( $profLim{"xMax"} - $profLim{"xMin"} );
		my $h       = abs( abs( $profLim{"yMax"} - $profLim{"yMin"} ) <= 0 );

		$autoPart->AddPnlSize( $w, $h );

		# Add border (get from step profile) + spacing
		my %areaLim = CamStep->GetActiveAreaLim( $inCAM, $jobId, $step );

		my $bL = abs( $profLim{"xMin"} - $areaLim{"xMin"} );
		my $bR = abs( $profLim{"xMax"} - $areaLim{"xMax"} );
		my $bT = abs( $profLim{"yMax"} - $areaLim{"yMax"} );
		my $bB = abs( $profLim{"yMin"} - $areaLim{"yMin"} );

		$autoPart->AddPnlBorderSpacing( $bT, $bB, $bL, $bR, $self->GetSpaceX(), $self->GetSpaceY() );

		# Create panel (best utilization)

		my $unitPerPanel = 0;
		my $numMaxSteps  = "no_limit";

		if ( $self->GetAmountType() eq Enums->StepAmount_AUTO ) {

			$unitPerPanel = "automatic";

		}
		elsif ( $self->GetAmountType() eq Enums->StepAmount_EXACT ) {
			$unitPerPanel = $self->GetExactQuantity();

		}
		elsif ( $self->GetAmountType() eq Enums->StepAmount_EXACT ) {

			$unitPerPanel = "automatic";
			$numMaxSteps  = $self->GetMaxQuantity();
		}

		$autoPart->Panelise(
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
	return $result;
}

#-------------------------------------------------------------------------------------------#
# Get/Set method for adjusting settings after Init/ImportSetting
#-------------------------------------------------------------------------------------------#

sub GetPnlClasses {
	my $self = shift;

	return $self->{"settings"}->{"pnlClasses"};
}

sub GetDefPnlClass {
	my $self = shift;

	return $self->{"settings"}->{"defPnlClass"};
}

sub GetDefPnlSpacing {
	my $self = shift;

	return $self->{"settings"}->{"defPnlSpacing"};
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

sub SetJSONStepPlacement {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"JSONStepPlacement"} = $val;

}

sub GetJSONStepPlacement {
	my $self = shift;

	return $self->{"settings"}->{"JSONStepPlacement"};

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

