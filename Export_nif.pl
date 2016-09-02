#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

#necessary for load pall packagesff
#use FindBin;
#use lib "$FindBin::Bin/../";
#use PackagesLib;

use aliased 'Packages::InCAM::InCAM';

#use aliased 'Programs::Exporter::ExportUtility::Groups::NifExport::NifExportTmp';
use aliased 'Programs::Exporter::ExportUtility::Groups::NifExport::NifExport';
use aliased 'Programs::Exporter::UnitEnums';
use aliased 'Programs::Exporter::DataTransfer::Enums' => 'EnumsTransfer';
use aliased 'Programs::Exporter::DataTransfer::DataTransfer';
#input parameters
my $jobId = "f13610";

my $resultMess = "";

my $inCAM  = InCAM->new();
my $export = NifExport->new( UnitEnums->UnitId_NIF );

my $dataTransfer = DataTransfer->new( $jobId, EnumsTransfer->Mode_READ );
my $exportData = $dataTransfer->GetExportData();

$export->Init( $inCAM, $jobId, $exportData );

$export->{"onItemResult"}->Add( sub { _OnItemResultHandler(@_) } );

$export->Run();

print $resultMess;




sub _OnItemResultHandler {
	my $itemResult = shift;

	$resultMess .= " \n=============== Export task result: ==============\n";
	$resultMess .= "Task: " . $itemResult->ItemId() . "\n";
	$resultMess .= "Task result: " . $itemResult->Result() . "\n";
	$resultMess .= "Task errors: \n" . $itemResult->GetErrorStr() . "\n";
	$resultMess .= "Task warnings: \n" . $itemResult->GetWarningStr() . "\n";

}

