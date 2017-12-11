#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::ChangeReorder::Changes::INCAM_JOB;
use base('Packages::Reorder::ChangeReorder::Changes::ChangeBase');

use Class::Interface;
&implements('Packages::Reorder::ChangeReorder::Changes::IChange');

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamStep';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamMatrix';

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

	my $isPool = HegMethods->GetPcbIsPool($jobId);

	# Check only standard orders

	my $result = 1;

	# 1) check if layer "c" is not missing. (layer has to exist even at noncopper pcb)
	unless ( CamHelper->LayerExists( $inCAM, $jobId, "c" ) ) {

		CamMatrix->CreateLayer( $inCAM, $jobId, "c", "signal", "positive", 1 );
		$inCAM->COM("matrix_auto_rows","job" => $jobId,"matrix" => "matrix");
	}
	
	# 2) check if layer "f" is not missing. (layer has to exist even at noncopper pcb)
	unless ( CamHelper->LayerExists( $inCAM, $jobId, "f" ) ) {

		CamMatrix->CreateLayer( $inCAM, $jobId, "f", "rout", "positive", 1 );
		$inCAM->COM("matrix_auto_rows","job" => $jobId,"matrix" => "matrix");
	}
 
	return $result;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Reorder::ChangeReorder::Changes::SCHEMA' => "Change";
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f52457";

	my $check = Change->new( "key", $inCAM, $jobId );

	my $mess = "";
	print "Change result: " . $check->Run( \$mess );
}

1;

