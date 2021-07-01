
#-------------------------------------------------------------------------------------------#
# Description: manager responsible for export all NC layer for step panel
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NCExport::ExportPanelAllMngr;
use base('Packages::ItemResult::ItemEventMngr');

#3th party library
use strict;
use warnings;
use Log::Log4perl qw(get_logger :levels);

#local library
use aliased 'Packages::Export::NCExport::OperationMngr::OperationBuilder::MLOperationBuilder';
use aliased 'Packages::Export::NCExport::OperationMngr::OperationBuilder::SLOperationBuilder';
use aliased 'Packages::Export::NCExport::MergeFileMngr::FileHelper::FileEditor';
use aliased 'Packages::CAMJob::Drilling::DrillChecking::LayerErrorInfo';
use aliased 'Packages::Export::NCExport::OperationMngr::OperationMngr';
use aliased 'Packages::Export::NCExport::MergeFileMngr::MergeFileMngr';
use aliased 'Packages::Export::NCExport::ExportFileMngr::ExportFileMngr';
use aliased 'Packages::Export::NCExport::MachineMngr::MachineMngr';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Export::NCExport::Helpers::Helper';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamJob';
use aliased 'Helpers::JobHelper';
use aliased 'Packages::Export::NCExport::Helpers::NpltDrillHelper';
use aliased 'Packages::CAMJob::Routing::RoutSpeed::RoutSpeed';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAM::UniDTM::UniDTM';
use aliased 'Packages::CAMJob::Microsection::CouponZaxisMill';

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
	$self->{"NCLayers"} = shift;    # information about layer stretch value

	return $self;
}

sub Run {
	my $self = shift;

	# move nptp hole from f and fsch to layer "d"
	# "d" is standard NC layer, but so far we work with merged chains and holes in one layer
	my $cnt = undef;

	$cnt = NpltDrillHelper->SeparateNpltDrill( $self->{"inCAM"}, $self->{"jobId"}, $self->{"NCLayers"} );

	$self->__Init();

	$self->__Run();

	# move nptp holes back

	NpltDrillHelper->RestoreNpltDrill( $self->{"inCAM"}, $self->{"jobId"}, $cnt );

}

# Return info about NC operations
sub GetOperationMngr {
	my $self = shift;

	$self->__Init();

	$self->{"operationMngr"}->CreateOperations();

	return $self->{"operationMngr"};
}

sub TaskItemsCount {
	my $self = shift;

	my $totalCnt = 0;

	$totalCnt += scalar( CamDrilling->GetPltNCLayers( $self->{"inCAM"}, $self->{"jobId"} ) );
	$totalCnt += scalar( CamDrilling->GetNPltNCLayers( $self->{"inCAM"}, $self->{"jobId"} ) );

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
	  FileEditor->new( $self->{'inCAM'}, $self->{'jobId'}, $self->{"stepName"}, $self->{"layerCnt"}, 0 );
	$self->{"mergeFileMngr"}->{"onItemResult"}->Add( sub { $self->_OnItemResult(@_) } );

	#create manager, which decide what will be exported
	$self->{"operationMngr"} = OperationMngr->new();

	# decide which builder use, depend on pcb type and export settings

	if ( $self->{"layerCnt"} <= 2 ) {

		$self->{"operationMngr"}->{"operationBuilder"} = SLOperationBuilder->new();
	}
	else {

		$self->{"operationMngr"}->{"operationBuilder"} = MLOperationBuilder->new();
	}

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

		# 3) update tif file
		# Add information about nc operations (time consuming operation, this is reason why store to tif for later useage)
		Helper->StoreOperationInfoTif( $self->{"inCAM"}, $self->{"jobId"}, $self->{"stepName"}, $self->{"operationMngr"} );

		# Add output settings info for nc layers
		Helper->StoreNClayerSettTif( $self->{"inCAM"}, $self->{"jobId"}, $self->{"NCLayers"}, $self->{"operationMngr"} );
 
		# 4) Export physical nc files
		$self->{"exportFileMngr"}->ExportFiles( $self->{"operationMngr"} );

		# 5) Merge an move files to archive
		$self->{"mergeFileMngr"}->MergeFiles( $self->{"operationMngr"} );

		# 6) Set rout feed speed to NC files
		$self->__SetRoutFeedSpeed();

		# 6) Save nc info table to database
		$self->__UpdateNCInfo();
	}

}

sub __SetRoutFeedSpeed {
	my $self = shift;

	my $resultItem = $self->_GetNewItem("Set rout speed");

	# If pcb is in status 'Ve vyrobe', 'Pozastavena', set rout speed
	my $lastOrder = $self->{"jobId"} . "-" . HegMethods->GetPcbOrderNumber( $self->{"jobId"} );
	my $pcbStatus = HegMethods->GetStatusOfOrder( $lastOrder, 0 );
	if ( $pcbStatus == 4 || $pcbStatus == 12 || JobHelper->GetIsFlex( $self->{"jobId"} ) ) {

		my $info = HegMethods->GetInfoAfterStartProduce($lastOrder);

		die "pocet_prirezu is no defined in HEG for orderid: $lastOrder"
		  if ( !defined $info->{'pocet_prirezu'} || !defined $info->{'prirezu_navic'} );

		my $totalPnlCnt = $info->{'pocet_prirezu'} + $info->{'prirezu_navic'};

		my $errMess = "";
		unless ( RoutSpeed->CompleteRoutSpeed( $self->{"jobId"}, $totalPnlCnt, \$errMess ) ) {

			$resultItem->AddError($errMess);
		}
	}

	$self->_OnItemResult($resultItem);
}

#Get information about nc files for  technical procedure
sub __UpdateNCInfo {
	my $self = shift;

	# Save nc info table to database
	my $resultItem = $self->_GetNewItem("Save NC info");

	#Get information about nc files for  technical procedure

	my @operationsTable = $self->{"operationMngr"}->GetInfoTable();
	my $c = CouponZaxisMill->new( $self->{"inCAM"}, $self->{"jobId"} );

	my $resultMess = "";
	my $ncInfoStr = Helper->BuildNCInfo( $self->{"jobId"}, \@operationsTable, $c, \$resultMess );

	# 3 attempt to write to HEG (can do problems during heg bil load)
	my $result = 0;
	foreach my $attempt ( 1 .. 3 ) {

		$result = Helper->UpdateNCInfo( $self->{"jobId"}, $ncInfoStr, \$resultMess );

		last if ($result);
		sleep(5);
	}

	unless ($result) {
		$resultItem->AddError($resultMess);
	}

	print STDERR "Update NC info after\n";

	$self->_OnItemResult($resultItem);
}

# Do final check of drill/rout layer
sub __CheckNCLayers {
	my $self = shift;

	my $res = 1;

	if ( !$self->{"exportSingle"} ) {

		my $checkRes = $self->_GetNewItem("Checking NC layers");

		my $mess = "";    # errors

		unless ( LayerErrorInfo->CheckNCLayers( $self->{"inCAM"}, $self->{"jobId"}, $self->{"stepName"}, undef, \$mess ) ) {

			$checkRes->AddError($mess);
			$res = 0;     # don't continue, because of check fail
		}

		$self->_OnItemResult($checkRes);
	}

	return $res;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Export::NCExport::ExportPanelAllMngr';

	use aliased 'Packages::InCAM::InCAM';

	my $jobId = "d322106";

	my $step  = "panel";
	my $inCAM = InCAM->new();

	my $export = ExportPanelAllMngr->new( $inCAM, $jobId, $step );
	my @opItems = ();

	my $t = $export->Run();

	die;
}

1;

