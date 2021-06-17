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

# Check if mask is not negative in matrix
sub Run {
	my $self = shift;
	my $errMess = shift;
	my $infMess = shift;

	my $inCAM       = $self->{"inCAM"};
	my $jobId       = $self->{"jobId"};
	my $reorderType = $self->{"reorderType"};

	my $result = 1;

	# 1) Chceck If pcb is pool and was in produce as standard before

	# pcb is pool and was in produce as standard last order
	if ( $reorderType eq Enums->ReorderType_POOLFORMERSTD ) {

		# Check if pcb can be merged with another pool currently
		if ( $self->__PoolCriteriaOk() ) {

			my @steps = CamStep->GetAllStepNames( $inCAM, $jobId );
			my @alowed = ( CamStep->GetReferenceStep( $inCAM, $jobId, "o+1" ), "o+1", "o+1_single", "o+1_panel" );

			my %tmp;
			@tmp{@alowed} = ();
			my @steps2Del = grep { !exists $tmp{$_} } @steps;

			foreach my $step (@steps2Del) {
				CamStep->DeleteStep( $inCAM, $jobId, $step );
			}

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

		$exportNifData{"datacode"} = HegMethods->GetDatacodeLayer($jobId);
		$exportNifData{"ul_logo"}  = HegMethods->GetUlLogoLayer($jobId);

		my $formerNif = NifFile->new($jobId);
		$exportNifData{"maska01"}   = $formerNif->GetPayment("2814075");
		$exportNifData{"wrongData"} = $formerNif->GetPayment("4007227");

		my $nifMngr = NifMngr->new( $inCAM, $jobId, \%exportNifData );

		$nifMngr->Run();

		# Sometimes dimensions are switeched (new reorder dimensions are loaded to IS, but switched)
		my $dimIS = HegMethods->GetInfoDimensions($jobId);

		# Switch dimension of single pieces
		if ( abs( $dimIS->{"kus_x"} - $dim{"single_y"} ) < 1 && abs( $dimIS->{"kus_y"} - $dim{"single_x"} ) < 1 ) {

			HegMethods->UpdatePCBDim( $jobId, "kus_x", $dim{"single_x"} );
			HegMethods->UpdatePCBDim( $jobId, "kus_y", $dim{"single_y"} );

		}

		# Switch dimension of single pieces
		if ( defined $dim{"nasobnost_panelu"} && $dim{"nasobnost_panelu"} ne "" ) {
			
			if ( abs( $dimIS->{"panel_x"} - $dim{"panel_y"} ) < 1 && abs( $dimIS->{"panel_y"} - $dim{"panel_x"} ) < 1 ) {

				HegMethods->UpdatePCBDim( $jobId, "panel_x", $dim{"panel_x"} );
				HegMethods->UpdatePCBDim( $jobId, "panel_y", $dim{"panel_y"} );
			}
		}

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

	my $errMess = "";
	print "Change result: " . $check->Run( \$errMess );
}

1;

