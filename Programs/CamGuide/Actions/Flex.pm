package Programs::CamGuide::Actions::Flex;


use utf8;
use strict;
use warnings;
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamHelper';
use aliased 'Programs::CamGuide::Enums';
use aliased 'Connectors::HeliosConnector::HegMethods';


use aliased 'Packages::GuideSubs::Flex::DoBendArea';
use aliased 'Packages::GuideSubs::Flex::DoCoverlayPins';
use aliased 'Packages::GuideSubs::Flex::DoCoverlayLayers';
use aliased 'Packages::GuideSubs::Flex::DoPrepregLayers';
use aliased 'Packages::GuideSubs::Flex::DoRoutTransitionLayers';
use aliased 'Packages::GuideSubs::Flex::DoCoverlayTemplateLayers';
use aliased 'Packages::GuideSubs::Flex::DoFlexiMaskLayer';
use aliased 'Packages::GuideSubs::Flex::DoPrepareBendAreaOther';


our %n;
our %d;


$n{"ActionDoBendArea"} = "Bend area";
$d{"ActionDoBendArea"} = "Vytvoří vrstvu (bend) s hranicemi pružných částí DPS";

sub ActionDoBendArea {

	#Veskere potrebne komponenty a informace nam vzdy poskytne samotny Guide, ktery je predan jako prvni parametr

	my $guide    = shift;
	my $inCAM    = $guide->GetCAM();		#napojena InCAM knihovna na editor, uz nevytvarime znovu
	my $messMngr = $guide->GetMessMngr();	#spravce chybovych/informacnich oken, take uz nevztvarime ynovu
	my %pcbInfo  = $guide->GetPcbInfo();	#hash obsahujici veskere potrebne info o dps nejen z norrisu
	my $stepO  	 = $guide->GetStepO();		#vrati "aktualni nazev stepu O", podle toho na keterm stepu je Guide spusten
	my $stepO1   = $guide->GetStepO1();		#vrati "aktualni nazev stepu O+1", podle toho na keterm stepu je Guide spusten
	
	#priklad dotazeni jmena dps z %pcbInfo
	my $jobId  = $pcbInfo{"pcbId"};
	
	#tady se bude zapisovat kod akce
	#kod bude co nejstrucnejsi a bude volat prislusne pomocne balicky ze slozkz Packages, popr CamHelper
	
	DoBendArea->CreateBendArea( $inCAM, $jobId, $stepO1 );
	
} 
 
$n{"ActionDoCoverlayPins"} = "Coverlay piny";
$d{"ActionDoCoverlayPins"} = "Vytvoří coverlay piny pro připájení pájkou";

sub ActionDoCoverlayPins {

	#Veskere potrebne komponenty a informace nam vzdy poskytne samotny Guide, ktery je predan jako prvni parametr

	my $guide    = shift;
	my $inCAM    = $guide->GetCAM();		#napojena InCAM knihovna na editor, uz nevytvarime znovu
	my $messMngr = $guide->GetMessMngr();	#spravce chybovych/informacnich oken, take uz nevztvarime ynovu
	my %pcbInfo  = $guide->GetPcbInfo();	#hash obsahujici veskere potrebne info o dps nejen z norrisu
	my $stepO  	 = $guide->GetStepO();		#vrati "aktualni nazev stepu O", podle toho na keterm stepu je Guide spusten
	my $stepO1   = $guide->GetStepO1();		#vrati "aktualni nazev stepu O+1", podle toho na keterm stepu je Guide spusten
	
	#priklad dotazeni jmena dps z %pcbInfo
	my $jobId  = $pcbInfo{"pcbId"};
	
	#tady se bude zapisovat kod akce
	#kod bude co nejstrucnejsi a bude volat prislusne pomocne balicky ze slozkz Packages, popr CamHelper
	
	DoCoverlayPins->CreateCoverlayPins( $inCAM, $jobId, $stepO1 );
	
}
 
$n{"ActionDoCoverlayLayers"} = "Coverlay frézovací vrstvy";
$d{"ActionDoCoverlayLayers"} = "Vytvoří coverlay frézovací vrstvy + coverlay masky pro ET";

sub ActionDoCoverlayLayers {

	#Veskere potrebne komponenty a informace nam vzdy poskytne samotny Guide, ktery je predan jako prvni parametr

	my $guide    = shift;
	my $inCAM    = $guide->GetCAM();		#napojena InCAM knihovna na editor, uz nevytvarime znovu
	my $messMngr = $guide->GetMessMngr();	#spravce chybovych/informacnich oken, take uz nevztvarime ynovu
	my %pcbInfo  = $guide->GetPcbInfo();	#hash obsahujici veskere potrebne info o dps nejen z norrisu
	my $stepO  	 = $guide->GetStepO();		#vrati "aktualni nazev stepu O", podle toho na keterm stepu je Guide spusten
	my $stepO1   = $guide->GetStepO1();		#vrati "aktualni nazev stepu O+1", podle toho na keterm stepu je Guide spusten
	
	#priklad dotazeni jmena dps z %pcbInfo
	my $jobId  = $pcbInfo{"pcbId"};
	
	#tady se bude zapisovat kod akce
	#kod bude co nejstrucnejsi a bude volat prislusne pomocne balicky ze slozkz Packages, popr CamHelper
 
	DoCoverlayLayers->PrepareCoverlayLayers( $inCAM, $jobId, $stepO1 );
}


$n{"ActionDoCoverlayTemplateLayers"} = "Šablonu pro pro pájení coverlay";
$d{"ActionDoCoverlayTemplateLayers"} = "Vytvoří šablonu pro pro pájení coverlay";

sub ActionDoCoverlayTemplateLayers {

	#Veskere potrebne komponenty a informace nam vzdy poskytne samotny Guide, ktery je predan jako prvni parametr

	my $guide    = shift;
	my $inCAM    = $guide->GetCAM();		#napojena InCAM knihovna na editor, uz nevytvarime znovu
	my $messMngr = $guide->GetMessMngr();	#spravce chybovych/informacnich oken, take uz nevztvarime ynovu
	my %pcbInfo  = $guide->GetPcbInfo();	#hash obsahujici veskere potrebne info o dps nejen z norrisu
	my $stepO  	 = $guide->GetStepO();		#vrati "aktualni nazev stepu O", podle toho na keterm stepu je Guide spusten
	my $stepO1   = $guide->GetStepO1();		#vrati "aktualni nazev stepu O+1", podle toho na keterm stepu je Guide spusten
	
	#priklad dotazeni jmena dps z %pcbInfo
	my $jobId  = $pcbInfo{"pcbId"};
	
	#tady se bude zapisovat kod akce
	#kod bude co nejstrucnejsi a bude volat prislusne pomocne balicky ze slozkz Packages, popr CamHelper
 
	DoCoverlayTemplateLayers->PrepareTemplateLayers( $inCAM, $jobId, $stepO1 );
}


$n{"ActionDoPrepregLayers"} = "NoFlow prepreg";
$d{"ActionDoPrepregLayers"} = "Vrstvy fprepreg1 a fprepreg2. Pokud uvnitř DPS není coverlay, vrstvy jsou totožné";

sub ActionDoPrepregLayers {

	#Veskere potrebne komponenty a informace nam vzdy poskytne samotny Guide, ktery je predan jako prvni parametr

	my $guide    = shift;
	my $inCAM    = $guide->GetCAM();		#napojena InCAM knihovna na editor, uz nevytvarime znovu
	my $messMngr = $guide->GetMessMngr();	#spravce chybovych/informacnich oken, take uz nevztvarime ynovu
	my %pcbInfo  = $guide->GetPcbInfo();	#hash obsahujici veskere potrebne info o dps nejen z norrisu
	my $stepO  	 = $guide->GetStepO();		#vrati "aktualni nazev stepu O", podle toho na keterm stepu je Guide spusten
	my $stepO1   = $guide->GetStepO1();		#vrati "aktualni nazev stepu O+1", podle toho na keterm stepu je Guide spusten
	
	#priklad dotazeni jmena dps z %pcbInfo
	my $jobId  = $pcbInfo{"pcbId"};
	
	#tady se bude zapisovat kod akce
	#kod bude co nejstrucnejsi a bude volat prislusne pomocne balicky ze slozkz Packages, popr CamHelper
 
	DoPrepregLayers->PreparePrepregLayers( $inCAM, $jobId, $stepO1 );
}


$n{"ActionDoRoutTransitionLayers"} = "Hloubková fréza tranzitního přechodu";
$d{"ActionDoRoutTransitionLayers"} = "Frézy jfzc/jfzs + fzc/fzs";

sub ActionDoRoutTransitionLayers {

	#Veskere potrebne komponenty a informace nam vzdy poskytne samotny Guide, ktery je predan jako prvni parametr

	my $guide    = shift;
	my $inCAM    = $guide->GetCAM();		#napojena InCAM knihovna na editor, uz nevytvarime znovu
	my $messMngr = $guide->GetMessMngr();	#spravce chybovych/informacnich oken, take uz nevztvarime ynovu
	my %pcbInfo  = $guide->GetPcbInfo();	#hash obsahujici veskere potrebne info o dps nejen z norrisu
	my $stepO  	 = $guide->GetStepO();		#vrati "aktualni nazev stepu O", podle toho na keterm stepu je Guide spusten
	my $stepO1   = $guide->GetStepO1();		#vrati "aktualni nazev stepu O+1", podle toho na keterm stepu je Guide spusten
	
	#priklad dotazeni jmena dps z %pcbInfo
	my $jobId  = $pcbInfo{"pcbId"};
	
	#tady se bude zapisovat kod akce
	#kod bude co nejstrucnejsi a bude volat prislusne pomocne balicky ze slozkz Packages, popr CamHelper
 
	DoRoutTransitionLayers->PrepareRoutLayers( $inCAM, $jobId, $stepO1 );
}


$n{"ActionDoFlexiMaskLayer"} = "Flexi maska";
$d{"ActionDoFlexiMaskLayer"} = "Pokud je zadaná v HEG";

sub ActionDoFlexiMaskLayer {

	#Veskere potrebne komponenty a informace nam vzdy poskytne samotny Guide, ktery je predan jako prvni parametr

	my $guide    = shift;
	my $inCAM    = $guide->GetCAM();		#napojena InCAM knihovna na editor, uz nevytvarime znovu
	my $messMngr = $guide->GetMessMngr();	#spravce chybovych/informacnich oken, take uz nevztvarime ynovu
	my %pcbInfo  = $guide->GetPcbInfo();	#hash obsahujici veskere potrebne info o dps nejen z norrisu
	my $stepO  	 = $guide->GetStepO();		#vrati "aktualni nazev stepu O", podle toho na keterm stepu je Guide spusten
	my $stepO1   = $guide->GetStepO1();		#vrati "aktualni nazev stepu O+1", podle toho na keterm stepu je Guide spusten
	
	#priklad dotazeni jmena dps z %pcbInfo
	my $jobId  = $pcbInfo{"pcbId"};
	
	#tady se bude zapisovat kod akce
	#kod bude co nejstrucnejsi a bude volat prislusne pomocne balicky ze slozkz Packages, popr CamHelper
 
	DoFlexiMaskLayer->PrepareFlexiMaskLayers( $inCAM, $jobId, $stepO1 );
}

$n{"ActionDoPrepareBendAreaOther"} = "Odmaskování pružné části + vložení cu pod pružnou část";
$d{"ActionDoPrepareBendAreaOther"} = "";

sub ActionDoPrepareBendAreaOther {

	#Veskere potrebne komponenty a informace nam vzdy poskytne samotny Guide, ktery je predan jako prvni parametr

	my $guide    = shift;
	my $inCAM    = $guide->GetCAM();		#napojena InCAM knihovna na editor, uz nevytvarime znovu
	my $messMngr = $guide->GetMessMngr();	#spravce chybovych/informacnich oken, take uz nevztvarime ynovu
	my %pcbInfo  = $guide->GetPcbInfo();	#hash obsahujici veskere potrebne info o dps nejen z norrisu
	my $stepO  	 = $guide->GetStepO();		#vrati "aktualni nazev stepu O", podle toho na keterm stepu je Guide spusten
	my $stepO1   = $guide->GetStepO1();		#vrati "aktualni nazev stepu O+1", podle toho na keterm stepu je Guide spusten
	
	#priklad dotazeni jmena dps z %pcbInfo
	my $jobId  = $pcbInfo{"pcbId"};
	
	#tady se bude zapisovat kod akce
	#kod bude co nejstrucnejsi a bude volat prislusne pomocne balicky ze slozkz Packages, popr CamHelper
 
	DoPrepareBendAreaOther->PrepareBendAreaOthers( $inCAM, $jobId, $stepO1 );
}
1;
