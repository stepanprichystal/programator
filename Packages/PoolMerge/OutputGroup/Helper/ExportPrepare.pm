
#-------------------------------------------------------------------------------------------#
# Description: Check before export, export pool file, etc..
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::PoolMerge::OutputGroup::Helper::ExportPrepare;
use base("Packages::ItemResult::ItemEventMngr");

#3th party library
use utf8;
use strict;
use warnings;
use DateTime;

#local library
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Managers::AsyncJobMngr::Enums' => "EnumsJobMngr";
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::Unit::Units';
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::GroupBuilder::StandardBuilder';
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::GroupTable::GroupTables';
use aliased 'Programs::Exporter::ExportUtility::DataTransfer::DataTransfer';
use aliased 'Programs::Exporter::ExportUtility::UnitEnums';
use aliased 'Programs::Exporter::ExportUtility::DataTransfer::Enums' => 'EnumsTransfer';
use aliased 'Programs::Exporter::ExportChecker::Enums'               => 'CheckerEnums';
use aliased 'Packages::NifFile::NifFile';
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::Unit::Helper' => "UnitHelper";

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	$self->{"inCAM"}    = shift;
	$self->{"poolInfo"} = shift;

	$self->{"units"} = undef;

	return $self;
}

sub CheckBeforeExport {
	my $self      = shift;
	my $masterJob = shift;

	my $inCAM = $self->{"inCAM"};

	$self->{"units"} = UnitHelper->PrepareUnits($inCAM, $masterJob);

	my @activeOnUnits = grep { $_->GetGroupState() eq CheckerEnums->GroupState_ACTIVEON } @{ $self->{"units"}->{"units"} };

	foreach my $unit (@activeOnUnits) {

		my $resultMngr = -1;
		my $succes = $unit->CheckBeforeExport( $inCAM, \$resultMngr );

		my $title = UnitEnums->GetTitle( $unit->GetUnitId() );

		my $itemRes = $self->_GetNewItem( $title, "Check before export" );

		unless ( $resultMngr->Succes() ) {

			if ( $resultMngr->GetErrorsCnt() ) {

				$itemRes->AddError( $resultMngr->GetErrorsStr(1) );
			}
			if ( $resultMngr->GetWarningsCnt() ) {

				$itemRes->AddWarning( $resultMngr->GetWarningsStr(1) );
			}
		}

		$self->_OnItemResult($itemRes);
	}

}

sub PrepareExportFile {
	my $self       = shift;
	my $masterJob  = shift;
	my $masterOrder  = shift;
	my $exportFile = shift;
	my $mess       = shift;

	my $result = 1;

	my $inCAM = $self->{"inCAM"};

	my $pathExportFile = EnumsPaths->Client_INCAMTMPOTHER . $exportFile;

	my $dataTransfer = DataTransfer->new( $masterJob, EnumsTransfer->Mode_WRITE, $self->{"units"}, undef, $pathExportFile );
	my @orders = ($masterOrder);
	$dataTransfer->SaveData( EnumsJobMngr->TaskMode_ASYNC, 1, undef, undef, \@orders);

	unless ( -e $pathExportFile ) {
		$$mess .= "Error during preparing \"export file\" for master job";
		$result = 0;
	}

	return $result;
}

 


sub __Mask01Exist {
	my $self      = shift;
 
	my $result = 0;

	my @orders = $self->{"poolInfo"}->GetOrdersInfo();
	 

	foreach my $order (@orders) {

		my $nif = NifFile->new( $order->{"jobName"} );

		unless ( $nif->Exist() ) {
			die "nif file doesn't exist " . $order->{"jobName"};
		}

		my $mask = $nif->GetValue("rel(22305,L)");

		if ( $mask =~ /\+/ ) {
			$result = 1;
			last;
		}
	}
	
	return $result;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

		use aliased 'Packages::PoolMerge::OutputGroup::Helper::ExportPrepare';
		use aliased 'Packages::InCAM::InCAM';
	
		my $inCAM = InCAM->new();
	
		my $jobName   = "f52457";
	
	#
		my $mngr = ExportPrepare->new( $inCAM);
		$mngr->CheckBeforeExport($jobName);
}

1;

