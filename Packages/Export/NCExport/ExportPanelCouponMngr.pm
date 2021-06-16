
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for export coupon layers from panel_coupon step
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NCExport::ExportPanelCouponMngr;
use base('Packages::ItemResult::ItemEventMngr');

#3th party library
use strict;
use warnings;
use Log::Log4perl qw(get_logger :levels);

#local library
use aliased 'Packages::Export::NCExport::OperationMngr::OperationBuilder::CPNOperationBuilder';
use aliased 'Packages::Export::NCExport::MergeFileMngr::FileHelper::FileEditor';
use aliased 'Packages::CAMJob::Drilling::DrillChecking::LayerErrorInfo';
use aliased 'Packages::Export::NCExport::OperationMngr::OperationMngr';
use aliased 'Packages::Export::NCExport::MergeFileMngr::MergeFileMngr';
use aliased 'Packages::Export::NCExport::ExportFileMngr::ExportFileMngr';
use aliased 'Packages::Export::NCExport::MachineMngr::MachineMngr';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Export::NCExport::Helpers::Helper';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamHistogram';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamMatrix';
use aliased 'Helpers::JobHelper';
use aliased 'Packages::Export::NCExport::Helpers::NpltDrillHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAM::UniDTM::UniDTM';
use aliased 'CamHelpers::CamStep';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class = shift;

	my $self = $class->SUPER::new(@_);
	bless $self;

	$self->{"inCAM"}    = shift;
	$self->{"jobId"}    = shift;
	$self->{"stepName"} = shift;

	return $self;
}

sub Run {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# Check if exist panel coupon
	die "Panel coupon step (" . $self->{"stepName"} . ") is not created" unless ( CamHelper->StepExists( $inCAM, $jobId, $self->{"stepName"} ) );

	# Check if therea are prepared Zaxis coupons
	my $cpnName = EnumsGeneral->Coupon_ZAXIS;
	my @zAxisCpn =
	  grep { $_->{"stepName"} =~ /^$cpnName\d+$/i } CamStepRepeat->GetUniqueDeepestSR( $self->{"inCAM"}, $self->{"jobId"}, $self->{"stepName"} );

	die "No z-axis coupon in panel step: " . $self->{"stepName"} unless ( scalar(@zAxisCpn) );

	# We want do coupon outline mill/drill from both sides.
	# So if there is some mill from BOT, duplicate outline mill
	my $outlLayer = $self->__DuplicateOutlineFromBot();

	$self->__Init();

	$self->__Run();

	$self->__RemoveOutlineFromBot($outlLayer);

}

sub TaskItemsCount {
	my $self = shift;

	my $totalCnt = 0;

	# TODO doplnit pocet vrstev ktere nesjou prazdne

	$totalCnt++;    # nc merging
	$totalCnt++;    # rout speed feed
	$totalCnt++;    # nc info save

	return $totalCnt;
}

sub __Init {
	my $self = shift;

	# 1) Load all NC layers
	my @plt = CamDrilling->GetPltNCLayers( $self->{"inCAM"}, $self->{"jobId"} );
	$self->{"pltLayers"} = \@plt;

	my @nplt = CamDrilling->GetNPltNCLayers( $self->{"inCAM"}, $self->{"jobId"} );
	$self->{"npltLayers"} = \@nplt;

	# 3) Add layer attributes
	CamDrilling->AddHistogramValues( $self->{"inCAM"}, $self->{"jobId"}, $self->{"stepName"}, $self->{"pltLayers"} );
	CamDrilling->AddHistogramValues( $self->{"inCAM"}, $self->{"jobId"}, $self->{"stepName"}, $self->{"npltLayers"} );

	foreach my $l ( @{ $self->{"pltLayers"} } ) {
		$l->{"UniDTM"} = UniDTM->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"stepName"}, $l->{"gROWname"}, 1 );
	}

	foreach my $l ( @{ $self->{"npltLayers"} } ) {
		$l->{"UniDTM"} = UniDTM->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"stepName"}, $l->{"gROWname"}, 1 );
	}

	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $self->{'inCAM'}, $self->{'jobId'} );

	#create manager for choosing right machines
	$self->{"machineMngr"} = MachineMngr->new( $self->{'inCAM'}, $self->{'jobId'}, $self->{"stepName"} );

	#create manager for exporting files
	$self->{"exportFileMngr"} =
	  ExportFileMngr->new( $self->{'inCAM'}, $self->{'jobId'}, $self->{"stepName"}, JobHelper->GetJobArchive( $self->{"jobId"} ) . "nc\\" );
	$self->{"exportFileMngr"}->{"onItemResult"}->Add( sub { $self->_OnItemResult(@_) } );

	#create manager for merging and moving files to archiv
	$self->{"mergeFileMngr"} =
	  MergeFileMngr->new( $self->{'inCAM'}, $self->{'jobId'}, $self->{"stepName"}, JobHelper->GetJobArchive( $self->{"jobId"} ) . "nc\\" );
	$self->{"mergeFileMngr"}->{"fileEditor"} =
	  FileEditor->new( $self->{'inCAM'}, $self->{'jobId'}, $self->{"stepName"}, $self->{"layerCnt"}, 1 );
	$self->{"mergeFileMngr"}->{"onItemResult"}->Add( sub { $self->_OnItemResult(@_) } );

	#create manager, which decide what will be exported
	$self->{"operationMngr"} = OperationMngr->new();
	$self->{"operationMngr"}->{"operationBuilder"} = CPNOperationBuilder->new();

	$self->{"operationMngr"}->{"operationBuilder"}
	  ->Init( $self->{"inCAM"}, $self->{"jobId"}, $self->{"stepName"}, $self->{"pltLayers"}, $self->{"npltLayers"} );

}

sub __Run {
	my $self = shift;

	# 1) Do final check of drill/rout layer
	if ( $self->__CheckNCLayers() ) {

		get_logger("abstractQueue")->error( "Finding  " . $self->{"jobId"} . " BUG ExportMngr 1\n " );

		# 2) create sequence of dps operation
		$self->{"operationMngr"}->CreateOperations();

		get_logger("abstractQueue")->error( "Finding  " . $self->{"jobId"} . " BUG ExportMngr 2\n " );

		# 3) for every operation filter suitable machines
		$self->{"machineMngr"}->AssignMachines( $self->{"operationMngr"} );

		get_logger("abstractQueue")->error( "Finding  " . $self->{"jobId"} . " BUG ExportMngr 3\n " );

		# 5) Export physical nc files
		$self->{"exportFileMngr"}->ExportFiles( $self->{"operationMngr"}, 0 );

		# 6) Merge an move files to archive
		$self->{"mergeFileMngr"}->MergeFiles( $self->{"operationMngr"} );
	}

}

# Do final check of drill/rout layer
sub __CheckNCLayers {
	my $self = shift;

	my $res = 1;

	my $checkRes = $self->_GetNewItem("Checking NC layers - coupon");

	my $mess = "";    # errors

	unless ( LayerErrorInfo->CheckNCLayers( $self->{"inCAM"}, $self->{"jobId"}, $self->{"stepName"}, undef, \$mess ) ) {

		$checkRes->AddError($mess);
		$res = 0;     # don't continue, because of check fail
	}

	$self->_OnItemResult($checkRes);

	return $res;
}

# If exist depth milling from BOT, duplicate outline layer and set direction from bot
sub __DuplicateOutlineFromBot {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $outlineL = undef;
	my @l = ( CamJob->GetLayerByType( $inCAM, $jobId, "rout" ) );

	CamDrilling->AddLayerStartStop( $inCAM, $jobId, \@l );

	for ( my $i = scalar(@l) - 1 ; $i >= 0 ; $i-- ) {

		my %hist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $self->{"stepName"}, $l[$i]->{"gROWname"}, 1 );
		splice @l, $i, 1 if( $hist{"total"} == 0 );
	}
 

	if ( scalar( grep { $_->{"gROWdrl_dir"} eq "bot2top" } @l ) ) {

		$outlineL = "fs";

		die "Layer $outlineL already exist, something is broken" if ( CamHelper->LayerExists( $inCAM, $jobId, $outlineL ) );

		CamMatrix->DuplicateLayer( $inCAM, $jobId, "f", $outlineL );

		CamMatrix->SetLayerDirection( $inCAM, $jobId, $outlineL, "bottom_to_top" );
	}

	return $outlineL;
}

sub __RemoveOutlineFromBot {
	my $self    = shift;
	my $outline = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	CamMatrix->DeleteLayer( $inCAM, $jobId, $outline );
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use aliased 'Packages::Export::NCExport::NCExportGroup';

	#print $test;

}

1;

