
#-------------------------------------------------------------------------------------------#
# Description: Class is responsible for creating panel profile
# Import/Export settings method are meant for using class in bacground
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlCreator::SizePnlCreator::MatrixSize;
use base('Programs::Panelisation::PnlCreator::PnlCreatorBase');

use Class::Interface;
&implements('Programs::Panelisation::PnlCreator::SizePnlCreator::ISize');

#3th party library
use strict;
use warnings;
use Scalar::Util qw(looks_like_number);

#local library
use aliased 'Programs::Panelisation::PnlCreator::Enums';
use aliased 'Packages::CAMJob::Panelization::SRStep';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStep';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class   = shift;
	my $jobId   = shift;
	my $pnlType = shift;
	my $key     = Enums->SizePnlCreator_MATRIX;

	my $self = $class->SUPER::new( $jobId, $pnlType, $key );
	bless $self;

	# Setting values necessary for procesing panelisation
	$self->{"settings"}->{"width"}       = 0;
	$self->{"settings"}->{"height"}      = 0;
	$self->{"settings"}->{"borderLeft"}  = 0;
	$self->{"settings"}->{"borderRight"} = 0;
	$self->{"settings"}->{"borderTop"}   = 0;
	$self->{"settings"}->{"borderBot"}   = 0;

	#$self->{"settings"}->{"activeAreaW"} = 0;
	#$self->{"settings"}->{"activeAreaH"} = 0;

	return $self;    #
}

#-------------------------------------------------------------------------------------------#
# Interface method
#-------------------------------------------------------------------------------------------#

use constant MINAREA => 10;    # 1mm

# Init creator class in order process panelisation
# (instead of Init method is possible init by import JSON settings)
# Return 1 if succes 0 if fail
sub Init {
	my $self     = shift;
	my $inCAM    = shift;
	my $stepName = shift;

	my $result = 1;

	$self->SetStep($stepName);

	# Set defualt active area 100mm
	# If active area would have dimension 0x0mm, InCAM is unable to return active area limits
	# Thats why 100mm

	$self->SetBorderLeft(10);
	$self->SetBorderRight(10);
	$self->SetBorderTop(10);
	$self->SetBorderBot(10);

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

	my $bL = $self->GetBorderLeft();
	my $bR = $self->GetBorderRight();
	my $bT = $self->GetBorderTop();
	my $bB = $self->GetBorderBot();
	#
	#	if ( !defined $areaH || $areaH eq "" || !looks_like_number($areaH) ) {
	#
	#		$result = 0;
	#		$$errMess .= "Panel active area height is not defined.\n";
	#	}
	#	else {
	#
	#		if ( $areaH < MINAREA ) {
	#
	#			$result = 0;
	#			$$errMess .= "Panel active area (${areaH}mm) height has to be larget than:" . MINAREA;
	#		}
	#
	#	}
	#
	#	if ( !defined $areaW || $areaW eq "" || !looks_like_number($areaW) ) {
	#
	#		$result = 0;
	#		$$errMess .= "Panel active area width is not defined.\n";
	#
	#		if ( $areaW < MINAREA ) {
	#
	#			$result = 0;
	#			$$errMess .= "Panel active area (${areaW}mm) height has to be larget than:" . MINAREA;
	#		}
	#	}

	if (    !defined $bL
		 || !defined $bR
		 || !defined $bT
		 || !defined $bB
		 || $bL eq ""
		 || $bR eq ""
		 || $bT eq ""
		 || $bB eq ""
		 || !looks_like_number($bL)
		 || !looks_like_number($bR)
		 || !looks_like_number($bT)
		 || !looks_like_number($bB)
		 || $bL < 0
		 || $bR < 0
		 || $bT < 0
		 || $bB < 0 )
	{

		$result = 0;
		$$errMess .= "Not all panel borders are defined (border must be number  >= 0).\n";
	}

	return $result;

}

# Return 1 if succes 0 if fail
# Process method only resize panel based on new border and active area dimension
# If there are alreadz steps included, move them according new border
sub Process {
	my $self    = shift;
	my $inCAM   = shift;
	my $errMess = shift;    # reference to err message

	my $jobId = $self->{"jobId"};
	my $step  = $self->GetStep();

	my $result = 1;

	#my $areaH = $self->GetActiveAreaH();
	#my $areaW = $self->GetActiveAreaW();
	my $bL = $self->GetBorderLeft();
	my $bR = $self->GetBorderRight();
	my $bT = $self->GetBorderTop();
	my $bB = $self->GetBorderBot();

	$self->_CreateStep($inCAM);

	my @sr = CamStepRepeat->GetStepAndRepeat( $inCAM, $jobId, $step );

	# 1) If in panel exist SR, take area from existing panel
	my $oriAreaH = undef;
	my $oriAreaW = undef;
	my $oriBL    = undef;

	#my $oriBR    = undef;
	#my $oriBT    = undef;
	my $oriBB = undef;

	if ( scalar(@sr) ) {
		my %profLim = CamJob->GetProfileLimits2( $inCAM, $jobId, $step );
		my %areaLim = CamStep->GetActiveAreaLim( $inCAM, $jobId, $step );

		$oriBL = abs( $profLim{"xMin"} - $areaLim{"xMin"} );

		#$oriBR    = abs( $profLim{"xMax"} - $areaLim{"xMax"} );
		#$oriBT    = abs( $profLim{"yMax"} - $areaLim{"yMax"} );
		$oriBB    = abs( $profLim{"yMin"} - $areaLim{"yMin"} );
		$oriAreaW = abs( $areaLim{"xMax"} - $areaLim{"xMin"} );
		$oriAreaH = abs( $areaLim{"yMax"} - $areaLim{"yMin"} );
	}

	# 2)
	my $SRStep = SRStep->new( $inCAM, $jobId, $self->GetStep() );

	#	#	my %p = ("x"=> -10, "y" => -20);
	#	$step->Edit( $self->GetWidth(),      $self->GetHeight(), $self->GetBorderTop(), $self->GetBorderBot(),
	#				 $self->GetBorderLeft(), $self->GetBorderRight() );

	# Check if there are SR

	unless ( scalar(@sr) ) {

		# Unless exist SR, it means, set default active area

		my $w = MINAREA + $bL + $bR;
		my $h = MINAREA + $bT + $bB;

		$SRStep->Edit( $w, $h, $bT, $bB, $bL, $bR );

	}
	else {

		# if exist SR,  use existing active area

		my $w = $oriAreaW + $bL + $bR;
		my $h = $oriAreaH + $bT + $bB;

		$SRStep->Edit( $w, $h, $bT, $bB, $bL, $bR );

		my $dBorderLeft = $oriBL - $bL;
		my $dBorderBot  = $oriBB - $bB;

		for ( my $i = 0 ; $i < scalar(@sr) ; $i++ ) {

			my $srRow = $sr[$i];

			CamStepRepeat->ChangeStepAndRepeat(
												$inCAM,                          $jobId,
												$step,                           $i + 1,
												$srRow->{"gSRstep"},             $srRow->{"gSRxa"} - $dBorderLeft,
												$srRow->{"gSRya"} - $dBorderBot, $srRow->{"gSRdx"},
												$srRow->{"gSRdy"},               $srRow->{"gSRnx"},
												$srRow->{"gSRny"},               $srRow->{"gSRangle"},
												"ccw",                           $srRow->{"gSRmirror"},
												$srRow->{"gSRflip"}
			);
		}

	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
# Get/Set method for adjusting settings after Init/ImportSetting
#-------------------------------------------------------------------------------------------#

sub SetWidth {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"width"} = $val;
}

sub GetWidth {
	my $self = shift;

	return $self->{"settings"}->{"width"};
}

sub SetHeight {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"height"} = $val;
}

sub GetHeight {
	my $self = shift;

	return $self->{"settings"}->{"height"};
}

sub SetBorderLeft {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"borderLeft"} = $val;
}

sub GetBorderLeft {
	my $self = shift;

	return $self->{"settings"}->{"borderLeft"};
}

sub SetBorderRight {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"borderRight"} = $val;
}

sub GetBorderRight {
	my $self = shift;

	return $self->{"settings"}->{"borderRight"};
}

sub SetBorderTop {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"borderTop"} = $val;
}

sub GetBorderTop {
	my $self = shift;

	return $self->{"settings"}->{"borderTop"};
}

sub SetBorderBot {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"borderBot"} = $val;
}

sub GetBorderBot {
	my $self = shift;

	return $self->{"settings"}->{"borderBot"};
}
#
#sub SetActiveAreaW {
#	my $self = shift;
#	my $val  = shift;
#
#	$self->{"settings"}->{"activeAreaW"} = $val;
#
#}
#
#sub GetActiveAreaW {
#	my $self = shift;
#
#	return $self->{"settings"}->{"activeAreaW"};
#}
#
#sub SetActiveAreaH {
#	my $self = shift;
#	my $val  = shift;
#
#	$self->{"settings"}->{"activeAreaH"} = $val;
#}
#
#sub GetActiveAreaH {
#	my $self = shift;
#
#	return $self->{"settings"}->{"activeAreaH"};
#}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

