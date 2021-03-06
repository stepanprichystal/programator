#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::CheckReorder::Checks::NC;
use base('Packages::Reorder::CheckReorder::Checks::CheckBase');

use Class::Interface;
&implements('Packages::Reorder::CheckReorder::Checks::ICheck');

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamDrilling';
use aliased 'Packages::CAMJob::Marking::MarkingDataCode';
use aliased 'Packages::CAMJob::Drilling::DrillChecking::LayerErrorInfo';
use aliased 'Packages::Reorder::Enums';
#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless($self);

	return $self;
}

# check if datacode is in helios
sub Run {
	my $self     = shift;
	
	my $inCAM    = $self->{"inCAM"};
	my $jobId    = $self->{"jobId"};
	my $reorderType = $self->{"reorderType"};
 
	
	my $step  = undef;

	if ( CamHelper->StepExists( $inCAM, $jobId, "panel" ) ) {
		$step = "panel";
	}
	else {
		$step = "o+1";
	}
 
	 
	# 1) check of NC layers, if layers, depths, matrix drill direction is ok 
	my $mess = "";
	unless ( LayerErrorInfo->CheckNCLayers( $inCAM, $jobId, $step, undef, \$mess ) ) {
		
		$self->_AddChange($mess, 1);
	}
	
	
	# 2) Check if job viafill layer  are prepared if viafill in IS
	my $viaFillType = HegMethods->GetBasePcbInfo($jobId)->{"zaplneni_otvoru"};
 
	# A - viafill in gatema
	# B - viafill in cooperation - all holes
	# C - viafill in cooperation - specified holes
	if ( defined $viaFillType && $viaFillType =~ /[abc]/i ) {

		unless ( CamDrilling->GetViaFillExists( $inCAM, $jobId ) ) {

			$self->_AddChange( "V IS je po??adavek na zapln??n?? otvor??, v jobu ale nejsou p??ipraven?? NC vrstvy (mfill; scfill; ssfill)", 1);

		}
	}
	 
}
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Reorder::CheckReorder::Checks::DATACODE_IS' => "Change";
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f52456";

	my $check = Change->new();

	print "Need change: " . $check->NeedChange( $inCAM, $jobId, 1 );

}

1;

