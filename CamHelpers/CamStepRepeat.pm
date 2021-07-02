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
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::Polygon::Enums' => 'EnumsPolygon';
use aliased 'Packages::Polygon::PointsTransform';

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

# Return information about all nested steps (through all deepness level) steps in given step
# Return array of hashes. Hash contains keys:
# - stepName
# - totalCnt: Total count of steps in specified step
sub GetUniqueNestedStepAndRepeat {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;

	my @uniqueSteps = ();

	my %step = ( "stepName" => $stepName, "totalCnt" => 1 );

	$self->__ExploreStep( $inCAM, $jobId, \%step, \@uniqueSteps );

	# remove inspected step, we want only nested
	@uniqueSteps = grep { $_->{"stepName"} ne $stepName } @uniqueSteps;

	return @uniqueSteps;
}

# Return information about deepest nested steps, which doesn't contain another SR
# Return array of hashes. Hash contains keys:
# - stepName
# - totalCnt: Total count of steps in specified step
sub GetUniqueDeepestSR {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;

	my @uniqueSteps = ();

	my %step = ( "stepName" => $stepName, "totalCnt" => 1 );

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

			$ch->{"totalCnt"} *= $exploreStep->{"totalCnt"};
			$self->__ExploreStep( $inCAM, $jobId, $ch, $uniqueSteps );

		}
	}

	# this step has no childern, test, if is not already in array
	my $uniqueStepInf = ( grep { $_->{"stepName"} eq $exploreStep->{"stepName"} } @{$uniqueSteps} )[0];

	unless ($uniqueStepInf) {
		$uniqueStepInf               = {};
		$uniqueStepInf->{"stepName"} = $exploreStep->{"stepName"};
		$uniqueStepInf->{"totalCnt"} = 0;
		push( @{$uniqueSteps}, $uniqueStepInf );
	}

	$uniqueStepInf->{"totalCnt"} += $exploreStep->{"totalCnt"};

}

# Return information about all nested steps in specified step
# Return array of hashes. Hash contains keys:
# - stepName
# - totalCnt: Total count of steps in specified step
sub GetUniqueStepAndRepeat {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;

	my @steps = ();
	my @arr = $self->GetStepAndRepeat( $inCAM, $jobId, $stepName );

	foreach my $info (@arr) {

		my $stepInf = ( grep { $_->{"stepName"} eq $info->{"gSRstep"} } @steps )[0];

		unless ($stepInf) {
			$stepInf               = ();
			$stepInf->{"stepName"} = $info->{"gSRstep"};
			$stepInf->{"totalCnt"} = 0;
			push( @steps, $stepInf );
		}

		# add count of occurence
		$stepInf->{"totalCnt"} += $info->{"gSRnx"} * $info->{"gSRny"};

	}

	return @steps;
}

#Return information about steps in given step
sub GetStepAndRepeat {
	my $self           = shift;
	my $inCAM          = shift;
	my $jobId          = shift;
	my $stepName       = shift;
	my $considerOrigin = shift // 0;

	my @arr = ();

	unless ($considerOrigin) {

		$inCAM->INFO( "units" => "mm", entity_type => 'step', angle_direction => 'ccw', entity_path => "$jobId/$stepName", data_type => 'SR' );
	}
	else {
		$inCAM->INFO(
					  "units"         => "mm",
					  entity_type     => 'step',
					  angle_direction => 'ccw',
					  entity_path     => "$jobId/$stepName",
					  data_type       => 'SR',
					  "options"       => "consider_origin"
		);
	}

	for ( my $i = 0 ; $i < scalar( @{ $inCAM->{doinfo}{gSRstep} } ) ; $i++ ) {
		my %info = ();
		$info{"stepName"} = ${ $inCAM->{doinfo}{gSRstep} }[$i];
		$info{"gSRstep"}  = ${ $inCAM->{doinfo}{gSRstep} }[$i];
		$info{"gSRxa"}    = ${ $inCAM->{doinfo}{gSRxa} }[$i];
		$info{"gSRya"}    = ${ $inCAM->{doinfo}{gSRya} }[$i];
		$info{"gSRdx"}    = ${ $inCAM->{doinfo}{gSRdx} }[$i];
		$info{"gSRdy"}    = ${ $inCAM->{doinfo}{gSRdy} }[$i];

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

		#	mistake in Incam angle_direction => 'ccw' not work, thus:
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

#Delete specific step and repeat from given step
sub DeleteStepAndRepeat {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;
	my $srName   = shift;

	my @arr = $self->GetStepAndRepeat( $inCAM, $jobId, $stepName );

	for ( my $i = scalar(@arr) - 1 ; $i >= 0 ; $i-- ) {

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

# Remove all coupon steps from list of steps
# each item has to contain key: "stepName"
sub RemoveCouponSteps {
	my $self         = shift;
	my $steps        = shift;
	my $includeCpns  = shift;
	my $includeSteps = shift;

	my $keyStepName = "stepName";

	for ( my $i = scalar( @{$steps} ) - 1 ; $i >= 0 ; $i-- ) {

		die "Key value: \"$keyStepName\" is not defined in step info" if ( !defined $steps->[$i]->{"stepName"} );

		if ( !$includeCpns ) {

			if ( $steps->[$i]->{$keyStepName} =~ /^coupon_?/ ) {

				splice @{$steps}, $i, 1;

			}
		}
		else {
			if ( $steps->[$i]->{$keyStepName} =~ /^coupon_?/ && defined $includeSteps ) {

				# Some coupon steps can contain index number suffix
				if ( !scalar( grep {  $steps->[$i]->{$keyStepName} =~ /^$_/} @{$includeSteps} ) ) {
					splice @{$steps}, $i, 1;
				}

			}
		}

	}
}

# Return information about nested deepest steps in specific step
# Returned values match absolute position and rotation of nested steps in specified step
# Each item contains
# - x: final x position
# - y: final y position
# - angle: final angle
# Function consider origin ( position of steps is relate to zero of step in parameter)
sub GetTransformRepeatStep {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;

	my @stepsInfo = ();

	my $curStep = ();
	$curStep->{"originX"}  = 0;
	$curStep->{"originY"}  = 0;
	$curStep->{"angle"}    = 0;
	$curStep->{"stepName"} = $step;
	my %datum = CamStep->GetDatumPoint( $inCAM, $jobId, $step, 1 );
	$curStep->{"datumX"} = $datum{"x"};
	$curStep->{"datumY"} = $datum{"y"};

	$self->__GetTransformRInfo( $inCAM, $jobId, \@stepsInfo, $curStep, [] );

	return @stepsInfo;
}

sub __GetTransformRInfo {
	my $self          = shift;
	my $inCAM         = shift;
	my $jobId         = shift;
	my $transformRS   = shift;
	my $curStep       = shift;
	my @stepAncestors = @{ shift(@_) };

	my @repeats = $self->GetRepeatStep( $inCAM, $jobId, $curStep->{"stepName"} );

	if (@repeats) {
		foreach my $repeat (@repeats) {
			my @a = ( @stepAncestors, $curStep );

			# Add datum point info
			my %datum = CamStep->GetDatumPoint( $inCAM, $jobId, $repeat->{"stepName"}, 1 );
			$repeat->{"datumX"} = $datum{"x"};
			$repeat->{"datumY"} = $datum{"y"};

			$self->__GetTransformRInfo( $inCAM, $jobId, $transformRS, $repeat, \@a );
		}
	}
	else {

		# Leaf step, compute position and rotation
		my %stepInf = ();
		$stepInf{"stepName"} = $curStep->{"stepName"};
		$stepInf{"x"}        = $curStep->{"originX"};
		$stepInf{"y"}        = $curStep->{"originY"};
		$stepInf{"angle"}    = $curStep->{"angle"};

		@stepAncestors = reverse(@stepAncestors);

		# do not consider last ancestor, because it is  not placed inside another ancestor
		for ( my $i = 0 ; $i < scalar(@stepAncestors) ; $i++ ) {

			my $ancestor = $stepAncestors[$i];

			next if ( $ancestor->{"stepName"} eq "" );

			# point of ancestor rotation (ancestor datum point)
			my $rotatePoint = {};
			$rotatePoint->{"x"} = ( $ancestor->{"originX"} ) * 1000;
			$rotatePoint->{"y"} = ( $ancestor->{"originY"} ) * 1000;

			# rorated point (cur step anchor)
			my $anchorPoint = {};
 
 			# do not consider anchor if ancestor doesn't have ancestor (last ancestor)
 			my $datumX = 0;
 			my $datumY = 0;
 			if($i < scalar(@stepAncestors) -1){
 				$datumX = $ancestor->{"datumX"};
 				$datumY = $ancestor->{"datumY"};
 			}
 
			$anchorPoint->{"x"} = $rotatePoint->{"x"} + ( $stepInf{"x"} - $datumX ) * 1000;
			$anchorPoint->{"y"} = $rotatePoint->{"y"} + ( $stepInf{"y"} - $datumY ) * 1000;

			my %newAnchorPoint = PointsTransform->RotatePoint( $anchorPoint, $ancestor->{"angle"}, EnumsPolygon->Dir_CCW, $rotatePoint );
			$stepInf{"x"} = $newAnchorPoint{"x"} / 1000;
			$stepInf{"y"} = $newAnchorPoint{"y"} / 1000;

			$stepInf{"angle"} += $ancestor->{"angle"};
			$stepInf{"angle"} -= 360 if ( $stepInf{"angle"} > 360 );
		}

		push( @{$transformRS}, \%stepInf );
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'CamHelpers::CamStepRepeat';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d113608";
	my $step  = "mpanel";

	my @sr = CamStepRepeat->GetTransformRepeatStep( $inCAM, $jobId, $step );

	die;

}

1;
