package Programs::CamGuide::Actions::LayerControls;


use utf8;
use strict;
use warnings;
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamHelper';
use aliased 'Programs::CamGuide::Enums';
use aliased 'Connectors::HeliosConnector::HegMethods';

our %n;
our %d;



$n{"ActionCheckIfExistRLayer"} = "Kontrola vrstvy R";
$d{"ActionCheckIfExistRLayer"} = "Akce zkontroluje pritomnost vrstvy R.";

sub ActionCheckIfExistRLayer {

	my $guide    = shift;
	my $inCam    = $guide->GetCAM();
	my $messMngr = $guide->GetMessMngr();
	my %pcbInfo  = $guide->GetPcbInfo();

	CamHelper->OpenJobAndStep( $inCam, $pcbInfo{"pcbId"}, "o+1" );
	my $exists = CamHelper->LayerExists( $inCam, $pcbInfo{"pcbId"}, "r" );

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