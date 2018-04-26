#!/usr/bin/perl-w
#################################
#Skript, ktery zkontroluje zakazky ve stavu na priprave, a je-li tam opakovana
#zakazka, pak ji v Genesisu odarchivuje.
#30.5.2014 RVI
#################################
use Genesis;
use Win32::OLE;
#use warnings;
#use strict;
use sqlNoris;
use untilityScript;

use LoadLibrary;

use GenesisHelper;
use Gatmain;

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use aliased 'Packages::Routing::PlatedRoutArea';

my $inCAM = new Genesis;

my @pcbInProduction = _get_priprava();

foreach my $itemOne (@pcbInProduction) {
	#print $itemOne , "\n";
	$itemOne = lc($itemOne);
	$inCAM->INFO( entity_type => 'job', entity_path => "$itemOne", data_type => 'exists' );
	$radim = $inCAM->{doinfo}{gEXISTS};
	if ( $inCAM->{doinfo}{gEXISTS} eq "no" ) {
		
		$inCAM->VOF;
		my $archiveDir = getPath("$itemOne");
		
		if (-e "$archiveDir/$itemOne.tgz") {
					 $inCAM->COM('import_job',db=>'incam',path=>"$archiveDir/$itemOne.tgz",name=>"$itemOne",analyze_surfaces=>'no');
		}

		

		my $stat2 = $inCAM->{STATUS};
		$inCAM->VON;

		unless ($stat2) {
			if ( getValueNoris( $itemOne, 'pooling' ) eq 'A' ) {
				unless ( PlatedRoutArea->PlatedAreaExceed($inCAM, $itemOne, 'o+1') == 1 ) {
					unless ( getValueNoris( $itemOne, 'datacode' ) ) {
						my $reference = getValueNoris( $itemOne, 'reference_zakazky' );
						OnlineWrite_order( $reference, "k panelizaci", "aktualni_krok" );
						_ChangePolarityMask($itemOne);
					}
				}
				else {
					my $reference = getValueNoris( $itemOne, 'reference_zakazky' );
					OnlineWrite_order( $reference, "SAMOSTATNE-nelze v poolu", "aktualni_krok" );
					
				}
			}
		}
	

		$inCAM -> COM ('check_inout',ent_type=>'job',job=>"$itemOne",mode=>'test');
		my @stav = split /\s/, $inCAM->{COMANS};
			if ($stav[0] eq 'yes') {
					$inCAM -> COM('check_inout',job=>"$itemOne",mode=>'in',ent_type=>'job');
	
					$inCAM->COM( 'close_job',  job => "$itemOne" );
					$inCAM->COM( 'close_form', job => "$itemOne" );
					$inCAM->COM( 'close_flow', job => "$itemOne" );
			}
	}
}


sub _ChangePolarityMask {
			my $pcbId = shift;
			my $StepName = 'o+1';
			
			$inCAM -> COM ('open_job',job=>"$pcbId",open_win=>'yes');
			#$inCAM -> COM ('open_entity',job=>"$pcbId",type=>'step',name=>"$StepName",iconic=>'no');
			
			#	  $inCAM ->	COM ('set_step',name=>"$StepName");
				
				  $inCAM->INFO(entity_type=>'layer',entity_path=>"$pcbId/$StepName/mc",data_type=>'exists');
  			  			if ($inCAM->{doinfo}{gEXISTS} eq "yes") {
  			  					$inCAM -> COM ('matrix_layer_polar',job=>"$pcbId",matrix=>'matrix',layer=>'mc',polarity=>'positive');
  			  					$inCAM -> COM ('save_job',job=>"$pcbId",override=>'no',skip_upgrade=>'no');
  			  			}
  			  	$inCAM->INFO(entity_type=>'layer',entity_path=>"$pcbId/$StepName/ms",data_type=>'exists');
  			  			if ($inCAM->{doinfo}{gEXISTS} eq "yes") {
  			  					$inCAM -> COM ('matrix_layer_polar',job=>"$pcbId",matrix=>'matrix',layer=>'ms',polarity=>'positive');
  			  					$inCAM -> COM ('save_job',job=>"$pcbId",override=>'no',skip_upgrade=>'no');
  			  			}
	
}


sub _get_priprava {
	my $dbConnection = Win32::OLE->new("ADODB.Connection");
	$dbConnection->Open("DSN=dps;uid=genesis;pwd=genesis");

	my $sqlStatement =
	 # "select distinct z.reference_subjektu from lcs.zakazky_dps_22_hlavicka z join lcs.desky_22 d on d.cislo_subjektu=z.deska where z.stav='2'";
	 "select distinct z.reference_subjektu from lcs.zakazky_dps_22_hlavicka z where z.stav='2'";

	my $sqlExecute = $dbConnection->Execute("$sqlStatement");

	my $rec = Win32::OLE->new("ADODB.Recordset");
	$rec->Open( $sqlStatement, $dbConnection );

	until ( $rec->EOF ) {
		my $value = $rec->Fields("reference_subjektu")->value;

		#print "$value\n";
		if ( $value =~ /([DdFf][\d]{5,})-([\d][\d])/ ) {
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
