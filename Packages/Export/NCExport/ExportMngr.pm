
#-------------------------------------------------------------------------------------------#
# Description: Class, cover whole logic for exporting, merging, staging nc layers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NCExport::ExportMngr;
use base('Packages::ItemResult::ItemEventMngr');

use Class::Interface;
&implements('Packages::Export::IMngr');

#3th party library
use strict;
use warnings;
use Log::Log4perl qw(get_logger :levels);

#local library
use aliased 'Packages::Export::NCExport::OperationBuilder::MLOperationBuilder';
use aliased 'Packages::Export::NCExport::OperationBuilder::SLOperationBuilder';
use aliased 'Packages::Export::NCExport::OperationBuilder::SimpleOperationBuilder';
use aliased 'Packages::Export::NCExport::FileHelper::FileEditor';
use aliased 'Packages::CAMJob::Drilling::DrillChecking::LayerErrorInfo';
use aliased 'Packages::Export::NCExport::OperationMngr';
use aliased 'Packages::Export::NCExport::MergeFileMngr';
use aliased 'Packages::Export::NCExport::ExportFileMngr';
use aliased 'Packages::Export::NCExport::MachineMngr';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Export::NCExport::Helpers::NCHelper';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::Export::NCExport::Helpers::NpltDrillHelper';
use aliased 'Packages::CAMJob::Routing::RoutSpeed::RoutSpeed';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	$self->{"inCAM"}        = shift;
	$self->{"jobId"}        = shift;
	$self->{"stepName"}     = shift;
	$self->{"exportSingle"} = shift;

	$self->{"requiredPlt"}  = shift;
	$self->{"requiredNPlt"} = shift;

	return $self;
}

sub Run {
	my $self = shift;

	# move nptp hole from f and fsch to layer "d"
	# "d" is standard NC layer, but so far we work with merged chains and holes in one layer
	my $cnt = undef;
	if ( !$self->{"exportSingle"} ) {
		$cnt = NpltDrillHelper->SeparateNpltDrill( $self->{"inCAM"}, $self->{"jobId"} );
	}

	my $err = undef;
	eval {

		$self->__Init();

		$self->__Run();

	};
	if ($@) {

		$err = $@;
	}

	# move nptp holes back
	if ( !$self->{"exportSingle"} ) {
		NpltDrillHelper->RestoreNpltDrill( $self->{"inCAM"}, $self->{"jobId"}, $cnt );
	}

	die $err if ($err);

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

	# Load all NC layers

	my @plt = CamDrilling->GetPltNCLayers( $self->{"inCAM"}, $self->{"jobId"} );
	$self->{"pltLayers"} = \@plt;

	my @nplt = CamDrilling->GetNPltNCLayers( $self->{"inCAM"}, $self->{"jobId"} );
	$self->{"npltLayers"} = \@nplt;

	CamDrilling->AddHistogramValues( $self->{"inCAM"}, $self->{"jobId"}, $self->{"stepName"}, $self->{"pltLayers"} );
	CamDrilling->AddHistogramValues( $self->{"inCAM"}, $self->{"jobId"}, $self->{"stepName"}, $self->{"npltLayers"} );

	# Filter layers, if export single
	if ( $self->{"exportSingle"} ) {

		$self->__FilterLayers( $self->{"requiredPlt"}, $self->{"requiredNPlt"} );

	}

	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $self->{'inCAM'}, $self->{'jobId'} );

	#create manager for choosing right machines
	$self->{"machineMngr"} = MachineMngr->new( $self->{'inCAM'}, $self->{'jobId'}, $self->{"stepName"} );

	#create manager for exporting files
	$self->{"exportFileMngr"} = ExportFileMngr->new( $self->{'inCAM'}, $self->{'jobId'}, $self->{"stepName"}, $self->{"exportSingle"} );
	$self->{"exportFileMngr"}->{"onItemResult"}->Add( sub { $self->_OnItemResult(@_) } );

	#create manager for merging and moving files to archiv
	$self->{"mergeFileMngr"} = MergeFileMngr->new( $self->{'inCAM'}, $self->{'jobId'}, $self->{"stepName"}, $self->{"exportSingle"} );
	$self->{"mergeFileMngr"}->{"fileEditor"} =
	  FileEditor->new( $self->{'inCAM'}, $self->{'jobId'}, $self->{"stepName"}, $self->{"layerCnt"}, $self->{"exportSingle"} );
	$self->{"mergeFileMngr"}->{"onItemResult"}->Add( sub { $self->_OnItemResult(@_) } );

	#create manager, which decide what will be exported
	$self->{"operationMngr"} = OperationMngr->new();

	# decide which builder use, depend on pcb type and export settings
	if ( $self->{"exportSingle"} ) {

		$self->{"operationMngr"}->{"operationBuilder"} = SimpleOperationBuilder->new();
	}
	else {

		if ( $self->{"layerCnt"} <= 2 ) {

			$self->{"operationMngr"}->{"operationBuilder"} = SLOperationBuilder->new();
		}
		else {

			$self->{"operationMngr"}->{"operationBuilder"} = MLOperationBuilder->new();
		}
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

		# 3) update tif file with information about nc operations (time consuming operation, this is reason why store to tif for later useage)
		NCHelper->StoreOperationInfoTif( $self->{"inCAM"}, $self->{"jobId"}, $self->{"stepName"}, $self->{"operationMngr"} )
		  if ( !$self->{"exportSingle"} );

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

	return 0 if ( $self->{"exportSingle"} );

	my $resultItem = $self->_GetNewItem("Set rout speed");

	# If pcb is in status 'Ve vyrobe', set rout speed
	my $lastOrder = $self->{"jobId"} . "-" . HegMethods->GetPcbOrderNumber( $self->{"jobId"} );
	if ( HegMethods->GetStatusOfOrder( $lastOrder, 0 ) == 4 ) {

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

	if ( $self->{"exportSingle"} ) {
		return 0;
	}

	# Save nc info table to database
	my $resultItem = $self->_GetNewItem("Save NC info");

	my @info       = $self->__GetNCInfo();
	my $resultMess = "";

	# 3 attempt to write to HEG (can do problems during heg bil load)
	my $result = 0;
	foreach my $attempt ( 1 .. 3 ) {

		$result = NCHelper->UpdateNCInfo( $self->{"jobId"}, \@info, \$resultMess );

		last if ($result);
		sleep(5);
	}

	unless ($result) {
		$resultItem->AddError($resultMess);
	}

	print STDERR "Update NC info after\n";

	$self->_OnItemResult($resultItem);
}

sub __FilterLayers {
	my $self         = shift;
	my $requiredPlt  = shift;
	my $requiredNPlt = shift;

	my $plt  = $self->{"pltLayers"};
	my $nplt = $self->{"npltLayers"};

	for ( my $i = scalar( @{$plt} ) - 1 ; $i >= 0 ; $i-- ) {

		my $checkedLayer = ${$plt}[$i]->{"gROWname"};
		my $exist = scalar( grep { $_ eq $checkedLayer } @{$requiredPlt} );

		unless ($exist) {
			splice @{$plt}, $i, 1;    # delete layer
		}
	}

	for ( my $i = scalar( @{$nplt} ) - 1 ; $i >= 0 ; $i-- ) {

		my $checkedLayer = ${$nplt}[$i]->{"gROWname"};
		my $exist = scalar( grep { $_ eq $checkedLayer } @{$requiredNPlt} );

		unless ($exist) {
			splice @{$nplt}, $i, 1;    # delete layer
		}
	}

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

#Get information about nc files for  technical procedure
sub __GetNCInfo {
	my $self = shift;

	my @infoTable = $self->{"operationMngr"}->GetInfoTable();

	return @infoTable;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Export::NCExport::ExportMngr';

	use aliased 'Packages::InCAM::InCAM';

	my $jobId = "d152457";
	my $step  = "panel";
	my $inCAM = InCAM->new();

	# Exportovat jednotlive vrstvy nebo vsechno
	my $exportSingle = 0;

	# Vrstvy k exportovani, nema vliv pokud $exportSingle == 0
	my @pltLayers = ();

	#my @npltLayers = ();

	# Pokud se bude exportovat jednotlive po vrstvach, tak vrstvz dotahnout nejaktakhle:
	#@pltLayers = CamDrilling->GetPltNCLayers( $inCAM, $jobId );
	my @npltLayers = ("f");

	my $export = ExportMngr->new( $inCAM, $jobId, $step, $exportSingle, \@pltLayers, \@npltLayers );
	$export->Run( $inCAM, $jobId, $exportSingle, \@pltLayers, \@npltLayers );

}

1;

