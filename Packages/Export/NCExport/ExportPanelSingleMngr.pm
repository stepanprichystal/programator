
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for export single layers in step panel
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NCExport::ExportPanelSingleMngr;
use base('Packages::ItemResult::ItemEventMngr');

#3th party library
use strict;
use warnings;
use Log::Log4perl qw(get_logger :levels);

#local library
use aliased 'Packages::Export::NCExport::OperationMngr::OperationBuilder::SimpleOperationBuilder';
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
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAM::UniDTM::UniDTM';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class = shift;

	my $self = $class->SUPER::new(@_);
	bless $self;

	$self->{"inCAM"}        = shift;
	$self->{"jobId"}        = shift;
	$self->{"stepName"}     = shift;
	$self->{"PltNCLayers"}  = shift;
	$self->{"NpltNCLayers"} = shift;

	return $self;
}

sub Run {
	my $self = shift;

	$self->__Init();

	$self->__Run();

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
	# 2) Filter layers, if export single

	$self->__FilterLayers( $self->{"PltNCLayers"}, $self->{"NpltNCLayers"} );

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
	  ExportFileMngr->new( $self->{'inCAM'}, $self->{'jobId'}, $self->{"stepName"}, JobHelper->GetJobArchive( $self->{"jobId"} ) . "nc_single\\" );
	$self->{"exportFileMngr"}->{"onItemResult"}->Add( sub { $self->_OnItemResult(@_) } );

	#create manager for merging and moving files to archiv
	$self->{"mergeFileMngr"} =
	  MergeFileMngr->new( $self->{'inCAM'}, $self->{'jobId'}, $self->{"stepName"}, JobHelper->GetJobArchive( $self->{"jobId"} ) . "nc_single\\" );
	$self->{"mergeFileMngr"}->{"fileEditor"} =
	  FileEditor->new( $self->{'inCAM'}, $self->{'jobId'}, $self->{"stepName"}, $self->{"layerCnt"}, 1 );
	$self->{"mergeFileMngr"}->{"onItemResult"}->Add( sub { $self->_OnItemResult(@_) } );

	#create manager, which decide what will be exported
	$self->{"operationMngr"} = OperationMngr->new();
	$self->{"operationMngr"}->{"operationBuilder"} = SimpleOperationBuilder->new();

	$self->{"operationMngr"}->{"operationBuilder"}
	  ->Init( $self->{"inCAM"}, $self->{"jobId"}, $self->{"stepName"}, $self->{"pltLayers"}, $self->{"npltLayers"} );

}

sub __Run {
	my $self = shift;

	get_logger("abstractQueue")->error( "Finding  " . $self->{"jobId"} . " BUG ExportMngr 1\n " );

	# 2) create sequence of dps operation
	$self->{"operationMngr"}->CreateOperations();

	get_logger("abstractQueue")->error( "Finding  " . $self->{"jobId"} . " BUG ExportMngr 2\n " );

	# 3) for every operation filter suitable machines
	$self->{"machineMngr"}->AssignMachines( $self->{"operationMngr"} );

	get_logger("abstractQueue")->error( "Finding  " . $self->{"jobId"} . " BUG ExportMngr 3\n " );

	# 4) Export physical nc files
	$self->{"exportFileMngr"}->ExportFiles( $self->{"operationMngr"} );

	# 5) Merge an move files to archive
	$self->{"mergeFileMngr"}->MergeFiles( $self->{"operationMngr"} );

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

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use aliased 'Packages::Export::NCExport::NCExportGroup';

	#print $test;

}

1;

