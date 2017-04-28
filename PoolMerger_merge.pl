#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

#necessary for load pall packages
#use FindBin;
#use lib "$FindBin::Bin/../";
#use PackagesLib;

use aliased 'Packages::InCAM::InCAM';
use aliased 'Programs::PoolMerge::Groups::MergeGroup::MergeGroupTmp';

 
my $inCAM    = InCAM->new();


#GET INPUT NIF INFORMATION
 
my $path = "c:\\Export\\ExportFiles\\Pool\\backup\\pan3_2-18-1500-Imersnizlato_12-39-35.xml";
my $export = MergeGroupTmp->new();
$export->Run( $inCAM, $path );
