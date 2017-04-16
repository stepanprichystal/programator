#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;
use utf8;

 
#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use aliased 'Packages::InCAM::InCAM';


my $inCAM = InCAM->new();

$inCAM->COM( "set_step", "name" => "o" );

sleep(2);

$inCAM->COM( "set_step", "name" => "mpanel" );

sleep(2);



