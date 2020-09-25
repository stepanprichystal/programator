#!/usr/bin/perl -w

use strict;
use warnings;
use Win32::Process;

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

 

use aliased 'Programs::Stencil::StencilInput::Forms::StencilInputFrm';
use aliased 'Packages::InCAM::InCAM';

my $inCAM = InCAM->new();
my $test = StencilInputFrm->new( -1, $inCAM );

# $test->Test();
$test->MainLoop();
