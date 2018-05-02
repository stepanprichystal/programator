#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;

#use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

#necessary for load pall packages

use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use aliased 'HelperScripts::DirStructure';

DirStructure->Create();
