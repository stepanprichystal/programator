#!/usr/bin/perl-w
#################################
#Skript, ktery zkontroluje zakazky ve stavu na priprave, a je-li tam opakovana
#zakazka, pak ji v Genesisu odarchivuje.
#30.5.2014 RVI
#################################
use Genesis;
use Win32::OLE;
use warnings;
use strict;
use sqlNoris;
use untilityScript;

use LoadLibrary;

use GenesisHelper;
use Gatmain;

my $genesis = new Genesis;

my @pcbInProduction = _get_priprava();


foreach my $itemOne (@pcbInProduction) {
	print $itemOne , "\n";
	$itemOne = lc($itemOne);
	$genesis->INFO( entity_type => 'job', entity_path => "$itemOne", data_type => 'exists' );
	if ( $genesis->{doinfo}{gEXISTS} eq "no" ) {

		$genesis->VOF;
		$genesis->COM( "acquire_job", job => "$itemOne", db => "genesis" );

		__RepairScore($itemOne);

		my $stat2 = $genesis->{STATUS};
		$genesis->VON;

		unless ($stat2) {
			if ( getValueNoris( $itemOne, 'pooling' ) eq 'A' ) {
				unless ( GenesisHelper::getInfoCouldTenting( $itemOne, 2 ) == 1 ) {
					unless ( getValueNoris( $itemOne, 'datacode' ) ) {
						my $reference = getValueNoris( $itemOne, 'reference_zakazky' );
						OnlineWrite_order( $reference, "k panelizaci", "aktualni_krok" );
						$genesis->COM( 'close_job',  job => "$itemOne" );
						$genesis->COM( 'close_form', job => "$itemOne" );
						$genesis->COM( 'close_flow', job => "$itemOne" );
					}
				}
				else {
					my $reference = getValueNoris( $itemOne, 'reference_zakazky' );
					OnlineWrite_order( $reference, "SAMOSTATNE-nelze v poolu", "aktualni_krok" );
					$genesis->COM( 'close_job',  job => "$itemOne" );
					$genesis->COM( 'close_form', job => "$itemOne" );
					$genesis->COM( 'close_flow', job => "$itemOne" );
				}
			}
		}
	}
}

sub _get_priprava {
	my $dbConnection = Win32::OLE->new("ADODB.Connection");
	$dbConnection->Open("DSN=dps;uid=genesis;pwd=genesis");

	my $sqlStatement =
	  "select distinct z.reference_subjektu from lcs.zakazky_dps_22_hlavicka z join lcs.desky_22 d on d.cislo_subjektu=z.deska where z.stav='2'";
	my $sqlExecute = $dbConnection->Execute("$sqlStatement");

	my $rec = Win32::OLE->new("ADODB.Recordset");
	$rec->Open( $sqlStatement, $dbConnection );

	until ( $rec->EOF ) {
		my $value = $rec->Fields("reference_subjektu")->value;

		#print "$value\n";
		if ( $value =~ /([DdFf][\d]{5})-([\d][\d])/ ) {
			if ( $2 > 01 ) {
				push( @pcbInProduction, $1 );
			}
		}
		$rec->MoveNext();
	}
	$rec->Close();
	$dbConnection->Close();
	return (@pcbInProduction);
}

#Open job and repair wrong score lines wrong when POOL
sub __RepairScore {

	my $jobName = shift;
	my $step    = "o+1";

	my $pooling = sqlNoris->getValueNoris( $jobName, 'pooling' );
	my $score   = sqlNoris->getValueNoris( $jobName, 'slotting' );
	
	if ( $pooling && $pooling eq 'A' && $score && $score eq 'A' ) {

		#		unless ( GenesisHelper->OpenJobAndStep( $genesis, $jobName, $step ) ) {
		#			return 0;
		#		}

		$genesis->COM(
					   "clipb_open_job",
					   job              => "$jobName",
					   update_clipboard => "view_job"
		);
		$genesis->COM( "open_job", job => "$jobName", "open_win" => "yes" );
		$genesis->COM(
					   "open_entity",
					   job  => "$jobName",
					   type => "step",
					   name => $step
		);

		$genesis->AUX( 'set_group', group => $genesis->{COMANS} );

		#if ( GenesisHelper->StepExists( $jobName, $step ) ) {

		$genesis->COM(
					   'script_run',
					   name    => "z:\\sys\\scripts\\ScoreRepairScript.pl",
					   dirmode => 'global',
					   params  => "$jobName $step"
		);

		#}

		$genesis->COM( "save_job", job => $jobName, "override" => "no" );
		$genesis->COM( "close_job", job => $jobName );

	}
}
