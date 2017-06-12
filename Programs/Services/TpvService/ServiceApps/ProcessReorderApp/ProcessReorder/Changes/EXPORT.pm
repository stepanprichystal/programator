#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::TpvService::ServiceApps::ProcessReorderApp::ProcessReorder::Changes::EXPORT;
use base('Programs::Services::TpvService::ServiceApps::ProcessReorderApp::ProcessReorder::Changes::ChangeBase');

use Class::Interface;
&implements('Programs::Services::TpvService::ServiceApps::ProcessReorderApp::ProcessReorder::Changes::IChange');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Managers::AsyncJobMngr::Enums' => "EnumsJobMngr";
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::Unit::Units';
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::GroupBuilder::StandardBuilder';
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::GroupTable::GroupTables';
use aliased 'Programs::Exporter::ExportUtility::DataTransfer::DataTransfer';
use aliased 'Programs::Exporter::ExportUtility::UnitEnums';
use aliased 'Programs::Exporter::ExportUtility::DataTransfer::Enums' => 'EnumsTransfer';
use aliased 'Programs::Exporter::ExportChecker::Enums'               => 'CheckerEnums';
use aliased 'Packages::NifFile::NifFile';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless($self);

	return $self;
}

# Do export, only non pool pcb
sub Run {
	my $self = shift;
	my $mess = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	$self->__CheckBeforeExport();

	my $result = 1;
}

sub __CheckBeforeExport {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	$self->__PrepareUnits($jobId);

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

sub __PrepareUnits {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# Units

	my $groubT = GroupTables->new();    # virtual table, where are stored reference of alll units

	my $groupBuilder = StandardBuilder->new();    # group builder, fill table by requested units
	$groupBuilder->Build( $jobId, $groubT );
	my @allUnits = $groubT->GetAllUnits();

	$self->{"units"} = Units->new();              # class which keep list of all defined units (composit pattern)
	$self->{"units"}->Init( $inCAM, $jobId, \@allUnits );
	$self->{"units"}->InitDataMngr($inCAM);

	# Read old nif file and in order to transfer info to nif file

	my $nif = NifFile->new($jobId);

	my $nifUnit      = $self->{"units"}->GetUnitById( UnitEnums->UnitId_NIF );
	my $nifGroupData = $nifUnit->{"dataMngr"}->GetGroupData();

	# Mask 0,1

	my $mask = $nif->GetValue("rel(22305,L)");
	if ( $mask =~ /\+/ ) {
		$nifGroupData->SetMaska01(1);
	}

	# Datacodes
	my $datacode = $nif->GetValue("datacode");
	$datacode =~ s/\s//g if ( defined $datacode );    # remove spaces

	if ( defined $datacode && $datacode ne "" ) {

		$datacode = uc($datacode);
		$nifGroupData->SetDatacode($datacode);
	}
	
	# UL logo
	my $ul = $nif->GetValue("ul_logo");
	$ul =~ s/\s//g if ( defined $ul );    # remove spaces

	if ( defined $ul && $ul ne "" ) {

		$ul = uc($ul);
		$nifGroupData->SetUlLogo($ul);
	}
	
}

sub PrepareExportFile {
	my $self        = shift;
	my $masterJob   = shift;
	my $masterOrder = shift;
	my $exportFile  = shift;
	my $mess        = shift;

	my $result = 1;

	my $inCAM = $self->{"inCAM"};

	my $pathExportFile = EnumsPaths->Client_INCAMTMPOTHER . $exportFile;

	my $dataTransfer = DataTransfer->new( $masterJob, EnumsTransfer->Mode_WRITE, $self->{"units"}, undef, $pathExportFile );
	my @orders = ($masterOrder);
	$dataTransfer->SaveData( EnumsJobMngr->TaskMode_ASYNC, 1, undef, undef, \@orders );

	unless ( -e $pathExportFile ) {
		$$mess .= "Error during preparing \"export file\" for master job";
		$result = 0;
	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::Services::TpvService::ServiceApps::ProcessReorderApp::ProcessReorder::Changes::EXPORT' => "Change";
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f52457";

	my $check = Change->new( "key", $inCAM, $jobId );

	my $mess = "";
	print "Change result: " . $check->Run( \$mess );
}

1;

