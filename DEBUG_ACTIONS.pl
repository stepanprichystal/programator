#!/usr/bin/perl -w

use strict;
use warnings;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Programs::CamGuide::Guides::Guide';
use aliased 'Programs::CamGuide::Guides::GuideTypeOne';
use aliased 'Programs::CamGuide::Guides::GuideTypeTwo';
use Packages::Handlers::LogHandler;
use Packages::Handlers::ErrorHandler;
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Programs::CamGuide::GuideSelector';
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::GeneralHelper';
use aliased 'Programs::CamGuide::Helper';

#==========Crate fake guide for quick actions debuging =======================#

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

my $guide =  $guideSelector->Get( $guideId, $pcbId, $inCAM, $messMngr, $childPcbId );


#===============================================================================#
#============ debugin action ===================================================#
#===============================================================================#

#use Programs::CamGuide::Actions::Milling;

use aliased 'Connectors::HeliosConnector::HegMethods';
HegMethods->UpdateConstructionClass("F13610", 8);

#Programs::CamGuide::Actions::Milling::ActionCreateOStep($guide);

  