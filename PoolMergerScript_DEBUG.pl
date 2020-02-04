#!/usr/bin/perl -w

use strict;
use warnings;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Programs::PoolMerge::PoolMerge::PoolMerge';
use aliased 'Managers::AsyncJobMngr::Enums' => 'EnumsMngr';
use aliased 'Packages::InCAM::InCAM';

#use aliased 'Programs::Exporter::ExportChecker::Server::Client';
use aliased 'Programs::PoolMerge::UnitEnums';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorder::AcquireJob';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::InCAM::InCAM';

my $inCAM = InCAM->new();

# Debug variable
$main::DEBUG = 1;

# ----------------------------------------------
# Debug options
# ----------------------------------------------

#NonStandartUnits();
#CreateFakePoolFile(1);
#CreateFakePoolFile(0);
#NotCreateServer();
NoChecks();
# ----------------------------------------------
 
if($inCAM->IsConnected()){
	$inCAM->ClientFinish();
}



my $poolMerger = PoolMerge->new( EnumsMngr->RUNMODE_TRAY );
$poolMerger->Run();

sub NonStandartUnits {

	@main::mandatory = ();

	push(@main::mandatory, UnitEnums->UnitId_CHECK);
	push( @main::mandatory, UnitEnums->UnitId_MERGE );
	push( @main::mandatory, UnitEnums->UnitId_ROUT );
	push( @main::mandatory, UnitEnums->UnitId_OUTPUT );

}

# PoolMerger conenct to server on port 56753
sub NotCreateServer{
	
	$main::debugPortServer = 56753;	
}

# disable some checks in pool merger
sub NoChecks{
	
	
	$main::disableChecks = 1;
	
}

# mother f13608-01 (f88466) 44 66
# child	 f13609-01 (f57100) 140 83.6
sub CreateFakePoolFile {
	my $createJobs = shift;
	
	my $motherOri   = "d188466";
	my $mother      = "d113608";
	my $motherOrder = "d113608-01";

	my $childOri   = "d157100";
	my $child      = "d113609";
	my $childOrder = "d113609-01";

	HegMethods->UpdatePooling( "d113608-01", 1 );
	HegMethods->UpdatePooling( "d113609-01", 1 );
	
#	HegMethods->UpdatePcbOrderState($motherOrder, "k panelizaci");
#	HegMethods->UpdatePcbOrderState($childOrder, "k panelizaci");

	

	if ($createJobs) {

		CopyJobs( $motherOri, $mother );
		CopyJobs( $childOri,  $child );
	}

	my $str = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>
		<orders panel_height=\"326.0\" panel_width=\"266.0\">
  		  <order h=\"66.0\" order_id=\"$motherOrder\" rotated=\"0\" w=\"44.0\" x=\"10.0\" y=\"10\"/>
  		  <order h=\"83.6\" order_id=\"$childOrder\" rotated=\"0\" w=\"140.0\" x=\"100\" y=\"200\"/>
  		  <order h=\"83.6\" order_id=\"$childOrder\" rotated=\"0\" w=\"140.0\" x=\"100\" y=\"100\"/>
	</orders>";

	my $f;
	if ( open( $f, "+>", 'c:\Export\ExportFiles\Pool\pan1_2-18-1000-TEST_20-24-37.xml' ) ) {

		print $f $str;
		close($f);
	}

}

sub CopyJobs {
	my $source = shift;
	my $dest   = shift;

	unless ( CamJob->JobExist( $inCAM, $source ) ) {

		AcquireJob->Acquire( $inCAM, $source );
	}

	CamJob->DeleteJob( $inCAM, $dest );

	CamHelper->OpenJob( $inCAM, $source );
	$inCAM->COM(
				 "copy_entity",
				 "type"           => "job",
				 "source_job"     => $source,
				 "source_name"    => $source,
				 "dest_job"       => $dest,
				 "dest_name"      => $dest,
				 "dest_database"  => "incam",
				 "remove_from_sr" => "yes"
	);

	$inCAM->COM( "close_job", "job" => "$source" );

}

