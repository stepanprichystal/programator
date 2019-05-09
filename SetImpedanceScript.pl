#!/usr/bin/perl

#-------------------------------------------------------------------------------------------#
# Description: Set impdance constraint to job layer
# Author:SPR
#-------------------------------------------------------------------------------------------#

use strict;
use warnings;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );
 
#local library
use aliased 'Packages::GuideSubs::Impedance::DoSetImpLines';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Managers::MessageMngr::MessageMngr';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

my $inCAM = InCAM->new();

my $jobId = "$ENV{JOB}";
 

my $res = DoSetImpLines->SetImpedanceLines( $inCAM, $jobId );

