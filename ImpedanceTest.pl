#!/usr/bin/perl

#-------------------------------------------------------------------------------------------#
# Description: Do final routing = 2mm with compensation left and suitable start of chain
# Author:SPR
#-------------------------------------------------------------------------------------------#

#3th party library
use utf8;
use strict;
use warnings;
use Time::HiRes qw (sleep);

#local library

#use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use aliased 'Packages::InCAM::InCAM';
use aliased 'CamHelpers::CamJob';

use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::GuideSubs::Impedance::DoSetImpLines';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Managers::MessageMngr::MessageMngr';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

my $inCAM    = InCAM->new();
my $jobId    = "$ENV{JOB}";

my $messMngr = MessageMngr->new($jobId);



my $res = DoSetImpLines->SetImpedanceLines( $inCAM, $jobId );
