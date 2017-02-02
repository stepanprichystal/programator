#!/usr/bin/perl-w
#################################
#Sript name: et.pl
#Verze     : 1.00
#Use       : Vytvoreni Stepu ET
#Made      : RV
#################################

use LoadLibrary;
use Time::localtime;

#local library
use Enums;
use FileHelper;
use GeneralHelper;
use DrillHelper;
use StackupHelper;
use aliased 'Packages::Stackup::StackupOperation';

my $jobName = 'f61721';
#my $layerName = 'v2';

#my $jobName = 'f61961';
my $layerName = 'v2';


print StackupOperation->GetThickByLayer($jobName, $layerName);