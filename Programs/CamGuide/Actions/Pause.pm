package Programs::CamGuide::Actions::Pause;

use utf8;
use strict;
use warnings;
use aliased 'Enums::EnumsGeneral';
 
our %n;
our %d;




$n{"ActionCheckLoadedLayer"} = "Kontrola vrstev přípravářem";
$d{"ActionCheckLoadedLayer"} = "Akce pozastaví prúvodce aby měl přípravář šanci zkonotrolvat nactene vrstvy";
sub ActionCheckLoadedLayer{

	my $guide    = shift;
	my $inCam    = $guide->GetCAM();
	my $messMngr = $guide->GetMessMngr();
	my %pcbInfo  = $guide->GetPcbInfo();

	
	$guide->SetPauseMess("Zkontroluj nactene vrstvy.");

}

$n{"ActionCheckWholePcb"} = "Kontrola cele dps pripravarem";
$d{"ActionCheckWholePcb"} = "Akce pozastavi pruvodce, aby mel pripravar sanci zkonotrolvat nactene vrstvy";
sub ActionCheckWholePcb{

	my $guide    = shift;
	my $inCam    = $guide->GetCAM();
	my $messMngr = $guide->GetMessMngr();
	my %pcbInfo  = $guide->GetPcbInfo();

	
	$guide->SetPauseMess("Zkontroluj na konec celou dps.");

}

1;
