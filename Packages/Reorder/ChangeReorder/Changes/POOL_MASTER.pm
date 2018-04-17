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
use aliased 'CamHelpers::CamHistogram';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamAttributes';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Routing::PlatedRoutArea';
use aliased 'Packages::Export::NifExport::NifMngr';
use aliased 'Packages::NifFile::NifFile';
use aliased 'Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorder::AcquireJob';
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
use aliased 'Programs::Exporter::ExportUtility::Groups::NifExport::NifExportTmpPool';
use aliased 'Programs::Exporter::ExportUtility::DataTransfer::UnitsDataContracts::NifData';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless($self);

	$self->{"nifCreation"}    = 1;
	$self->{"nifCreationErr"} = "";

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

	# First order but reorder with ancestor
	return $result if ( HegMethods->GetPcbOrderNumber($jobId) != 1 );

	# 1) Remove all steps except input and o+1
	my @allowed = ( CamStep->GetReferenceStep( $inCAM, $jobId, "o+1" ), "o+1", "o+1_single", "o+1_panel" );

	foreach my $step ( CamStep->GetAllStepNames( $inCAM, $jobId ) ) {

		unless ( grep { $_ eq $step } @allowed ) {

			CamStep->DeleteStep( $inCAM, $jobId, $step );
		}

	}

	# 2) Delete empty layers according o+1 step
	foreach my $layer ( CamJob->GetAllLayers( $inCAM, $jobId ) ) {

		my %fHist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, "o+1", $layer->{"gROWname"} );

		if ( $fHist{"total"} == 0 ) {

			CamMatrix->DeleteLayer( $inCAM, $jobId, $layer->{"gROWname"} );
		}
	}

	# 3) Clip signal layer (old job id behind profile)

	CamHelper->SetStep( $inCAM, "o+1" );

	foreach my $l ( ( "c", "s" ) ) {

		my $f = FeatureFilter->new( $inCAM, $jobId, $l );
		$f->SetProfile(2);
		$f->SetPolarity("positive");
		$f->SetFilterType( "text" => 1 );
		if ( $f->Select() ) {
			CamLayer->DeleteFeatures( $inCAM, $jobId );
		}
	}

	# 4) Set proper info to noris (there can be attributes from former mother)
	my %silk   = ( "top" => undef, "bot" => undef );
	my %solder = ( "top" => undef, "bot" => undef );

	$silk{"top"} =   CamHelper->LayerExists( $inCAM, $jobId, "pc" )  ? "B" : "";
	$silk{"bot"} =  CamHelper->LayerExists( $inCAM, $jobId, "ps" ) ? "B" : "";

	$solder{"top"} =  CamHelper->LayerExists( $inCAM, $jobId, "mc" ) ? "Z" : "";
	$solder{"bot"} =  CamHelper->LayerExists( $inCAM, $jobId, "ms" ) ? "Z" : "";

	HegMethods->UpdateSilkScreen( $jobId, "top", $silk{"top"}, 1 );
	HegMethods->UpdateSilkScreen( $jobId, "bot", $silk{"bot"}, 1 );
	HegMethods->UpdateSolderMask( $jobId, "top", $solder{"top"}, 1 );
	HegMethods->UpdateSolderMask( $jobId, "bot", $solder{"bot"}, 1 );
	
	# 5) Create nif file
	# Prepare NIF  data

	my $taskData = NifData->new();

	#silk
	 
	$taskData->SetC_silk_screen_colour( $silk{"top"} );
	$taskData->SetS_silk_screen_colour( $silk{"bot"} );

	#mask
 
	$taskData->SetC_mask_colour( $solder{"top"} );
	$taskData->SetS_mask_colour( $solder{"bot"} );

	my %dim = ();
	$dim{"single_x"} = "";
	$dim{"single_y"} = "";

	#get information about dimension, Ssteps: 0+1, mpanel

	my %profilO1 = CamJob->GetProfileLimits( $inCAM, $jobId, "o+1" );

	$dim{"single_x"} = abs( $profilO1{"xmax"} - $profilO1{"xmin"} );
	$dim{"single_y"} = abs( $profilO1{"ymax"} - $profilO1{"ymin"} );

	#format numbers
	$dim{"single_x"} = sprintf( "%.1f", $dim{"single_x"} ) if ( $dim{"single_x"} );
	$dim{"single_y"} = sprintf( "%.1f", $dim{"single_y"} ) if ( $dim{"single_y"} );

	$taskData->SetSingle_x( $dim{"single_x"} );
	$taskData->SetSingle_y( $dim{"single_y"} );

	my $name = CamAttributes->GetJobAttrByName( $inCAM, $jobId, "user_name" );
	$taskData->SetZpracoval($name);
	
	$taskData->SetDatacode(HegMethods->GetDatacodeLayer($jobId));
	$taskData->SetUlLogo(HegMethods->GetUlLogoLayer($jobId));

	# 6) Create nif file

	my $nifMngr = NifMngr->new( $inCAM, $jobId, $taskData->{"data"} );
	$nifMngr->{"onItemResult"}->Add( sub { $self->__NifResults(@_) } );

	$nifMngr->Run();

	unless ( $self->{"nifCreation"} ) {

		$result = 0;
		$$mess .= $self->{"nifCreationErr"};
	}

	return $result;
}

sub __NifResults {
	my $self       = shift;
	my $itemResult = shift;

	if ( $itemResult->Result() eq "failure" ) {
		$self->{"nifCreation"} = 0;
	}

	$self->{"nifCreationErr"} .= "Task: " . $itemResult->ItemId() . "\n";
	$self->{"nifCreationErr"} .= "Task result: " . $itemResult->Result() . "\n";
	$self->{"nifCreationErr"} .= "Task errors: \n" . $itemResult->GetErrorStr() . "\n";
	$self->{"nifCreationErr"} .= "Task warnings: \n" . $itemResult->GetWarningStr() . "\n";

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Reorder::ChangeReorder::Changes::POOL_MASTER' => "Change";
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d152456";

	my $check = Change->new( "key", $inCAM, $jobId );

	my $mess = "";
	print "Change result: " . $check->Run( \$mess );
}

1;

