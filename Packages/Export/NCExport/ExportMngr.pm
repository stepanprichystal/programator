
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
use aliased 'Packages::Drilling::DrillChecking::LayerCheckError';
use aliased 'Packages::Export::NCExport::OperationMngr';
use aliased 'Packages::Export::NCExport::MergeFileMngr';
use aliased 'Packages::Export::NCExport::ExportFileMngr';
use aliased 'Packages::Export::NCExport::MachineMngr';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Export::NCExport::NCHelper';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamJob';

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

	my $requiredPlt  = shift;
	my $requiredNPlt = shift;

	# Load all NC layers

	my @plt = CamDrilling->GetPltNCLayers( $self->{"inCAM"}, $self->{"jobId"} );
	$self->{"pltLayers"} = \@plt;

	my @nplt = CamDrilling->GetNPltNCLayers( $self->{"inCAM"}, $self->{"jobId"} );
	$self->{"npltLayers"} = \@nplt;

	CamDrilling->AddHistogramValues( $self->{"inCAM"}, $self->{"jobId"}, $self->{"stepName"}, $self->{"pltLayers"} );
	CamDrilling->AddHistogramValues( $self->{"inCAM"}, $self->{"jobId"}, $self->{"stepName"}, $self->{"npltLayers"} );

	# Filter layers, if export single
	if ( $self->{"exportSingle"} ) {

		$self->__FilterLayers( $requiredPlt, $requiredNPlt );

	}

	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $self->{'inCAM'}, $self->{'jobId'} );

	#create manager for choosing right machines
	$self->{"machineMngr"} = MachineMngr->new( $self->{'inCAM'}, $self->{'jobId'}, $self->{"stepName"} );

	#create manager for exporting files
	$self->{"exportFileMngr"} = ExportFileMngr->new( $self->{'inCAM'}, $self->{'jobId'}, $self->{"stepName"}, $self->{"exportSingle"} );
	$self->{"exportFileMngr"}->{"onItemResult"}->Add( sub { $self->_OnItemResult(@_) } );

	#create manager for merging and moving files to archiv
	$self->{"mergeFileMngr"} = MergeFileMngr->new( $self->{'inCAM'}, $self->{'jobId'}, $self->{"stepName"}, $self->{"exportSingle"} );
	$self->{"mergeFileMngr"}->{"fileEditor"} = FileEditor->new( $self->{'jobId'}, $self->{"layerCnt"} );
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

	return $self;
}

sub Run {
	my $self = shift;

	# 1) Do final check of drill/rout layer
	if ( $self->__CheckNCLayers() ) {
 
		# 2) create sequence of dps operation
		$self->{"operationMngr"}->CreateOperations();
 
		# 3) for every operation filter suitable machines
		$self->{"machineMngr"}->AssignMachines( $self->{"operationMngr"} );

		# 4) Export physical nc files
		$self->{"exportFileMngr"}->ExportFiles( $self->{"operationMngr"} );

		# 5) Merge an move files to archive
		$self->{"mergeFileMngr"}->MergeFiles( $self->{"operationMngr"} );

		# 6) Save nc info table to database
		$self->__UpdateNCInfo();
	}

}

#Get information about nc files for  technical procedure
sub GetNCInfo {
	my $self = shift;

	my @infoTable = $self->{"operationMngr"}->GetInfoTable();

	return @infoTable;
}

sub TaskItemsCount {
	my $self = shift;

	my $totalCnt = 0;

	if ( $self->{"exportSingle"} ) {
		$totalCnt++;    # checking nc layer
	}

	$totalCnt += scalar( @{ $self->{"pltLayers"} } );
	$totalCnt += scalar( @{ $self->{"npltLayers"} } );

	$totalCnt++;        # nc merging
	$totalCnt++;        # nc info save

	return $totalCnt;
}

#Get information about nc files for  technical procedure
sub __UpdateNCInfo {
	my $self = shift;

	if ( $self->{"exportSingle"} ) {
		return 0;
	}

	# Save nc info table to database
	my $resultItem = $self->_GetNewItem("Save NC info");

	my @info       = $self->GetNCInfo();
	my $resultMess = "";
	my $result     = NCHelper->UpdateNCInfo( $self->{"jobId"}, \@info, \$resultMess );

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

		unless ( LayerCheckError->CheckNCLayers( $self->{"inCAM"}, $self->{"jobId"}, $self->{"stepName"}, undef, \$mess ) ) {

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

	#use aliased 'Packages::Export::NCExport::NCExportGroup';

	#print $test;

}

1;

