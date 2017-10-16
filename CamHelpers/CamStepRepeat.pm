#-------------------------------------------------------------------------------------------#
# Description: Helper class, operation which are working with S&R
# Author:SPR
#-------------------------------------------------------------------------------------------#

package CamHelpers::CamStepRepeat;

#3th party library
use strict;
use warnings;
use List::Util qw[max];

#loading of locale modules
#use aliased 'Helpers::JobHelper';
#use aliased 'Enums::EnumsPaths';
#use aliased 'Packages::InCAM::InCAM';
#use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

# Return depth of SR in given step
# 1 - means, there is panel and 1up nested steps inside
# 2 - means, there is panel, inside panel which contain 1up steps inside
sub GetStepAndRepeatDepth {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;

	my @uniqueSteps = ();

	my %step = ( "stepName" => $stepName, "depth" => 0 );

	my $depth = -1;

	$self->__ExploreStepDepth( $inCAM, $jobId, \%step, \@uniqueSteps, $depth );

	# remove inspected step, we want only nested
	@uniqueSteps = map { $_->{"depth"} } @uniqueSteps;

	my $depthMax = max(@uniqueSteps);

	return $depthMax;
}

sub __ExploreStepDepth {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $exploreStep = shift;
	my $uniqueSteps = shift;
	my $depth       = shift;

	my @childs = $self->GetUniqueStepAndRepeat( $inCAM, $jobId, $exploreStep->{"stepName"} );

	$depth++;

	if ( scalar(@childs) ) {

		# recusive search another nested steps
		foreach my $ch (@childs) {

			$self->__ExploreStepDepth( $inCAM, $jobId, $ch, $uniqueSteps, $depth );

		}
	}

	# this step has no childern, test, if is not already in array

	$exploreStep->{"depth"} = $depth;

	push( @{$uniqueSteps}, $exploreStep );

}

#Return information about all nested steps (in all deepness) steps in given step
sub GetUniqueNestedStepAndRepeat {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;

	my @uniqueSteps = ();

	my %step = ( "stepName" => $stepName );

	$self->__ExploreStep( $inCAM, $jobId, \%step, \@uniqueSteps );

	# remove inspected step, we want only nested
	@uniqueSteps = grep { $_->{"stepName"} ne $stepName } @uniqueSteps;

	return @uniqueSteps;
}

# Return information about deepest nested steps, which doesn't contain another SR
sub GetUniqueDeepestSR {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;

	my @uniqueSteps = ();

	my %step = ( "stepName" => $stepName );

	$self->__ExploreStep( $inCAM, $jobId, \%step, \@uniqueSteps );

	# Remove inspected step, we want only nested
	@uniqueSteps = grep { $_->{"stepName"} ne $stepName } @uniqueSteps;

	my @deepest = ();
	foreach my $s (@uniqueSteps) {

		unless ( $self->ExistStepAndRepeats( $inCAM, $jobId, $s->{"stepName"} ) ) {
			push( @deepest, $s );
		}
	}

	return @deepest;
}

sub __ExploreStep {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $exploreStep = shift;
	my $uniqueSteps = shift;

	my @childs = $self->GetUniqueStepAndRepeat( $inCAM, $jobId, $exploreStep->{"stepName"} );

	if ( scalar(@childs) ) {

		# recusive search another nested steps
		foreach my $ch (@childs) {

			$self->__ExploreStep( $inCAM, $jobId, $ch, $uniqueSteps );

		}
	}

	# this step has no childern, test, if is not already in array
	my $exist = scalar( grep { $_->{"stepName"} eq $exploreStep->{"stepName"} } @{$uniqueSteps} );

	unless ($exist) {

		push( @{$uniqueSteps}, $exploreStep );
	}

}

#Return information about steps in given step
sub GetUniqueStepAndRepeat {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;

	my @steps = ();
	my @arr = $self->GetStepAndRepeat( $inCAM, $jobId, $stepName );

	foreach my $info (@arr) {

		unless ( scalar( grep { $_->{"stepName"} eq $info->{"gSRstep"} } @steps ) ) {
			my %stepInf = ();
			$stepInf{"stepName"} = $info->{"gSRstep"};

			push( @steps, \%stepInf );
		}
	}

	return @steps;
}

#Return information about steps in given step
sub GetStepAndRepeat {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;

	my @arr = ();

	$inCAM->INFO( "units" => "mm", entity_type => 'step', angle_direction => 'ccw', entity_path => "$jobId/$stepName", data_type => 'SR' );

	for ( my $i = 0 ; $i < scalar( @{ $inCAM->{doinfo}{gSRstep} } ) ; $i++ ) {
		my %info = ();
		$info{"gSRstep"} = ${ $inCAM->{doinfo}{gSRstep} }[$i];
		$info{"gSRxa"}   = ${ $inCAM->{doinfo}{gSRxa} }[$i];
		$info{"gSRya"}   = ${ $inCAM->{doinfo}{gSRya} }[$i];
		$info{"gSRdx"}   = ${ $inCAM->{doinfo}{gSRdx} }[$i];
		$info{"gSRdy"}   = ${ $inCAM->{doinfo}{gSRdy} }[$i];

		$info{"gSRnx"}     = ${ $inCAM->{doinfo}{gSRnx} }[$i];
		$info{"gSRny"}     = ${ $inCAM->{doinfo}{gSRny} }[$i];
		$info{"gSRangle"}  = ${ $inCAM->{doinfo}{gSRangle} }[$i];
		$info{"gSRmirror"} = ${ $inCAM->{doinfo}{gSRmirror} }[$i];
		$info{"gSRflip"}   = ${ $inCAM->{doinfo}{gSRflip} }[$i];
		$info{"gSRxmin"}   = ${ $inCAM->{doinfo}{gSRxmin} }[$i];
		$info{"gSRymin"}   = ${ $inCAM->{doinfo}{gSRymin} }[$i];
		$info{"gSRxmax"}   = ${ $inCAM->{doinfo}{gSRxmax} }[$i];
		$info{"gSRymax"}   = ${ $inCAM->{doinfo}{gSRymax} }[$i];

		push( @arr, \%info );

	}
	return @arr;
}

# Return information about each step step in specific step
sub GetRepeatStep {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;

	my @arr = ();

	$inCAM->INFO( entity_type => 'step', angle_direction => 'ccw', units => "mm", entity_path => "$jobId/$stepName", data_type => 'REPEAT' );

	for ( my $i = 0 ; $i < scalar( @{ $inCAM->{doinfo}{gREPEATstep} } ) ; $i++ ) {
		my %info = ();
		$info{"stepName"} = ${ $inCAM->{doinfo}{gREPEATstep} }[$i];
		$info{"originX"}  = ${ $inCAM->{doinfo}{gREPEATxa} }[$i];
		$info{"originY"}  = ${ $inCAM->{doinfo}{gREPEATya} }[$i];
		$info{"angle"}    = ${ $inCAM->{doinfo}{gREPEATangle} }[$i];

		#		# mistake in Incam angle_direction => 'ccw' not work, thus:
		#
		#		$info{"angle"} = 360 - $info{"angle"};

		$info{"originXNew"} = ${ $inCAM->{doinfo}{gREPEATxmin} }[$i];
		$info{"originYNew"} = ${ $inCAM->{doinfo}{gREPEATymin} }[$i];

		$info{"gREPEATxmin"} = ${ $inCAM->{doinfo}{gREPEATxmin} }[$i];
		$info{"gREPEATymin"} = ${ $inCAM->{doinfo}{gREPEATymin} }[$i];
		$info{"gREPEATxmax"} = ${ $inCAM->{doinfo}{gREPEATxmax} }[$i];
		$info{"gREPEATymax"} = ${ $inCAM->{doinfo}{gREPEATymax} }[$i];

		push( @arr, \%info );

	}
	return @arr;
}

#Return if any step and repeat exist in given step
sub ExistStepAndRepeats {
	my $self = shift;

	my @arr = $self->GetStepAndRepeat(@_);

	if ( scalar(@arr) ) {
		return 1;
	}
	else {

		return 0;
	}

}

#Return if specific step and repeat exist
sub ExistStepAndRepeat {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;
	my $srName   = shift;

	my @arr = $self->GetStepAndRepeat( $inCAM, $jobId, $stepName );

	if ( scalar( grep { $_->{"gSRstep"} eq $srName } @arr ) ) {
		return 1;
	}
	else {
		return 0;
	}

}

#Delete specific step and repeat from given step
sub DeleteStepAndRepeat {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;
	my $srName   = shift;

	my @arr = $self->GetStepAndRepeat( $inCAM, $jobId, $stepName );

	for ( my $i = 0 ; $i < scalar(@arr) ; $i++ ) {

		if ( $srName eq $arr[$i]->{"gSRstep"} ) {
			$inCAM->COM( 'sr_tab_del', line => ( $i + 1 ) );
		}
	}
}

# add step and repeat
sub AddStepAndRepeat {
	my $self     = shift;
	my $inCAM    = shift;
	my $stepName = shift;
	my $srName   = shift;
	my $posX     = shift;
	my $posY     = shift;

	my $angle = shift;
	my $nx    = shift;
	my $ny    = shift;
	my $dx    = shift;
	my $dy    = shift;

	my $direction = shift;
	my $flip      = shift;
	my $mirror    = shift;

	$nx = 1 if ( !defined $nx );
	$ny = 1 if ( !defined $ny );
	$dx = 0 if ( !defined $dx );
	$dy = 0 if ( !defined $dy );

	$angle = 0 if ( !defined $angle );

	$direction = "ccw" if ( !defined $direction );
	$flip      = "no"  if ( !defined $flip );
	$mirror    = "no"  if ( !defined $mirror );

	CamHelper->SetStep( $inCAM, $stepName );

	$inCAM->COM(
				 "sr_tab_add",
				 "step"      => $srName,
				 "x"         => $posX,
				 "y"         => $posY,
				 "nx"        => $nx,
				 "ny"        => $ny,
				 "dx"        => $dx,
				 "dy"        => $dy,
				 "angle"     => $angle,
				 "direction" => "ccw",
				 "flip"      => "no",
				 "mirror"    => "no"
	);
}

## Change step and repeat table (one specific row)
sub ChangeStepAndRepeat {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $stepName  = shift;
	my $srLineNum = shift;    # line umber in SR table
	my $step      = shift;    # name of parent step
	my $xa        = shift;
	my $ya        = shift;
	my $dx        = shift;
	my $dy        = shift;
	my $nx        = shift;
	my $ny        = shift;
	my $angle     = shift;
	my $direction = shift;
	my $mirror    = shift;
	my $flip      = shift;

	$direction = "ccw" if ( !defined $direction );

	CamHelper->SetStep( $inCAM, $stepName );

	$inCAM->COM(
				 "sr_tab_change",
				 "step"      => $step,
				 "line"      => $srLineNum,
				 "x"         => $xa,
				 "y"         => $ya,
				 "nx"        => $nx,
				 "ny"        => $ny,
				 "dx"        => $dx,
				 "dy"        => $dy,
				 "angle"     => $angle,
				 "direction" => $direction,
				 "flip"      => $flip,
				 "mirror"    => $mirror
	);
}

# Return limits of all step and repeat
sub GetStepAndRepeatLim {
	my $self           = shift;
	my $inCAM          = shift;
	my $jobId          = shift;
	my $stepName       = shift;
	my $considerOrigin = shift;
	my %limits;

	unless ($considerOrigin) {

		$inCAM->INFO(
			units       => 'mm',
			entity_type => 'step',
			entity_path => "$jobId/$stepName",
			data_type   => 'SR_LIMITS'

		);
	}
	else {

		$inCAM->INFO(
					  units       => 'mm',
					  entity_type => 'step',
					  entity_path => "$jobId/$stepName",
					  data_type   => 'SR_LIMITS',
					  "options"   => "consider_origin"
		);
	}

	$limits{"xMin"} = ( $inCAM->{doinfo}{gSR_LIMITSxmin} );
	$limits{"xMax"} = ( $inCAM->{doinfo}{gSR_LIMITSxmax} );
	$limits{"yMin"} = ( $inCAM->{doinfo}{gSR_LIMITSymin} );
	$limits{"yMax"} = ( $inCAM->{doinfo}{gSR_LIMITSymax} );

	return %limits;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'CamHelpers::CamStepRepeat';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f52456";
	my $step  = "o+1";

	my $depth = CamStepRepeat->GetStepAndRepeatDepth( $inCAM, $jobId, $step );

	print STDERR $depth;

	#my $self             = shift;
	#	my $inCAM            = shift;
	#	my $jobName          = shift;
	#	my $stepName         = shift;
	#	my $layerNameTop     = shift;
	#	my $layerNameBot     = shift;
	#
	#	my $considerHole     = shift;
	#	my $considerEdge     = shift;
	#
	#	my $cuThickness = JobHelper->GetBaseCuThick( "f13610", "c" );
	#	my $pcbThick = JobHelper->GetFinalPcbThick("f13610");
	#
	#	my $inCAM = InCAM->new();
	#
	#	my %test = CamHelpers::CamCopperArea->GetCuArea( $cuThickness, $pcbThick, $inCAM, "f13610", "panel", "c", "s", 1, 1 );

	#my %test1 = CamHelpers::CamCopperArea->GetCuArea( $cuThickness, $pcbThick, $inCAM, "F13608", "panel", "c" );

	#my %lim = CamJob->GetLayerLimits( $inCAM, "F13608", "panel", "fr" );

	#my %test1 = CamHelpers::CamCopperArea->GetCuAreaByBox($cuThickness, $pcbThick, $inCAM, "F13608", "panel", "c", "s", \%lim );
	#$inCAM->COM("get_message_bar");
	#print STDERR "TEXT BAR: " . $inCAM->GetReply();

	#my %test2 = CamHelpers::CamCopperArea->GetCuAreaMask($cuThickness, $pcbThick, $inCAM, "F13608", "panel", "c", "s", "mc", "ms" );
	#
	#	print $test2{"area"};
	#	print "\n";
	#	print $test2{"percentage"};
	#
	#	my %test3 = CamHelpers::CopperArea->GetCuAreaMaskByBox( $inCAM, "F13608", "panel", "c", "s", "mc", "ms", \%lim );

	#print $test3{"area"};
	#print "\n";
	#print $test3{"percentage"};
	#my %test3 = CamHelpers::CopperArea->GetCuAreaMask( $inCAM, "F13608", "panel", "c", undef, "mc");

	#	my %test2 = CamHelpers::CopperArea->GetGoldFingerArea($cuThickness, $pcbThick, $inCAM, "F13608", "panel");

	#print $test2{"area"};
	#print "\n";
	#print $test2{"percentage"};

	#print 1;

}

1;
