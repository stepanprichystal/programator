#-------------------------------------------------------------------------------------------#
# Description:  Do operation with pool pcb
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::ChangeReorder::Changes::POOL;
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
use aliased 'CamHelpers::CamAttributes';
use aliased 'Packages::CAMJob::Dim::JobDim';

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

	# 1) Chceck If pcb is pool and was in produce as standard before
	my $pnlExist = CamHelper->StepExists( $inCAM, $jobId, "panel" );

	# pcb is pool and was in produce as standard last order
	if ( $isPool && $pnlExist ) {

		# Check if pcb can be merged with another pool currently
		if ( $self->__PoolCriteriaOk() ) {

			# 1) delete panel (and et_panel if exist)
			CamStep->DeleteStep( $inCAM, $jobId, "panel" );
			CamStep->DeleteStep( $inCAM, $jobId, "et_panel" );

		}
		else {

			# Change POOL -> Standard in IS in last order
			my $lastOrder = HegMethods->GetPcbOrderNumber($jobId);
			my $res = HegMethods->UpdatePooling( $jobId . "-" . $lastOrder, 0 );
		}

	}

	# if pcb was not change to standard and is not new id (01), export nif
	if ( HegMethods->GetPcbIsPool($jobId) ) {

		# fill necessary attributes for create pool nif
		my %exportNifData = ();

		# values taken from job (nasobnost_panelu and dimensions could be changed)
		$exportNifData{"zpracoval"} = CamAttributes->GetJobAttrByName( $inCAM, $jobId, "user_name" );
		
		my %dim = JobDim->GetDimension( $inCAM, $jobId );
		$exportNifData{"single_x"}         = $dim{"single_x"};
		$exportNifData{"single_y"}         = $dim{"single_y"};
		$exportNifData{"panel_x"}          = $dim{"panel_x"};
		$exportNifData{"panel_y"}          = $dim{"panel_y"};
		$exportNifData{"nasobnost_panelu"} = $dim{"nasobnost_panelu"};

		my %silk   = ( "top" => undef, "bot" => undef );
		my %solder = ( "top" => undef, "bot" => undef );
		$exportNifData{"c_mask_colour"}        = CamHelper->LayerExists( $inCAM, $jobId, "mc" ) ? "Z" : "";
		$exportNifData{"s_mask_colour"}        = CamHelper->LayerExists( $inCAM, $jobId, "ms" ) ? "Z" : "";
		$exportNifData{"c_silk_screen_colour"} = CamHelper->LayerExists( $inCAM, $jobId, "pc" ) ? "B" : "";
		$exportNifData{"s_silk_screen_colour"} = CamHelper->LayerExists( $inCAM, $jobId, "ps" ) ? "B" : "";
	 
		$exportNifData{"datacode"}  = HegMethods->GetDatacodeLayer($jobId);
		$exportNifData{"ul_logo"}   = HegMethods->GetUlLogoLayer($jobId);
		
		my $formerNif = NifFile->new($jobId);
		$exportNifData{"maska01"}   = $formerNif->GetPayment("2814075");
		$exportNifData{"wrongData"} = $formerNif->GetPayment("4007227");

		my $nifMngr = NifMngr->new( $inCAM, $jobId, \%exportNifData );

		$nifMngr->Run();
	}

	return $result;
}

# Check if job meets with pool criteria
sub __PoolCriteriaOk {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $criteriaOk = 1;

	if ( PlatedRoutArea->PlatedAreaExceed( $inCAM, $jobId, "o+1" ) ) {

		$criteriaOk = 0;
	}

	return $criteriaOk;
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

