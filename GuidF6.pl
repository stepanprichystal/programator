#!/usr/bin/perl -w

use strict;
use warnings;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );
 
use aliased 'Programs::CamGuide::Guide';
use aliased 'Programs::CamGuide::GuideTypeOne';
use Packages::Handlers::LogHandler;
use Packages::Handlers::ErrorHandler;
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Packages::InCAM::InCAM';



#pcb id
my $pcbId = "d152456";

#init CAM
my $inCAM = InCAM->new();


#init message manager
my $messMngr = MessageMngr->new($pcbId);

#init Guid type one
my $guid = GuideTypeOne->new($pcbId, $inCAM,$messMngr);

#Set handlers for writing to logs
$messMngr->SetOnMessage(\&Packages::LogWriter::LogWriter::WriteMessage);
$guid->SetOnAction(\&Packages::Handlers::LogHandler::WriteAction);
$guid->SetOnActionErr(\&Packages::Handlers::ErrorHandler::ShowMessage);

#$guid->SetOnActionErr(\&Test);

print "GUIDE start..\n\n";




my $step = $guid->{"helper"}->GetActionIdByStepId(2);

$guid->RunFromAction($step);

print "GUIDE end..\n\n";




