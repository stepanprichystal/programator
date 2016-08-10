#!/usr/bin/perl -w

use strict;
use warnings;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );



use aliased 'Programs::CamGuide::Guides::Guide';
use aliased 'Programs::CamGuide::Guides::GuideTypeOne';
use aliased 'Programs::CamGuide::Guides::GuideTypeTwo';
use Packages::Handlers::LogHandler;
use Programs::CamGuide::ErrorHandler;
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Programs::CamGuide::GuideSelector';
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::GeneralHelper';
use aliased 'Programs::CamGuide::Helper';


my $guideAction = EnumsGeneral->GuideAction_SHOW;

#init CAM
my $inCAM = InCAM->new();


#init message manager
my $messMngr = MessageMngr->new();

#pcb id
my $pcbId      = Helper->GetJobId($inCAM);

#elper for selection acreate proper  guide
my $guideSelector = GuideSelector->new($pcbId);

my $childPcbId = Helper->GetChildId($inCAM);
my $guideId = $guideSelector->GetGuideId();

my $guide = undef;

#get init guide
InitGuide( $guideId );


$guide->Run();

sub InitGuide {

	my $myGuideId = shift;

	$guide = $guideSelector->Get( $myGuideId, $pcbId, $inCAM, $messMngr, $childPcbId );

	#Set handlers for writing to logs
	#$messMngr->AddOnMessage( \&Packages::Handlers::LogHandler::WriteMessage );
	$guide->AddOnAction( \&Packages::Handlers::LogHandler::WriteAction );
	$guide->AddOnActionErr( \&Programs::CamGuide::ErrorHandler::ShowExceptionMess );
	$guide->AddOnActionErr( \&Programs::CamGuide::ErrorHandler::WriteExceptionToLog );
	$guide->AddOnGuideChanged( \&GuideChanged );

}

sub GuideChanged {
	my $myGuideId = shift;

	InitGuide($myGuideId);
	$guide->Show();

}



#require  GeneralHelper->Root()."/Programs/CamGuide/GuideInit.pl";
