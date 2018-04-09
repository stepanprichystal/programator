#-------------------------------------------------------------------------------------------#
# Description:  If pool is master, delete step and empty lazers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::ChangeReorder::Changes::POOL_MASTER;
use base('Packages::Reorder::ChangeReorder::Changes::ChangeBase');

use Class::Interface;
&implements('Packages::Reorder::ChangeReorder::Changes::IChange');

#3th party library
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamHelper';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Routing::PlatedRoutArea';
use aliased 'Packages::Export::NifExport::NifMngr';
use aliased 'Packages::NifFile::NifFile';
use aliased 'Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorder::AcquireJob';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless($self);

	return $self;
}

# Check if mask is not negative in matrix
sub Run {
	my $self = shift;
	my $mess = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $isPool = HegMethods->GetPcbIsPool($jobId);

	my $result = 1;

	# 1) Chceck If pcb has ancestor.
	# if ancestor is former mother pcb, delete child steps and empty layers
	my $ancestor = "d203719"

	  if ( $ancestor && $isPool ) {

		# First order but reorder with ancestor
		if ( HegMethods->GetPcbOrderNumber($jobId) == 1 ) {

			# 1) Remove all steps except input and o+1
			my @allowed = ( CamStep->GetReferenceStep( $inCAM, $ancestor, "o+1" ), "o+1", "o+1_single", "o+1_panel" );
			
			foreach my $step  (CamStep->GetAllStepNames($inCAM, $jobId)){
			
				unless( grep { $_ eq $step } @allowed){
					
					CamStep->DeleteStep($inCAM, $jobId, $step);
				}
			
			} 
			
			# 2) Delete empty layers according o+1 step
			foreach my $layer  (CamJob->GetAllLayers($inCAM, $jobId)){
			
			
				my %fHist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, "o+1", $layer->{"gROWname"} );
			}
			

		}
	}

}

return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

  use aliased 'Packages::Reorder::ChangeReorder::Changes::LAYER_NAMES' => "Change";
  use aliased 'Packages::InCAM::InCAM';

  my $inCAM = InCAM->new();
  my $jobId = "f00873";

  my $check = Change->new( "key", $inCAM, $jobId );

  my $mess = "";
  print "Change result: " . $check->Run( \$mess );
}

1;

