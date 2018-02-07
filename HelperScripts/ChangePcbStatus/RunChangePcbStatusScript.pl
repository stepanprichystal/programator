#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use aliased 'HelperScripts::ChangePcbStatus::ChangeStatusFrm';
use aliased 'Helpers::GeneralHelper';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';
use aliased 'Managers::AbstractQueue::Helper';

my $result = 0;

#run exporter

my $path = GeneralHelper->Root() . "\\HelperScripts\\ChangePcbStatus\\StatusFileTPV";

my $frm = ChangeStatusFrm->new( -1, $path );

$frm->{"mainFrm"}->Show();

$frm->MainLoop();

