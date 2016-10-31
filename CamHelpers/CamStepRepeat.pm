#-------------------------------------------------------------------------------------------#
# Description: Helper class, operation which are working with S&R
# Author:SPR
#-------------------------------------------------------------------------------------------#

package CamHelpers::CamStepRepeat;

#3th party library
use strict;
use warnings;

#loading of locale modules
#use aliased 'Helpers::JobHelper';
#use aliased 'Enums::EnumsPaths';
#use aliased 'Packages::InCAM::InCAM';
#use aliased 'CamHelpers::CamJob';
#use aliased 'CamHelpers::CamHelper';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

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

	$inCAM->INFO( entity_type => 'step', angle_direction => 'ccw', entity_path => "$jobId/$stepName", data_type => 'SR' );

	for ( my $i = 0 ; $i < scalar( @{ $inCAM->{doinfo}{gSRstep} } ) ; $i++ ) {
		my %info = ();
		$info{"gSRstep"} = ${ $inCAM->{doinfo}{gSRstep} }[$i];
		$info{"gSRxa"}   = ${ $inCAM->{doinfo}{gSRxa} }[$i];
		$info{"gSRya"}   = ${ $inCAM->{doinfo}{gSRya} }[$i];
		$info{"gSRdx"}   = ${ $inCAM->{doinfo}{gSRdx} }[$i];
		$info{"gSRdy"}   = ${ $inCAM->{doinfo}{gSRdy} }[$i];

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
		$info{"originY"}  = ${ $inCAM->{doinfo}{gREPEATxa} }[$i];
		$info{"angle"}    = ${ $inCAM->{doinfo}{gREPEATangle} }[$i];

		# mistake in Incam angle_direction => 'ccw' not work, thus:
		
		$info{"angle"} = 360 - $info{"angle"};

		$info{"originXNew"} = ${ $inCAM->{doinfo}{gREPEATxmin} }[$i];
		$info{"originYNew"} = ${ $inCAM->{doinfo}{gREPEATymin} }[$i];

		$info{"gREPEATxmin"} = ${ $inCAM->{doinfo}{gREPEATxmin} }[$i];
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

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'CamHelpers::CamStepRepeat';
	#use aliased 'Packages::InCAM::InCAM';

	#	my $inCAM = InCAM->new();
	#	my $jobId = "f13610";
	#my $step  = "mpanel_10up";

	#my @steps = CamStepRepeat->GetUniqueNestedStepAndRepeat( $inCAM, $jobId, $step );

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
