#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;


use PureWindow;

#	my $parent    = shift;
#	my $title     = shift;
#	my $dimension = shift;
#	my $flags = shift;
#	my $position = shift;
my $parentWindow = -1;

my $pw = PureWindow1->new($parentWindow);

 
$pw->{"mainFrm"}->Show(1);
 
$pw->MainLoop();

