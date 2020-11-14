#!/usr/bin/perl-w
#-------------------------------------------------------------------------------------------#
# Description: Allow activate Revision besade on TPV request to Job
# Revision info is stored in DIF file
# Author:SPR
#-------------------------------------------------------------------------------------------#

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;
use utf8;

use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::TifFile::TifRevision';
use aliased 'Widgets::Forms::SimpleInput::SimpleInputFrm';
use aliased 'Packages::InCAM::InCAM';
use aliased 'CamHelpers::CamJob';
use aliased 'Helpers::JobHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Managers::MessageMngr::MessageMngr';

my $inCAM = InCAM->new();

my $ACTIONTYPE_OPENCHECKOUT = "Open job + check out                        ";
my $ACTIONTYPE_OPENCHECKIN  = "Open job + check in";
my $ACTIONTYPE_NOACTION     = "No action";

my $jobId = $ENV{"JOB"};

#$jobId = "d298300";

my $dif = TifRevision->new($jobId);

my $rActive = 0;
my $rText   = "";

if ( $dif->TifFileExist() ) {

	if ( $dif->GetRevisionIsActive() ) {

		$rActive = 1;

		$rText = $dif->GetRevisionText();

	}

}

my $messMngr = MessageMngr->new($jobId);

my @mess = ();
push( @mess, "<b>=========================================</b>" );
push( @mess, "<b>Nastavení revize pro opakovanou výrobu </b>" );
push( @mess, "<b>=========================================</b>" );
push( @mess, "" );
push( @mess, "• Text revize je uložen v DIF souboru v archivu jobu" );
push( @mess, "• Pokud bude revize aktivní, upozorní na ni script zpracování opakované výroby nebo Export Checker" );
push( @mess, "• Script umožňuje nastavit novou revizi (<b>aktivovat</b>) nebo smazat stávající (<b>deaktivovat</b>)" );
push( @mess, "" );

my $rActiveTxt = $rActive ? "<g>Ano</g>" : "<r>Ne</r>";

push( @mess, "---------------------" );
push( @mess, "Revize aktivní: <b>$rActiveTxt</b>" );
push( @mess, "Text revize:\n$rText" );

my $revTextPar = $messMngr->GetTextParameter( "Text nové revize", "" );

my @params = ($revTextPar);

$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION,
					  \@mess, [ "Aktivovat novou revizi", "Deaktivovat revizi", "Cancel" ],
					  undef, \@params );

my $res = $messMngr->Result();

if ( $res == 0 ) {

	my $newText = $revTextPar->GetResultValue(1);

	if ( !defined $newText || $newText eq "" ) {

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, ["Text nové revize je prázdný!"] );
	}
	else {

		$dif->SetRevisionIsActive(1);
		$dif->SetRevisionText($newText);

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, ["Nová revize je <b><g>aktivní</g></b>"] );
	}

}
elsif ( $res == 1 ) {

	$dif->SetRevisionIsActive(0);
	$dif->SetRevisionText("");
	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, ["Revize byla <b><r>deaktivována</r></b> (smazána)"] );

}
