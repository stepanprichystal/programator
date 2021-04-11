
#-------------------------------------------------------------------------------------------#
# Description: Parse information from InCAM global Library Panel classes
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlCreator::Helpers::PnlToJSON;

#3th party library
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Packages::CAMJob::Panelization::SRStep';
use aliased 'Packages::ObjectStorable::JsonStorable::JsonStorable';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;

	my $self = {};
	bless $self;

	# Properties
	$self->{"inCAM"} = $inCAM;
	$self->{"jobId"} = $jobId;
	$self->{"step"}  = $step;

	$self->{"jsonStorable"} = JsonStorable->new();

	return $self;
}

sub CheckBeforeParse {
	my $self    = shift;
	my $errMess = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	my $result = 1;

	# 1) Check if step exist
	unless ( CamHelper->StepExists( $inCAM, $jobId, $step ) ) {

		$$errMess .= "Step: $step doesn't exist";
		$result = 0;

		return $result;

	}

	# 2) Check if nested steps
	my @steps = CamStepRepeat->GetRepeatStep( $inCAM, $jobId, $step );

	if ( scalar(@steps) == 0 ) {

		$$errMess .= "No nested step in panel";
		$result = 0;
	}

	return $result;

}

sub ParsePnlToJSON {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	my %sett = ();

	# Panel + active area limits
	my %profLim = CamJob->GetProfileLimits2( $inCAM, $jobId, $step, 1 );
	my %areaLim = CamStep->GetActiveAreaLim( $inCAM, $jobId, $step, 1 );

	$sett{"profLim"}         = \%profLim;
	$sett{"areaLim"}         = \%areaLim;
	$sett{"profZero"}->{"x"} = $profLim{"xMin"};
	$sett{"profZero"}->{"y"} = $profLim{"yMin"};

	# Step placement

	my @steps = CamStepRepeat->GetStepAndRepeat( $inCAM, $jobId, $step );
	$sett{"sr"} = \@steps;

	my $JSON = $self->{"jsonStorable"}->Encode( \%sett );

	return $JSON;
}

sub CreatePnlByJSON {
	my $self = shift;
	my $JSON = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	my %sett = %{ $self->{"jsonStorable"}->Decode($JSON) };
	my $SRStep = SRStep->new( $inCAM, $jobId, $step );

	my $bL = abs( $sett{"profLim"}->{"xMin"} - $sett{"areaLim"}->{"xMin"} );
	my $bR = abs( $sett{"profLim"}->{"xMax"} - $sett{"areaLim"}->{"xMax"} );
	my $bT = abs( $sett{"profLim"}->{"yMax"} - $sett{"areaLim"}->{"yMax"} );
	my $bB = abs( $sett{"profLim"}->{"yMin"} - $sett{"areaLim"}->{"yMin"} );

	my $w = abs( $sett{"profLim"}->{"xMax"} - $sett{"profLim"}->{"xMin"} );
	my $h = abs( $sett{"profLim"}->{"yMax"} - $sett{"profLim"}->{"yMin"} );

	$SRStep->Create( $w, $h, $bT, $bB, $bL, $bR, $sett{"profZero"} );

	foreach my $sr ( @{ $sett{"sr"} } ) {

		$SRStep->AddSRStep( $sr->{"stepName"}, $sr->{"gSRxa"}, $sr->{"gSRya"}, $sr->{"gSRangle"},
							$sr->{"gSRnx"},    $sr->{"gSRny"}, $sr->{"gSRdx"}, $sr->{"gSRdy"} );
	}

	return 1;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Packages::CAM::PanelClass::PnlClassParser';
	#	use aliased 'Packages::InCAM::InCAM';
	#	use aliased 'Packages::InCAM::InCAM';
	#
	#	my $inCAM = InCAM->new();
	#
	#	my $jobId = "d222606";
	#	my $parser = PnlClassParser->new( $inCAM, $jobId );
	#	$parser->Parse();
	#
	#	my @classes  = $parser->GetClassesProductionPanel();
	#	my @mclasses = $parser->GetClassesCustomerPanel();
	#
	#	die;
}

1;

