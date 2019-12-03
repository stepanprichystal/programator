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
use aliased 'CamHelpers::CamChecklist';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Routing::PlatedRoutArea';
use aliased 'Packages::Export::NifExport::NifMngr';
use aliased 'Packages::NifFile::NifFile';
use aliased 'Packages::CAMJob::Dim::JobDim';
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
use aliased 'Programs::Exporter::ExportUtility::DataTransfer::UnitsDataContracts::NifData';
use aliased 'Packages::Reorder::Enums';
use aliased 'Packages::TifFile::TifPoolMother';
use aliased 'Helpers::JobHelper';

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

	my $inCAM       = $self->{"inCAM"};
	my $jobId       = $self->{"jobId"};
	my $reorderType = $self->{"reorderType"};

	my $result = 1;

	# First order but reorder with ancestor
	return $result if ( $reorderType ne Enums->ReorderType_POOLFORMERMOTHER );

	# 1) Find former construction class first in First in DIF file, then in las run ERF model

	my $lCnt = CamJob->GetSignalLayerCnt( $inCAM, $jobId );

	my $outerClass = undef;
	my $innerClass = undef;

	# Load from TIF
	my $tif = TifPoolMother->new($jobId);
	if ( $tif->TifFileExist() ) {

		$outerClass = $tif->GetFormerOuterClass();
		$innerClass = $tif->GetFormerInnerClass() if ( $lCnt > 2 );
	}

	# Load from last ERF model

	my $chcklstCheckName = "checks";

	if ( !defined $outerClass && CamChecklist->ChecklistExists( $inCAM, $jobId, "o+1", $chcklstCheckName ) ) {

		# action number outer layer = 1 for 1v + 2v;
		# action number outer layer = 3 for multilayer;
		my $aOuterNum = $lCnt <= 2 ? 1 : 3;

		my $ERF = CamChecklist->GetChecklistActionERF( $inCAM, $jobId, "o+1", $chcklstCheckName, $aOuterNum );
		my $ERFNum = ( $ERF =~ /_(\d+)_/ )[0];

		if ( defined $ERFNum && $ERFNum > 0 ) {
			$outerClass = $ERFNum;
		}
	}

	if ( $lCnt > 2 && !defined $innerClass && CamChecklist->ChecklistExists( $inCAM, $jobId, "o+1", $chcklstCheckName ) ) {

		# action number 3 for inner layers
		my $ERFIn = CamChecklist->GetChecklistActionERF( $inCAM, $jobId, "o+1", $chcklstCheckName, 2 );
		my $ERFInNum = ( $ERFIn =~ /_(\d+)_/ )[0];

		if ( defined $ERFInNum && $ERFInNum > 0 ) {
			$innerClass = $ERFInNum;
		}
	}

	CamAttributes->SetJobAttribute( $inCAM, $jobId, "pcb_class", ( defined $outerClass ? $outerClass : 0 ) );

	CamAttributes->SetJobAttribute( $inCAM, $jobId, "pcb_class_inner", ( defined $innerClass ? $innerClass : 0 ) );

	# 2) Set default Cu 18 if current Cu is lowered on 9
	my $cuThick = JobHelper->GetBaseCuThick($jobId);
	if ( $cuThick == 9 ) {
		HegMethods->UpdateBaseCu( $jobId, 18 );
	}

	# 3) Remove all steps except input and o+1
	my @steps = CamStep->GetAllStepNames( $inCAM, $jobId );
	my @alowed = ( CamStep->GetReferenceStep( $inCAM, $jobId, "o+1" ), "o+1", "o+1_single", "o+1_panel" );

	my %tmp;
	@tmp{@alowed} = ();
	my @steps2Del = grep { !exists $tmp{$_} } @steps;

	foreach my $step (@steps2Del) {
		CamStep->DeleteStep( $inCAM, $jobId, $step );
	}

	# 4) Delete empty layers according o+1 step
	foreach my $layer ( CamJob->GetAllLayers( $inCAM, $jobId ) ) {

		my %fHist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, "o+1", $layer->{"gROWname"} );

		if ( $fHist{"total"} == 0 ) {

			CamMatrix->DeleteLayer( $inCAM, $jobId, $layer->{"gROWname"} );
		}
	}

	# 5) Clip signal layer (old job id behind profile)

	CamHelper->SetStep( $inCAM, "o+1" );

	foreach my $l ( ( "c", "s" ) ) {

		my $f = FeatureFilter->new( $inCAM, $jobId, $l );
		$f->SetProfile(2);
		$f->SetPolarity("positive");
		$f->SetFeatureTypes( "text" => 1 );
		if ( $f->Select() ) {
			CamLayer->DeleteFeatures( $inCAM, $jobId );
		}
	}

	# 6) Set proper info to noris (there can be attributes from former mother)
	my %silk   = ( "top" => undef, "bot" => undef );
	my %solder = ( "top" => undef, "bot" => undef );

	$silk{"top"} = CamHelper->LayerExists( $inCAM, $jobId, "pc" ) ? "B" : "";
	$silk{"bot"} = CamHelper->LayerExists( $inCAM, $jobId, "ps" ) ? "B" : "";

	$solder{"top"} = CamHelper->LayerExists( $inCAM, $jobId, "mc" ) ? "Z" : "";
	$solder{"bot"} = CamHelper->LayerExists( $inCAM, $jobId, "ms" ) ? "Z" : "";

	HegMethods->UpdateSilkScreen( $jobId, "top", $silk{"top"} );
	HegMethods->UpdateSilkScreen( $jobId, "bot", $silk{"bot"} );
	HegMethods->UpdateSolderMask( $jobId, "top", $solder{"top"} );
	HegMethods->UpdateSolderMask( $jobId, "bot", $solder{"bot"} );

	# 7) Create nif file
	# Prepare NIF  data

	my $taskData = NifData->new();

	#silk

	$taskData->SetC_silk_screen_colour( $silk{"top"} );
	$taskData->SetS_silk_screen_colour( $silk{"bot"} );

	#mask

	$taskData->SetC_mask_colour( $solder{"top"} );
	$taskData->SetS_mask_colour( $solder{"bot"} );

	my %dim = JobDim->GetDimension( $inCAM, $jobId );

	$taskData->SetSingle_x( $dim{"single_x"} );
	$taskData->SetSingle_y( $dim{"single_y"} );
	$taskData->SetPanel_x( $dim{"panel_x"} );
	$taskData->SetPanel_y( $dim{"panel_y"} );
	$taskData->SetNasobnost_panelu( $dim{"nasobnost_panelu"} );

	my $name = CamAttributes->GetJobAttrByName( $inCAM, $jobId, "user_name" );
	$taskData->SetZpracoval($name);

	$taskData->SetDatacode( HegMethods->GetDatacodeLayer($jobId) );
	$taskData->SetUlLogo( HegMethods->GetUlLogoLayer($jobId) );

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
	my $jobId = "d211583";

	my $check = Change->new( "key", $inCAM, $jobId );

	my $mess = "";
	print "Change result: " . $check->Run( \$mess );
}

1;

