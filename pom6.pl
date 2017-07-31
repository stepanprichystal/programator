#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

#necessary for load pall packages
#use FindBin;
#use lib "$FindBin::Bin/../";
#use PackagesLib;
use aliased "CamHelpers::CamAttributes";
use aliased "Helpers::FileHelper";
use aliased "Enums::EnumsPaths";
use Data::Dump qw(dump);

use aliased 'Packages::InCAM::InCAM';

my $inCAM = InCAM->new();

 my $userName = CamAttributes->GetJobAttrByName( $inCAM, "d98970", "user_name" );  
 
 print $userName;