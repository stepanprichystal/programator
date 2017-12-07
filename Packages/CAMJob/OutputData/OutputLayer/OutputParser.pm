
#-------------------------------------------------------------------------------------------#
# Description: Prepare NC layers to finla output
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::OutputData::OutputLayer::OutputParser;

#3th party library
use strict;
use warnings;
use List::Util qw[max min];
use Math::Trig;

#local library

use aliased 'Packages::CAMJob::OutputData::OutputLayer::Enums';
use aliased 'Packages::CAMJob::OutputData::OutputLayer::OutputResult::OutputClassResult';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
	$self->{"step"}  = shift;

	$self->{"classes"} = [];

	#$self->{"classResult"} = OutputClassResult->new();

	return $self;
}

sub Parse {
	my $self = shift;

	my @results = ();

	foreach my $class ( @{ $self->{"classes"} } ) {

		my $classResult = $class->Prepare();

		push( @results, $classResult );

	}

	return @results;
}

sub AddClass {
	my $self  = shift;
	my $class = shift;

	push( @{ $self->{"classes"} }, $class );

}

#-------------------------------------------------------------------------------------------#
#  Protected methods
#-------------------------------------------------------------------------------------------#

# Remove all layers used in result
sub _FinalCheck {
	my $self   = shift;
	my $result = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	my %hist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $step, $result->GetOriLayer() );
	if ( $hist{"total"} > 0 ) {

		return 0;
	}
	else {

		return 1;
	}
}

# Remove all layers used in result
sub _Clear {
	my $self   = shift;
	my $result = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	foreach my $lName ( $result->GetLayers() ) {

		CamMatrix->DeleteLayer( $inCAM, $jobId, $lName );
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
