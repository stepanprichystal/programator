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

#Return information about steps in given step
sub GetUniqueNestedStepAndRepeat {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;

	my @uniqueSteps = ();

	my %step = ( "stepName" => $stepName );

	$self->__ExploreStep( $inCAM, $jobId, \%step, \@uniqueSteps );
	
	# remove inspected step, we want only nested
	@uniqueSteps = grep {$_->{"stepName"} ne $stepName} @uniqueSteps;

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

	$inCAM->INFO( entity_type => 'step', entity_path => "$jobId/$stepName", data_type => 'SR' );

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

	use aliased 'CamHelpers::CamStepRepeat';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f13610";
	my $step  = "mpanel_10up";

	my @steps = CamStepRepeat->GetUniqueNestedStepAndRepeat( $inCAM, $jobId, $step );

	print 1;

}

1;

1;
