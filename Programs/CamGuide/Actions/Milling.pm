
package Programs::CamGuide::Actions::Milling;


use utf8;
use strict;
use warnings;
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamHelper';
use aliased 'Programs::CamGuide::Enums';
use aliased 'Connectors::HeliosConnector::HegMethods';

our %n;
our %d;


#kazda akce musi obsahovat vystizny nazev a strucny popis. A to presne v tomhle poradi:

$n{"ActionCreateOStep"} = "Vytvorit step O";
$d{"ActionCreateOStep"} = "Vytvoreni prazdneho stepu O";

sub ActionCreateOStep {

	#Veskere potrebne komponenty a informace nam vzdy poskytne samotny Guide, ktery je predan jako prvni parametr

	my $guide    = shift;
	my $inCam    = $guide->GetCAM();		#napojena InCAM knihovna na editor, uz nevytvarime znovu
	my $messMngr = $guide->GetMessMngr();	#spravce chybovych/informacnich oken, take uz nevztvarime ynovu
	my %pcbInfo  = $guide->GetPcbInfo();	#hash obsahujici veskere potrebne info o dps nejen z norrisu
	my $stepO  	 = $guide->GetStepO();		#vrati "aktualni nazev stepu O", podle toho na keterm stepu je Guide spusten
	my $stepO1   = $guide->GetStepO1();		#vrati "aktualni nazev stepu O+1", podle toho na keterm stepu je Guide spusten
	
	#priklad dotazeni jmena dps z %pcbInfo
	my $jobName  = $pcbInfo{"pcbId"};
	
	#tady se bude zapisovat kod akce
	#kod bude co nejstrucnejsi a bude volat prislusne pomocne balicky ze slozkz Packages, popr CamHelper
	
	CamHelper->OpenJob($inCam, $jobName);
	#CamHelper->CreateStep($stepO);
	
}
	
	
	
	
	#HegMethods->UpdateConstructionClass("F13610", 8);
	#HegMethods->GetReorderPoolPcb();
	
	#my $test = 1/0;
	#$inCam->COM_test();
	 
	#my @mess1 = ( Enums->TXT_PRIPRAVAR, "vytvoř ji." );
	#$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess1 );
#
#	$inCam->COM( "clipb_open_job", job => "$jobName", update_clipboard => "view_job" );
#
	#$inCam->COM( "open_job", job => "$jobName", "open_win" => "yes" );
#
	#$inCam->COM( "open_entity", job => "$jobName", type => "step", name => $stepName );
#
	#$inCam->AUX( 'set_group', group => $inCam->{COMANS} );

	#$inCam create_entity,job=testGuide1,name=o+1,db=,is_fw=no,type=step,fw_type=form

	#$guide->SetCanContinue(1);
	#$guide->SetPauseMess("Pausa z metody 1");

#}

$n{"ActionCreateO_1Step"} = "Vytvorit step O+1";
$d{"ActionCreateO_1Step"} = "Vytvoreni stepu O+1, zkopirovanim stepu O";

sub ActionCreateO_1Step {

	my $guide    = shift;
	my $inCam    = $guide->GetCAM();
	my $messMngr = $guide->GetMessMngr();
	my %pcbInfo  = $guide->GetPcbInfo();

	#$inCam->COM( "create_entity", "job" => "testGuide1", "name" => "o+1", "type" => "step", "fw_type" => "form" );

	#$guide->SetCanContinue(1);
	#$guide->SetPauseMess("Pausa z metody 1");

}

$n{"ActionCreatePanelStep"} = "Vytvorit step panel";
$d{"ActionCreatePanelStep"} = "Vytvoreni prazdneho stepu panel";

sub ActionCreatePanelStep {

	my $guide    = shift;
	my $inCam    = $guide->GetCAM();
	my $messMngr = $guide->GetMessMngr();
	my %pcbInfo  = $guide->GetPcbInfo();

	#$inCam->COM( "create_entity", "job" => "testGuide1", "name" => "panel", "type" => "step", "fw_type" => "form" );

	#$guide->SetCanContinue(1);
	#$guide->SetPauseMess("Pausa z metody 1");

}

$n{"ActionCheckIfExistRLayer"} = "Kontrola vrstvy R";
$d{"ActionCheckIfExistRLayer"} = "Akce zkontroluje pritomnost vrstvy R.";

sub ActionCheckIfExistRLayer {

	my $guide    = shift;
	my $inCam    = $guide->GetCAM();
	my $messMngr = $guide->GetMessMngr();
	my %pcbInfo  = $guide->GetPcbInfo();

	CamHelper->OpenJobAndStep( $inCam, $pcbInfo{"pcbId"}, "o+1" );
	my $exists = CamHelper->LayerExists( $inCam, $pcbInfo{"pcbId"}, "o+1", "r" );

	if ($exists) {

		$guide->SetCanContinue(1);
		 

	}
	else {
		my @mess1 = ( Enums->TXT_PRIPRAVAR, "Vytvor ji." );
		$messMngr->Show( -1, EnumsGeneral->MessageType_ERROR, \@mess1 );

		$guide->SetCanContinue(0);
		$guide->SetPauseMess("Vytvor vrstvu r.");
	}

}

$n{"ActionLoadInputFiles"} = "Nacist vstuni data";
$d{"ActionLoadInputFiles"} = "Akce nacte vstupni data ze zdrojove slozky";

sub ActionLoadInputFiles {

	my $guide    = shift;
	my $inCam    = $guide->GetCAM();
	my $messMngr = $guide->GetMessMngr();
	my %pcbInfo  = $guide->GetPcbInfo();

	#$guide->SetCanContinue(1);
	#$guide->SetPauseMess("Pausa z metody 1");

}

$n{"ActionPcbPanelization"} = "Napanelizovani dps";
$d{"ActionPcbPanelization"} = "Akce napanelizuje dps..";

sub ActionPcbPanelization {

	my $guide    = shift;
	my $inCam    = $guide->GetCAM();
	my $messMngr = $guide->GetMessMngr();
	my %pcbInfo  = $guide->GetPcbInfo();

	#$guide->SetCanContinue(1);
	#$guide->SetPauseMess("Pausa z metody 1");

}

$n{"ActionAddBorder"} = "Vlozi okoli do panelu";
$d{"ActionAddBorder"} = "Akce vlozi prislusne okoli do panelu";

sub ActionAddBorder {

	my $guide    = shift;
	my $inCam    = $guide->GetCAM();
	my $messMngr = $guide->GetMessMngr();
	my %pcbInfo  = $guide->GetPcbInfo();

	#$guide->SetCanContinue(1);
	#$guide->SetPauseMess("Pausa z metody 1");

}

$n{"ActionRunChecklist"} = "Spusteni checklistu";
$d{"ActionRunChecklist"} = "Akce spusti prislusny Checklist pro dps.";

sub ActionRunChecklist {

	my $guide    = shift;
	my $inCam    = $guide->GetCAM();
	my $messMngr = $guide->GetMessMngr();
	my %pcbInfo  = $guide->GetPcbInfo();

	#$guide->SetCanContinue(1);
	$guide->SetPauseMess("Zkontroluj Cchecklist.");

}

1;
