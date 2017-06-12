#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::TpvService::ServiceApps::ProcessReorderApp::ProcessReorder::Changes::SCHEMA;
use base('Programs::Services::TpvService::ServiceApps::ProcessReorderApp::ProcessReorder::Changes::ChangeBase');

use Class::Interface;
&implements('Programs::Services::TpvService::ServiceApps::ProcessReorderApp::ProcessReorder::Changes::IChange');

#3th party library
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStepRepeat';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless($self);

	return $self;
}

# Delete and add new schema
sub Run {
	my $self = shift;
	my $mess = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $result = 1;

	my $layerCnt = CamJob->GetSignalLayerCnt( $inCAM, $jobId );

	 
	my $schema = undef;

	if ( $layerCnt <= 2 ) {

		$schema = "1a2v";
	}
	else {

		my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, "panel" );

		if ( abs( $lim{"yMax"} - $lim{"yMin"} ) == 407 ) {
			$schema = '4v-407';
		}
		else {
			$schema = '4v-485';
		}
	}

	my @steps = CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobId, "panel" );

	$inCAM->COM("autopan_delete","job" => $jobId,"panel" => "panel","mode" => "objects_all_layers");

	$inCAM->COM( 'autopan_run_scheme', "job" => $jobId, "panel" => "panel", "pcb" => $steps[0]->{"stepName"}, "scheme" => $schema );
	
	return $result;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::Services::TpvService::ServiceApps::ProcessReorderApp::ProcessReorder::Changes::SCHEMA' => "Change";
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f52457";

	my $check = Change->new( "key", $inCAM, $jobId );

	my $mess = "";
	print "Change result: " . $check->Run( \$mess );
}

1;

