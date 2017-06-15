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

my $result = 0;

my $frm = ChangeStatusFrm->new();

$frm->ShowModal();
